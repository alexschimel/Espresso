function update_wc_tab(main_figure)
%UPDATE_WC_TAB  Updates wc tab in Espresso Swath panel
%
%   See also CREATE_WC_TAB, INITIALIZE_DISPLAY, ESPRESSO.

%   Copyright 2017-2021 Alexandre Schimel, Yoann Ladroit, NIWA
%   Licensed under MIT. Details on https://github.com/alexschimel/Espresso/


%% prep

% check if there are data to display
fData_tot = getappdata(main_figure,'fData');
if isempty(fData_tot)
    no_data_clear_all_displays(main_figure);
    return;
end

% get disp_config
disp_config = getappdata(main_figure,'disp_config');
disp_config.cleanup(main_figure);

% get fdata to be displayed
fData_tot_IDs = cellfun(@(c) c.ID,fData_tot);
fData = fData_tot{fData_tot_IDs==disp_config.Fdata_ID};
datagramSource = CFF_get_datagramSource(fData);

% exit if not showing water column data
if ~ismember(disp_config.MET_datagramSource, {'WC','AP'})
    return
end

fprintf('Updating WC view... ');

% get ping and across-dist to be displayed
iPing          = disp_config.Iping;
across_dist = disp_config.AcrossDist;

% get data type to be grabbed
display_tab_comp = getappdata(main_figure,'display_tab');
wc_str = display_tab_comp.data_disp.String;
str_disp = wc_str{display_tab_comp.data_disp.Value};

% if "Processed" was selected but there is no Processed data, or if "Phase"
% was selected and there is no Phase data, switch back to original
if strcmp(str_disp,'Processed') && ~isfield(fData,'X_SBP_WaterColumnProcessed') || ...
        strcmp(str_disp,'Phase') && ~isfield(fData,'AP_SBP_SamplePhase')
    set(display_tab_comp.data_disp,'Value',find(contains(wc_str,'Original')));
    str_disp = 'Original';
end

% get data extents for colormap
cax_min = str2double(display_tab_comp.clim_min_wc.String);
cax_max = str2double(display_tab_comp.clim_max_wc.String);
cax = [cax_min cax_max];


%% extract data
switch str_disp
    case 'Original'
        WC_data = CFF_get_WC_data(fData,sprintf('%s_SBP_SampleAmplitudes',datagramSource),'iPing',iPing);
        idx_keep = WC_data >= cax(1);
    case 'Processed'
        WC_data = CFF_get_WC_data(fData,'X_SBP_WaterColumnProcessed','iPing',iPing);
        idx_keep = WC_data >= cax(1);
    case 'Phase'
        WC_data = CFF_get_WC_data(fData,sprintf('%s_SBP_SamplePhase',datagramSource),'iPing',iPing);
        idx_keep = true(size(WC_data));
end
if isempty(WC_data)
    return;
end


%% get WCD coordinates in the swath frame
[sampleAcrossDist,sampleUpDist] = CFF_get_WCD_swathe_coordinates(fData,iPing,size(WC_data,1));


%% display
wc_tab_comp = getappdata(main_figure,'wc_tab');

% display WC data itself
set(wc_tab_comp.wc_gh,...
    'XData',sampleAcrossDist,...
    'YData',sampleUpDist,...
    'ZData',zeros(size(WC_data)),...
    'CData',WC_data,...
    'AlphaData',idx_keep);

% display Bottom
set(wc_tab_comp.bot_gh,...
    'XData',fData.X_BP_bottomAcrossDist(:,iPing),...
    'YData',fData.X_BP_bottomUpDist(:,iPing));

% set display Xlim and Ylim
if all(idx_keep(:)==0)
    % if no data is good, display all of it
    idx_keep = true(size(idx_keep));
end
xlim = [-max(abs(sampleAcrossDist(idx_keep))) max(abs(sampleAcrossDist(idx_keep)))];
ylim = [min(nanmin(fData.X_BP_bottomUpDist(:,iPing)),nanmin(sampleUpDist(idx_keep))) 0];
set(wc_tab_comp.wc_axes,...
    'XLim',xlim,...
    'Ylim',ylim,...
    'Layer','top');

% display pointer's location across
set(wc_tab_comp.ac_gh,...
    'XData',[across_dist across_dist],...
    'YData',get(wc_tab_comp.wc_axes,'YLim'));

% figure title
fname = fData.ALLfilename{1};
[~,fnamet,~] = fileparts(fname);
tt = sprintf('File: %s. Ping: %.0f/%.0f. Time: %s.',fnamet,iPing,numel(fData.(sprintf('%s_1P_PingCounter',datagramSource))),datestr(fData.X_1P_pingSDN(iPing),'HH:MM:SS'));
wc_tab_comp.wc_axes_tt.String = tt;

drawnow;
fprintf('Done.\n');

end