function update_wc_tab(main_figure,varargin)
%UPDATE_WC_TAB  Updates wc tab in Espresso Swath panel
%
%   See also CREATE_WC_TAB, INITIALIZE_DISPLAY, ESPRESSO.

%   Authors: Alex Schimel (NIWA, alexandre.schimel@niwa.co.nz) and Yoann
%   Ladroit (NIWA, yoann.ladroit@niwa.co.nz)
%   2017-2021; Last revision: 21-07-2021

% input parser
p = inputParser;
addOptional(p,'change_line_flag',1);
addOptional(p,'change_ping_flag',1);
parse(p,varargin{:});
change_line_flag = p.Results.change_line_flag;
change_ping_flag = p.Results.change_ping_flag;


%% prep

% disp
if ~isdeployed()
    disp('Update WC Tab');
end

% check if there are data to display
fData_tot = getappdata(main_figure,'fData');
if isempty(fData_tot)
    no_data_clear_all_displays(main_figure);
    return;
end

% clean-up disp_config
disp_config = getappdata(main_figure,'disp_config');
disp_config.cleanup(main_figure);

% get fdata to be displayed
fData_tot_IDs = cellfun(@(c) c.ID,fData_tot);
fData = fData_tot{fData_tot_IDs==disp_config.Fdata_ID};
datagramSource = CFF_get_datagramSource(fData);

% get ping and across-dist to be displayed
ip          = disp_config.Iping;
across_dist = disp_config.AcrossDist;

% get data type to be grabbed
wc_tab_comp  = getappdata(main_figure,'wc_tab');
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

% get colour extents to limit data
cax_min = str2double(display_tab_comp.clim_min_wc.String);
cax_max = str2double(display_tab_comp.clim_max_wc.String);
cax = [cax_min cax_max];


%% extract data
switch str_disp
    case 'Original'
        WC_data = CFF_get_WC_data(fData,sprintf('%s_SBP_SampleAmplitudes',datagramSource),'iPing',ip);
        idx_keep = WC_data >= cax(1);
    case 'Processed'
        WC_data = CFF_get_WC_data(fData,'X_SBP_WaterColumnProcessed','iPing',ip);
        idx_keep = WC_data >= cax(1);
    case 'Phase'
        WC_data = CFF_get_WC_data(fData,sprintf('%s_SBP_SamplePhase',datagramSource),'iPing',ip);
        if isempty(WC_data)
            display_tab_comp.data_disp.Value = find(strcmpi(display_tab_comp.data_disp.String,'Original'));
        end
        idx_keep = true(size(WC_data));
end

if isempty(WC_data)
    return;
end


%% calculations

% get distances across and upwards for all samples
dr_samples = CFF_inter_sample_distance(fData);
sampleRange = CFF_get_samples_range((1:size(WC_data,1))',fData.(sprintf('%s_BP_StartRangeSampleNumber',datagramSource))(:,ip),dr_samples(ip));
[sampleAcrossDist,sampleUpDist] = CFF_get_samples_dist(sampleRange,fData.(sprintf('%s_BP_BeamPointingAngle',datagramSource))(:,ip)/180*pi);


%% display

% display WC data itself
set(wc_tab_comp.wc_gh,...
    'XData',sampleAcrossDist,...
    'YData',sampleUpDist,...
    'ZData',zeros(size(WC_data)),...
    'CData',WC_data,...
    'AlphaData',idx_keep);

% display Bottom
set(wc_tab_comp.bot_gh,...
    'XData',fData.X_BP_bottomAcrossDist(:,ip),...
    'YData',fData.X_BP_bottomUpDist(:,ip));

% set display Xlim and Ylim
if all(idx_keep(:)==0)
    % if no data is good, display all of it
    idx_keep = true(size(idx_keep));
end
xlim = [-max(abs(sampleAcrossDist(idx_keep))) max(abs(sampleAcrossDist(idx_keep)))];
ylim = [min(nanmin(fData.X_BP_bottomUpDist(:,ip)),nanmin(sampleUpDist(idx_keep))) 0];
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
tt = sprintf('File: %s. Ping: %.0f/%.0f. Time: %s.',fnamet,ip,numel(fData.(sprintf('%s_1P_PingCounter',datagramSource))),datestr(fData.X_1P_pingSDN(ip),'HH:MM:SS'));
wc_tab_comp.wc_axes_tt.String = tt;


if change_line_flag
    % calling this update on a different line than currently displayed, so
    % ensure that the line now displayed in WC is selected in the list of
    % files loaded
    
    IDs = cellfun(@(c) c.ID,fData_tot);
    
    if ~ismember(disp_config.Fdata_ID , fData_tot_IDs)
        disp_config.Fdata_ID = fData_tot_IDs(1);
        disp_config.Iping = 1;
        return;
    end
    
end

end