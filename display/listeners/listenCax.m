%% this_function_name.m
%
% _This section contains a very short description of the function, for the
% user to know this function is part of the software and what it does for
% it. Example below to replace. Delete these lines XXX._
%
% Template of ESP3 function header. XXX
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
function listenCax(src,~,main_figure)

% exit if no data loaded
fData_tot = getappdata(main_figure,'fData');

if isempty(fData_tot)
    return;
end

% get disp config
disp_config = getappdata(main_figure,'disp_config');

IDs = cellfun(@(c) c.ID,fData_tot);

if ~ismember(disp_config.Fdata_ID , IDs)
    disp_config.Fdata_ID = IDs(1);
    disp_config.Iping = 1;
    return;
end
cax = disp_config.get_cax();

switch src.Name
    
    case {'Cax_wc_int' 'Cax_bathy' 'Cax_bs'}
        for ui=1:numel(fData_tot)
            fData_tot_tmp=fData_tot{ui};
            map_tab_comp = getappdata(main_figure,'Map_tab');
            ax = map_tab_comp.map_axes;
            % colour axis for map (whether variable shown is integrated water
            % column, bathmyetry, or backscatter.
            %% Processed water column grid
            tag_id_wc = num2str(fData_tot_tmp.ID,'%.0f_wc');
            obj_wc = findobj(ax,'Tag',tag_id_wc);
            
            
            % grid transparency
            data = get(obj_wc,'CData');

            switch disp_config.Var_disp
                case 'wc_int'
                    if iscell(data)
                        for ic=1:numel(data)
                            set(obj_wc,'alphadata',data{ic} > cax(1));
                        end
                    else
                        set(obj_wc,'alphadata',data > cax(1));
                    end
                case {'bathy' 'bs'}
                    if iscell(data)
                        for ic=1:numel(data)
                            set(obj_wc,'alphadata',~isnan(data{ic}));
                        end
                    else
                        set(obj_wc,'alphadata',~isnan(data));
                    end
            end
        end
        caxis(ax,cax);
        
    case 'Cax_wc'
        % colour axis for WC view and stacked view
        
        wc_tab_comp = getappdata(main_figure,'wc_tab');
        wc_str = wc_tab_comp.data_disp.String;
        str_disp = wc_str{wc_tab_comp.data_disp.Value};
        
        switch str_disp
            
            case 'Phase'
                
                % update caxis on WC view
                caxis(wc_tab_comp.wc_axes,[-180 180]);
                alphadata = abs(get(wc_tab_comp.wc_gh,'CData'))>0;
                set(wc_tab_comp.wc_gh,'AlphaData',alphadata);
                
                % update caxis on stacked view
                stacked_wc_tab_comp = getappdata(main_figure,'stacked_wc_tab');
                caxis(stacked_wc_tab_comp.wc_axes,[-180 180]);
                stacked_alphadata = abs(get(stacked_wc_tab_comp.wc_gh,'CData'))>0;
                set(stacked_wc_tab_comp.wc_gh,'AlphaData',stacked_alphadata);
                
            otherwise
                % Original or Processed
                
                % update caxis on WC view
                caxis(wc_tab_comp.wc_axes,disp_config.Cax_wc);
                alphadata = get(wc_tab_comp.wc_gh,'CData') >= disp_config.Cax_wc(1);
                set(wc_tab_comp.wc_gh,'AlphaData',alphadata);
                
                % update caxis on stacked view
                stacked_wc_tab_comp = getappdata(main_figure,'stacked_wc_tab');
                caxis(stacked_wc_tab_comp.wc_axes,disp_config.Cax_wc);
                alphadata = get(stacked_wc_tab_comp.wc_gh,'CData') >= disp_config.Cax_wc(1);
                set(stacked_wc_tab_comp.wc_gh,'AlphaData',alphadata);
                
        end
        
end

end