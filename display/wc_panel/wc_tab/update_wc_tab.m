%% update_wc_tab.m
%
% Updates the WC swath display
%
%% Help
%
% *USE*
%
% _This section contains a more detailed description of what the function
% does and how to use it, for the interested user to have an overall
% understanding of its function. Example below to replace. Delete these
% lines XXX._
%
% This is a text file containing the basic comment template to add at the
% start of any new ESP3 function to serve as function help. XXX
%
% *INPUT VARIABLES*
%
% _This section contains bullet points of input variables with description
% and information. Put input variable and other valid entries or defaults
% between | symbols so it shows as monospace. Information section to
% contain, in order: requirement (i.e. Required/Optional/Paramter), valid
% type (e.g. Num, Positive num, char, 1xN cell array, etc.) and default
% value if there is one (e.g. Default: '10'). Example below to replace.
% Delete these lines XXX._
%
% * |input_variable_1|: Description (Information). XXX
% * |input_variable_2|: Description (Information). XXX
% * |input_variable_3|: Description (Information). XXX
%
% *OUTPUT VARIABLES*
%
% _This section contains bullet points of output variables with description
% and information. See input variables for template. Example below to
% replace. Delete these lines XXX._
%
% * |output_variable_1|: Description (Information). XXX
% * |output_variable_2|: Description (Information). XXX
%
% *DEVELOPMENT NOTES*
%
% _This section describes what features are temporary, needed future
% developments and paper references. Example below to replace. Delete these
% lines XXX._
%
% * research point 1. XXX
% * research point 2. XXX
%
% *NEW FEATURES*
%
% _This section contains dates and descriptions of major updates. Example
% below to replace. Delete these lines XXX._
%
% * YYYY-MM-DD: second version. Describes the update. XXX
% * YYYY-MM-DD: first version. XXX
%
% *EXAMPLE*
%
% _This section contains examples of valid function calls. Note that
% example lines start with 3 white spaces so that the publish function
% shows them correctly as matlab code. Example below to replace. Delete
% these lines XXX._
%
%   example_use_1; % comment on what this does. XXX
%   example_use_2: % comment on what this line does. XXX
%
% *AUTHOR, AFFILIATION & COPYRIGHT*
%
% _This last section contains at least author name and affiliation. Delete
% these lines XXX._
%
% Yoann Ladroit, Alexandre Schimel, NIWA. XXX

%% Function
function update_wc_tab(main_figure,varargin)

if ~isdeployed()
    disp('Update WC Tab');
end

% input parser
p = inputParser;
addOptional(p,'change_line_flag',1);
addOptional(p,'change_ping_flag',1);
parse(p,varargin{:});
change_line_flag = p.Results.change_line_flag;
change_ping_flag = p.Results.change_ping_flag;

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
display_tab_comp = getappdata(main_figure,'display_tab');
cax_min = str2double(display_tab_comp.clim_min_wc.String);
cax_max = str2double(display_tab_comp.clim_max_wc.String);
cax = [cax_min cax_max];

% now extract data
switch str_disp
    case 'Original'
        amp = CFF_get_WC_data(fData,sprintf('%s_SBP_SampleAmplitudes',datagramSource),'iPing',ip);
        idx_keep = amp >= cax(1);
    case 'Processed'
        amp = CFF_get_WC_data(fData,'X_SBP_WaterColumnProcessed','iPing',ip);
        idx_keep = amp >= cax(1);
    case 'Phase'
        amp = CFF_get_WC_data(fData,sprintf('%s_SBP_SamplePhase',datagramSource),'iPing',ip);
        if isempty(amp)
            display_tab_comp.data_disp.Value = find(strcmpi(display_tab_comp.data_disp.String,'Original'));
        end
        idx_keep = true(size(amp));
end

if isempty(amp)
    amp = CFF_get_WC_data(fData,sprintf('%s_SBP_SampleAmplitudes',datagramSource),'iPing',ip);
    [amp, ~] = CFF_WC_radiometric_corrections_CORE(amp,fData);
    idx_keep = amp >= cax(1);
end

% get distances across and upwards for all samples
dr_samples = CFF_inter_sample_distance(fData);
sampleRange = CFF_get_samples_range((1:size(amp,1))',fData.(sprintf('%s_BP_StartRangeSampleNumber',datagramSource))(:,ip),dr_samples(ip));
[sampleAcrossDist,sampleUpDist] = CFF_get_samples_dist(sampleRange,fData.(sprintf('%s_BP_BeamPointingAngle',datagramSource))(:,ip)/180*pi);

% display WC data itself
set(wc_tab_comp.wc_gh,...
    'XData',sampleAcrossDist,...
    'YData',sampleUpDist,...
    'ZData',zeros(size(amp)),...
    'CData',amp,...
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

% display Pointer location across
set(wc_tab_comp.ac_gh,...
    'XData',[across_dist across_dist],...
    'YData',get(wc_tab_comp.wc_axes,'YLim'));


%% set Fdata_ID
fname = fData.ALLfilename{1};
[~,fnamet,~] = fileparts(fname);
tt = sprintf('File: %s. Ping: %.0f/%.0f. Time: %s.',fnamet,ip,numel(fData.(sprintf('%s_1P_PingCounter',datagramSource))),datestr(fData.X_1P_pingSDN(ip),'HH:MM:SS'));
wc_tab_comp.wc_axes_tt.String = tt;

if change_line_flag
    % ensure that the line now displayed in WC is selected in the list of
    % files loaded
    
    IDs = cellfun(@(c) c.ID,fData_tot);
    
    if ~ismember(disp_config.Fdata_ID , IDs)
        disp_config.Fdata_ID = IDs(1);
        disp_config.Iping = 1;
        return;
    end
    
    %% THIS SECTION REMOVED because it re-updates everything..
    %     line_idx = find(disp_config.Fdata_ID ==IDs);
    %
    %     fdata_tab_comp = getappdata(main_figure,'fdata_tab');
    %     if ~ismember(line_idx,fdata_tab_comp.selected_idx)
    %
    %         % select the cell in the table. Unfortunately, findjobj takes a while
    %         % but seems the only solution to select a cell programmatically
    %         jUIScrollPane = findjobj(fdata_tab_comp.table);
    %         jUITable = jUIScrollPane.getViewport.getView;
    %         jUITable.changeSelection(line_idx-1,0, false, false);
    %
    %         % and update selected_idx
    %         fdata_tab_comp.selected_idx = unique([fdata_tab_comp.selected_idx;line_idx]);
    %
    %         % and save back
    %         setappdata(main_figure,'fdata_tab',fdata_tab_comp);
    %     end
    
end

end