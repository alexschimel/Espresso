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

%% Batch stacked WC export
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

% save all parameters as text
onOffArray = {'OFF','ON'};
onOffVal = @(x) onOffArray{x+1};
clear paramText
paramText{1} = 'Processing parameters:';
paramText{end+1} = sprintf('* Filter bottom detection: %s',onOffVal(procpar.bottomfilter_flag));
paramText{end+1} = sprintf('* Mask selected data: %s',onOffVal(procpar.masking_flag));
paramText{end+1} = sprintf('  * Outer beams (deg): %.2f',procpar.masking_params.maxAngle);
paramText{end+1} = sprintf('  * Close range (m): %.2f',procpar.masking_params.minRange);
paramText{end+1} = sprintf('  * Above bottom (m): %.2f',-procpar.masking_params.maxRangeBelowBottomEcho);
paramText{end+1} = sprintf('  * Bad pings (%%): %.2f',procpar.masking_params.maxPercentFaultyDetects);
paramText{end+1} = sprintf('  * Mask beyond min. slant range: %s',onOffVal(wc_proc_tab_comp.mask_minslantrange.Value));
paramText{end+1} = sprintf('* Radiometric correction: %s',onOffVal(procpar.radiomcorr_flag));
paramText{end+1} = sprintf('  * Output: %s',procpar.radiomcorr_params.outVal);
paramText{end+1} = sprintf('* Filter sidelobe artefacts: %s',onOffVal(procpar.sidelobefilter_flag));
paramText{end+1} = '';
paramText{end+1} = 'WC stacking parameters:';
paramText{end+1} = sprintf('* Col. scale (dB): [%.2f,%.2f]',cax(1),cax(2));
paramText{end+1} = sprintf('* Data: %s',stackpar.dataField);
paramText{end+1} = sprintf('* Stack: %s',stackpar.stackMode);
paramText{end+1} = sprintf('* Angular lim. (deg): [%.2f,%.2f]',stackpar.angleDegLims(1),stackpar.angleDegLims(2));
paramText{end+1} = sprintf('* Pings: %i',StackPingWidth);
paramText{end+1} = '';
paramText{end+1} = sprintf('Raw data:');
paramText{end+1} = sprintf('* Folder: %s',regexprep(search_path,'\','/'));
paramText{end+1} = sprintf('* Number of files: %i',nFiles);

% create the intro text and add parameters
clear dialogText
dialogText{1} = 'For each compatible raw data file in the folder specified in the "Data files" tab, the "Batch Stack Export" tool will 1) convert the raw data if necessary, 2) process it according to the parameters set in the "Data processing" tab, 3) stack the WCD according to the parameters set in the "Water Column" panel of the "Display" tab, and 4) screenshot a temporary "Stacked WC" view for each block of pings along the entire file. Please review all relevant parameters (listed below) and/or the current aspect of the "Stacked WC" display, before proceeding.';
dialogText{end+1} = '';
dialogText = [dialogText, paramText];

% initialize batch stack dialog
dialogWidthPix = 800;
dialogHeightPix = 550;
marginPix = 10;
buttonHeightPix = 30;
buttonWidthPix = 120;
mainFigPos = getpixelposition(main_figure);
batchStackFigPos = [mainFigPos(1)+0.5*(mainFigPos(3)-dialogWidthPix), ...
    mainFigPos(2)+0.5*(mainFigPos(4)-dialogHeightPix), ...
    dialogWidthPix, dialogHeightPix]; % centered with main figure
batchStackFig = figure('Name','Batch stacked WC export',...
    'NumberTitle','off', ...
    'Position',batchStackFigPos,...
    'WindowStyle','modal',... % set windows style to "normal" when debugging
    'Resize','off',...
    'Visible','off');
set_icon_espresso(batchStackFig);
if ~isdeployed
    set(batchStackFig,'Visible','on');
end

% Proceed and Cancel buttons
proceedButton = uicontrol(batchStackFig,'Style','pushbutton','String','Proceed',...
    'units','pixels',...
    'pos',[0.5*(dialogWidthPix-marginPix)-buttonWidthPix marginPix buttonWidthPix buttonHeightPix],...
    'callback',{@callback_press_proceed_button});
uicontrol(batchStackFig,'Style','pushbutton','String','Cancel',...
    'units','pixels',...
    'pos',[0.5*(dialogWidthPix+marginPix) marginPix buttonWidthPix buttonHeightPix],...
    'callback',{@callback_press_cancel_button});

% Keep converted files checkbox
keepConvCheckbox = uicontrol(batchStackFig,'Style','checkbox','String','Keep converted files',...
    'units','pixels',...
    'pos',[marginPix buttonHeightPix+2*marginPix dialogWidthPix buttonHeightPix]);

% Text
stackUIC = uicontrol(batchStackFig,'Style','text', ...
    'Units','pixels',...
    'Position', [marginPix 2*buttonHeightPix+3*marginPix dialogWidthPix-2*marginPix dialogHeightPix-(2*buttonHeightPix+4*marginPix)], ...
    'String', dialogText, ...
    'HorizontalAlignment', 'left', ...
    'FontSize', 10);

% Make dialog visible
set(batchStackFig,'Visible','on');

    function callback_press_cancel_button(~,~)
        close(batchStackFig);
        return
    end

    function callback_press_proceed_button(~,~)
        
        flagKeepConvertedFiles = keepConvCheckbox.Value;
        
        % select directory for export
        getDirDefPath = espresso_export_folder();
        exportFolder = uigetdir(getDirDefPath,'Select folder where to export stacked WC images');
        close(batchStackFig);
        if exportFolder == 0
            return;
        end
        
        % start of export text
        clear outputTxt
        exportText{1} = sprintf('Espresso v%s. Stacked WC export.',espresso_version());
        exportText{end+1} = sprintf('date: %s',datestr(now,'yyyy/mm/dd HH:MM:SS'));
        exportText{end+1} = '';
        
        % add parameters
        exportText = [exportText, paramText];
        
        % add list of files
        exportText{end+1} = '* List of files:';
        for ii = 1:nFiles
            rawFile = CFF_file_name(CFF_onerawfileonly(rawfileslist(ii)));
            if iscell(rawFile), rawFile = rawFile{1}; end
            exportText{end+1} = sprintf('  #%i/%i: %s.',ii,nFiles,rawFile);
        end
        
        % create export text file
        exportFilename = sprintf('%s_batch_stack_export.txt',datestr(now,'yyyymmddTHHMMSS'));
        exportFile = fullfile(exportFolder,exportFilename);
        fid = fopen(exportFile,'wt');
        for ii = 1:numel(exportText)
            fprintf(fid,exportText{ii}); % print to text file
            fprintf(fid,'\n');
        end
        fclose(fid);
        
        % initialize the temporary stacked WC figure
        size_max = get(0, 'MonitorPositions');
        pos_fig = [size_max(1,1)+size_max(1,3)*0.2 size_max(1,2)+size_max(1,4)*0.2 size_max(1,3)*0.6 size_max(1,4)*0.6];
        dest_fig = figure(...
            'Units','pixels',...
            'Position',pos_fig,...
            'Name',sprintf('Batch stacked WC output. Processing file 1/%i. Please wait...',nFiles),...
            'Resize','on',...
            'Color','White',...
            'MenuBar','none',...
            'Toolbar','none',...
            'CloseRequestFcn',@callback_close_stackedWC_fig);
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

        global cancelFlag
        cancelFlag = 0;
        
        % loop over all files
        for ii = 1:nFiles
            
            % change name of figure
            set(dest_fig,'Name',sprintf('Batch stacked WC output. Processing file %i/%i. Please wait...',ii,nFiles));
            drawnow;
            
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
                outFilename = sprintf('%s_WCD_%i-%i.png',fnamet,blocks(iB,1),blocks(iB,2));
                outFile = fullfile(exportFolder,outFilename);
                print(dest_fig,'-r300',outFile,'-dpng');
                
            end
            
            % clear fData
            clear fData
            
            % delete converted file?
            if ~flagKeepConvertedFiles && ~flagFileAlreadyConverted
                wc_dir = CFF_converted_data_folder(rawFile);
                rmdir(wc_dir,'s');
            end
            
            if cancelFlag
                delete(dest_fig);
                return;
            end
            
        end
        
        % delete converted file?
        if flagKeepConvertedFiles
            update_datafiles_tab(main_figure);
        end
        
        % close stack figure
        delete(dest_fig);
        
        function callback_close_stackedWC_fig(~,~)
            cancelFlag = 0;
            answer = questdlg('Are you sure you want to cancel the Batch Stacked WC Export process?', ...
                'Batch Stacked WC Export', ...
                'Yes','No','No');
            % Handle response
            switch answer
                case 'Yes'
                    set(dest_fig,'Name','Batch stacked WC export. Cancelling process after this file. Please wait...');
                    drawnow;
                    cancelFlag = 1;
                case 'No'
                    cancelFlag = 0;
            end
        end
        
    end

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
    'Position',mainFigPos,'WindowStyle','modal','Visible','off'); % set windows style to "normal" when debugging
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