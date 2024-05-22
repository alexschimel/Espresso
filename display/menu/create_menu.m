function create_menu(main_figure)
%CREATE_MENU  Create menu on Espresso main window
%
%   Create menu on Espresso main window
%
%   See also ESPRESSO.

%   Copyright 2024 Alexandre Schimel, Yoann Ladroit, NIWA
%   Licensed under MIT. Details on https://github.com/alexschimel/Espresso/

toolsMenu = uimenu(main_figure,'Label','Tools');
mitem = uimenu(toolsMenu,'Text','Batch stacked WC export');
mitem.MenuSelectedFcn = {@batch_stacked_export,main_figure};

uimenu(main_figure,'Label','About','Callback',{@callback_about,main_figure});

end

%% Batch staceked WC export
function batch_stacked_export(~,~,main_figure)

% get list of raw data files from search path in "Data files" tab
file_tab_comp = getappdata(main_figure,'file_tab');
search_path = get(file_tab_comp.path_box,'string');
rawfileslist = CFF_list_raw_files_in_dir(search_path);
nFiles = numel(rawfileslist);

% get WCD processing parameters from "Data Processing" tab
procpar = struct();
wc_proc_tab_comp = getappdata(main_figure,'wc_proc_tab');
% bottom filter
procpar.bottomfilter_flag = wc_proc_tab_comp.bot_filtering.Value;
% masking parameters
procpar.masking_flag = wc_proc_tab_comp.masking.Value;
procpar.masking_params.maxAngle = str2double(get(wc_proc_tab_comp.angle_mask,'String'));
procpar.masking_params.minRange = str2double(get(wc_proc_tab_comp.r_min,'String'));
procpar.masking_params.maxRangeBelowBottomEcho = -str2double(get(wc_proc_tab_comp.r_bot,'String')); % NOTE inverting sign here.
procpar.masking_params.maxPercentFaultyDetects = str2double(get(wc_proc_tab_comp.mask_badpings,'String'));
if wc_proc_tab_comp.mask_minslantrange.Value
    % checked, remove beyond MSR
    procpar.masking_params.maxRangeBelowMSR = 0;
else
    % unchecked, don't remove anything
    procpar.masking_params.maxRangeBelowMSR = inf;
end
% radiometric correction parameters
procpar.radiomcorr_flag = wc_proc_tab_comp.radiomcorr.Value;
procpar.radiomcorr_params.outVal = wc_proc_tab_comp.radiomcorr_output.String{wc_proc_tab_comp.radiomcorr_output.Value};
% sidelobe filtering parameters
procpar.sidelobefilter_flag = wc_proc_tab_comp.sidelobe.Value;
procpar.sidelobefilter_params.avgCalc = 'mean';
procpar.sidelobefilter_params.refType = 'fromPingData';
procpar.sidelobefilter_params.refArea = 'nadirWC';
procpar.sidelobefilter_params.refCalc = 'perc25';

% get stacking parameters from "Display" tab
stackpar = struct();
disp_config = getappdata(main_figure,'disp_config');
stackpar.dataField = 'X_SBP_WaterColumnProcessed';
stackpar.stackMode = disp_config.StackAngularMode;
stackpar.angleDegLims = disp_config.StackAngularWidth;
StackPingWidth = disp_config.StackPingWidth.*2;

% get WCD color bar limits
cax = disp_config.Cax_wc;

% % dialog box
% dlg_title = 'Check the processing parameters';
% dlg_text = sprintf('The selected files will b\n\ne converted, loaded, then processed using the parameters as currently selected files will be converted, loaded, then processed using the parameters as currently selected files will be converted, loaded, then processed using the parameters as currently set in the "Data Processing" tab.\nProceed?');
% dlg_options = {'OK','Cancel'};
% dlg_answer = question_dialog_fig(main_figure,dlg_title,dlg_text,'opt',dlg_options);
% 
% switch dlg_answer
%     case 'Cancel'
%         return
% end

% select directory for export
getDirDefPath = espresso_export_folder();
exportFolder = uigetdir(getDirDefPath,'Select folder where to export stacked WC images');
if exportFolder == 0
    return;
end

% start by exporting info in text file
clear txt
txt{1} = sprintf('Espresso v%s. Stacked WC export.',espresso_version());
txt{end+1} = sprintf('date: %s',datestr(now,'yyyy/mm/dd HH:MM:SS'));
txt{end+1} = '';
txt{end+1} = 'Processing parameters:';
txt{end+1} = sprintf('* Filter bottom detection: %i',procpar.bottomfilter_flag);
txt{end+1} = sprintf('* Mask selected data: %i',procpar.masking_flag);
txt{end+1} = sprintf('  * Outer beams (deg): %.2f',procpar.masking_params.maxAngle);
txt{end+1} = sprintf('  * Close range (m): %.2f',procpar.masking_params.minRange);
txt{end+1} = sprintf('  * Above bottom (m): %.2f',-procpar.masking_params.maxRangeBelowBottomEcho);
txt{end+1} = sprintf('  * Bad pings (%%%%): %.2f',procpar.masking_params.maxPercentFaultyDetects);
txt{end+1} = sprintf('  * Mask beyond min slant range: %i',wc_proc_tab_comp.mask_minslantrange.Value);
txt{end+1} = sprintf('* Radiometric correction: %i',procpar.radiomcorr_flag);
txt{end+1} = sprintf('  * Output: %s',procpar.radiomcorr_params.outVal);
txt{end+1} = sprintf('* Filter siedelobe artefacts: %i',procpar.sidelobefilter_flag);
txt{end+1} = sprintf('  * avgCalc: %s',procpar.sidelobefilter_params.avgCalc);
txt{end+1} = sprintf('  * refType: %s',procpar.sidelobefilter_params.refType);
txt{end+1} = sprintf('  * refArea: %s',procpar.sidelobefilter_params.refArea);
txt{end+1} = sprintf('  * refCalc: %s',procpar.sidelobefilter_params.refCalc);
txt{end+1} = '';
txt{end+1} = 'Stacking parameters:';
txt{end+1} = sprintf('* dataField: %s',stackpar.dataField);
txt{end+1} = sprintf('* stackMode: %s',stackpar.stackMode);
txt{end+1} = sprintf('* angleDegLims: [%.2f,%.2f]',stackpar.angleDegLims(1),stackpar.angleDegLims(2));
txt{end+1} = sprintf('* pings: %i',StackPingWidth);
txt{end+1} = '';
txt{end+1} = 'Display parameters:';
txt{end+1} = sprintf('* cax: [%.2f,%.2f]',cax(1),cax(2));
txt{end+1} = '';
txt{end+1} = sprintf('Processing %i files in folder %s:',nFiles,regexprep(search_path,'\','/'));
for ii = 1:nFiles
    rawFile = CFF_file_name(CFF_onerawfileonly(rawfileslist(ii)));
    if iscell(rawFile), rawFile = rawFile{1}; end
    txt{end+1} = sprintf('#%i/%i: %s.',ii,nFiles,rawFile);
end

exportFile = fullfile(exportFolder,'batch_stack_export.txt');
fid = fopen(exportFile,'wt');
for ii = 1:numel(txt)
    fprintf(fid,txt{ii}); % print to text file
    fprintf(fid,'\n');
end
fclose(fid);

% initialize figure
size_max = get(0, 'MonitorPositions');
pos_fig = [size_max(1,1)+size_max(1,3)*0.2 size_max(1,2)+size_max(1,4)*0.2 size_max(1,3)*0.6 size_max(1,4)*0.6];
dest_fig = figure(...
            'Units','pixels',...
            'Position',pos_fig,...
            'Name','Stacked Water Column',...
            'Resize','on',...
            'Color','White',...
            'MenuBar','none',...
            'Toolbar','none');
set_icon_espresso(dest_fig)
wc_axes = axes(dest_fig,...
    'Units','normalized',...
    'outerposition',[0 0 0.98 1],...
    'nextplot','add',...
    'YDir','normal',...
    'Tag','stacked_wc');
colorbar(wc_axes,'southoutside');
colormap(wc_axes,init_cmap('ek60'));
title(wc_axes,'N/A','Interpreter','none','FontSize',10,'FontWeight','normal');
caxis(wc_axes,cax);
ylabel(wc_axes,'Range/Depth (m)','FontSize',10);
grid(wc_axes,'on');
box(wc_axes,'on')
axis(wc_axes,'ij');
wc_axes.XAxisLocation='top';
wc_axes.YAxis.TickLabelFormat='%.0f';
wc_axes.YAxis.FontSize=8;
wc_axes.XAxis.FontSize=8;
wc_gh = pcolor(wc_axes,[],[],[]);
set(wc_gh,'facealpha','flat','LineStyle','none','AlphaData',[]);
drawnow;

% loop over all files
for ii = 1:nFiles
    
    % file to process
    rawFile = rawfileslist(ii);
    
    % check if file is already converted, to remember
    flagFileAlreadyConverted = CFF_are_raw_files_converted(rawFile);
    
    % convert file (if necessary) and load temporarily
    fData = CFF_convert_raw_files(rawFile,...
        'conversionType','WCD',...
        'saveFDataToDrive',0,...
        'forceReconvert',0,...
        'outputFData',1,...
        'abortOnError',0,...
        'convertEvenIfDtgrmsMissing',0,...
        'dr_sub',1,...
        'db_sub',1);
    
    % initial WCD processing
    fData = CFF_compute_ping_navigation_v2(fData,'comms','multilines');
    fData = CFF_georeference_bottom_detect(fData,'comms','multilines');

    % filter bottom
    if procpar.bottomfilter_flag
        fData = CFF_filter_bottom_detect_v2(fData,'comms','multilines');
    end
    
    % data processing (masking, radiometric core
    if procpar.masking_flag || procpar.radiomcorr_flag || procpar.sidelobefilter_flag
        fData = process_watercolumn({fData}, 1, procpar);
        fData = fData{1};
    end
    
    % get list of blocks of pings to stack
    nPings = numel(fData.WC_1P_Date);
    blocks = CFF_setup_block_processing(nPings,StackPingWidth);
    nBlocks = size(blocks,1);
    if nBlocks>1
        blocks(end,1) = blocks(end,2) - StackPingWidth + 1;
    end
    
    % loop over blocks of pings
    for iB = 1:nBlocks
        
        % complete stacking parameter structure with list of pings to stack
        stackpar.iPingLims = [blocks(iB,1),blocks(iB,2)];

        % stack it baby
        [stack,stackX,stackY] = CFF_stack_WCD(fData,stackpar);
        
        % alphadata
        idx_keep_al = stack >= cax(1);
        
        % update stacked WC data
        set(wc_gh,...
            'XData',stackX,...
            'YData',stackY,...
            'ZData',zeros(size(stack)),...
            'CData',stack,...
            'AlphaData',idx_keep_al);
        
        % Xlim and Ylim. Cropping the nans at top and bottom
        xlim_stacked = ([stackX(1) stackX(end)]);
        if xlim_stacked(1) == xlim_stacked(2)
            % in case only one ping in this view (file with 1 ping)
            xlim_stacked(2) = xlim_stacked(1)+1;
        end
        idx_al_s = find(~isnan(nanmean(stack,2)),1,'first');
        idx_al_e = find(~isnan(nanmean(stack,2)),1,'last');
        if ~isempty(idx_al_s)&&~isempty(idx_al_s)
            ylim_stacked = [stackY(idx_al_s)*0.9 stackY(idx_al_e)*1.1];
            set(wc_axes,...
                'XLim',xlim_stacked,...
                'Ylim',ylim_stacked,...
                'Layer','top');
        end
        
        % title
        fname = fData.ALLfilename{1};
        [~,fnamet,~] = fileparts(fname);
        tt = sprintf('File %s (#%i/%i). Pings %i-%i (#%i/%i)',fnamet,ii,nFiles,blocks(iB,1),blocks(iB,2),iB,nBlocks);
        wc_axes.Title.String = tt;
        
        % Y Label
        switch disp_config.StackAngularMode
            case 'range'
                wc_axes.YLabel.String = 'Range (m)';
            case 'depth'
                wc_axes.YLabel.String = 'Depth (m)';
        end
        
        drawnow;
        
        % print and save to default export folder
        outFilename = sprintf('stack_file_%i-%i_ping-block_%i-%i.png',ii,nFiles,iB,nBlocks);
        outFile = fullfile(exportFolder,outFilename);
        print(dest_fig,'-r300',outFile,'-dpng');
        
    end
    
    % clear fData
    clear fData
    
    % delete converted file if it wasn't converted in the first place
    if ~flagFileAlreadyConverted
        wc_dir = CFF_converted_data_folder(rawFile);
        rmdir(wc_dir,'s');
    end
    
end

% close figure
close(dest_fig);

end



%% Callback when pressing the "About" menu
function callback_about(~,~,main_figure)

% about text
[ver, coffeeVer, aknowledgments] = espresso_version();
aboutText = {};
aboutText{end+1,1} = sprintf('Espresso v%s\n',ver);
aboutText{end+1,1} = sprintf('(powered by CoFFee v%s)\n\n',coffeeVer);
aboutText{end+1,1} = sprintf('If you use this software, please acknowledge:\n');
aboutText{end+1,1} = sprintf('%s.\n\n',aknowledgments);
aboutText{end+1,1} = sprintf('License:\n');

% license text
licenseFile = espresso_license_file();
licenseText = readlines(licenseFile);

% text parameters
fontSizeInPoints = 10;
marginsInPixels = 20;
licenseLeftIndentInPixels = 20;

% initialize dialog to cover main figure
mainFigPos = getpixelposition(main_figure);
aboutFig = figure('Name','About','NumberTitle','off', ...
    'Position',mainFigPos,'WindowStyle','modal','Visible','off');
set_icon_espresso(aboutFig);
if ~isdeployed
    set(aboutFig,'Visible','on');
end

% UI control for license
licenseUIC = uicontrol(aboutFig, 'Style', 'text', ...
    'Position', [0, 0, mainFigPos(3), mainFigPos(4)], ...
    'String', licenseText, ...
    'HorizontalAlignment', 'left', ...
    'FontSize', fontSizeInPoints,...
    'Fontname','FixedWidth');
licenseUIC.Position(1) = marginsInPixels + licenseLeftIndentInPixels;
licenseUIC.Position(2) = marginsInPixels; % align to bottom of figure
licenseUIC.Position(4) = licenseUIC.Extent(4); % height to match inner text

% UI control for about section
aboutUIC = uicontrol(aboutFig, 'Style', 'text', 'Position', [0, 0, mainFigPos(3), mainFigPos(4)], ...
    'String', aboutText, ...
    'HorizontalAlignment', 'left', ...
    'FontSize', fontSizeInPoints);
aboutUIC.Position(1) = marginsInPixels;
aboutUIC.Position(2) = marginsInPixels + licenseUIC.Position(4); % align to top of license
aboutUIC.Position(4) = aboutUIC.Extent(4); % height to match inner text

% adjust window width and height to contents
aboutFig.Position(3) = max([aboutUIC.Extent(3),licenseUIC.Extent(3)+licenseLeftIndentInPixels]) ...
    + 2.*marginsInPixels;
aboutFig.Position(4) = aboutUIC.Extent(4) + licenseUIC.Extent(4) ...
    + 2.*marginsInPixels;

% center window
aboutFig.Position(1:2) = mainFigPos(1:2) + round(mainFigPos(3:4)./2) - round(aboutFig.Position(3:4)./2);

% make visible
set(aboutFig,'Visible','on');

end