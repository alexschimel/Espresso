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
function compute_and_add_mosaic(main_figure,E_lim,N_lim,mos_type)

fData_tot = getappdata(main_figure,'fData');
fdata_tab_comp = getappdata(main_figure,'fdata_tab');
idx_fData = find(cell2mat(fdata_tab_comp.table.Data(:,3)));
fData_tot = fData_tot(idx_fData);

if isempty(fData_tot)
    return;
end

% choose mode 'blend' (normal) or the new 'stitch'
mosaic_init = init_mosaic(E_lim,N_lim,0,'stitch');

[mosaic_init, fData_tot] = prep_mosaic(mosaic_init,fData_tot);

% mosaic requested outside of data available
if mosaic_init.res == 0
    
    disp('No mosaic was created because there were no data within requested bounds.');
    
    % reset normal interaction
    replace_interaction(main_figure,'interaction','WindowButtonDownFcn','id',1,'interaction_fcn',{@move_map_cback,main_figure},'pointer','arrow');
    
    return;
    
end

% get vertical extent of 3D grid displayed
        display_tab_comp = getappdata(main_figure,'display_tab');

switch mos_type
    case '2D'
        d_lim_sonar_ref  = [sscanf(display_tab_comp.d_line_min.Label,'%fm');sscanf(display_tab_comp.d_line_max.Label,'%fm')];
        d_lim_bottom_ref = [sscanf(display_tab_comp.d_line_bot_min.Label,'%fm');sscanf(display_tab_comp.d_line_bot_max.Label,'%fm')];
    case '3D'
        wc_proc_tab_comp = getappdata(main_figure,'wc_proc_tab');
        fData_tot = getappdata(main_figure,'fData');
        
        if isempty(fData_tot)
            return;
        end

        d_max=0;
        d_min=nan;
        
        d_max_bot=nan;
        d_min_bot=0;
        
        for ui=1:numel(fData_tot)
            d_min=nanmin(nanmin(fData_tot{ui}.X_BP_bottomHeight(:),d_min));
            d_max_bot=nanmax(d_max_bot,abs(d_min));
        end
        
        v_res = str2double(wc_proc_tab_comp.vert_grid_val.String);
        n_ref_bot = ceil(1/2*(d_max_bot-d_min_bot)/v_res);
        n_ref = ceil(1/2*(d_max-d_min)/v_res);
        d_ref_sonar  = linspace(d_min,d_max,n_ref);
        d_ref_bot  = linspace(d_min_bot,d_max_bot,n_ref_bot);
        d_lim_sonar_ref = [d_ref_sonar(1:end-1);d_ref_sonar(2:end)];
        d_lim_bottom_ref  = [d_ref_bot(1:end-1);d_ref_bot(2:end)];
               
end
mosaics = getappdata(main_figure,'mosaics');

for uir = 1:size(d_lim_sonar_ref,2)
    % compute mosaic
    mosaic = compute_mosaic(mosaic_init,fData_tot,d_lim_sonar_ref(:,uir),[nan nan]);
    
    mosaic.name  =sprintf('Sonar_ref_%.0f_%.0fm',d_lim_sonar_ref(1,uir),d_lim_sonar_ref(2,uir));
    mosaic.ID       = str2double(datestr(now,'yyyymmddHHMMSSFFF'));
    if ~any(~isnan(mosaic.mosaic_level),'all')
        continue;
    end
    if numel(mosaics) >= 1 
        
        id_g = mosaics(:).ID;
        
        idx_mosaic = find(id_g==mosaic.ID);
        
        if isempty(idx_mosaic)
            idx_mosaic = numel(mosaics)+1;
        end
        
        mosaics(idx_mosaic) = mosaic;
        
    else
        mosaics = mosaic;
    end
    
end

for uir = 1:size(d_lim_bottom_ref,2)
    % compute mosaic
    mosaic = compute_mosaic(mosaic_init,fData_tot,[nan nan],d_lim_bottom_ref(:,uir));
    mosaic.name  =sprintf('Bottom_ref_%.0f_%.0fm',d_lim_bottom_ref(1,uir),d_lim_bottom_ref(2,uir));
    mosaic.ID       = str2double(datestr(now,'yyyymmddHHMMSSFFF'));
    
    if ~any(~isnan(mosaic.mosaic_level),'all')
        continue;
    end
    
    if numel(mosaics) >= 1 
        
        id_g = mosaics(:).ID;
        
        idx_mosaic = find(id_g==mosaic.ID);
        
        if isempty(idx_mosaic)
            idx_mosaic = numel(mosaics)+1;
        end
        
        mosaics(idx_mosaic) = mosaic;
        
    else
        mosaics = mosaic;
    end
    
end

setappdata(main_figure,'mosaics',mosaics);

replace_interaction(main_figure,'interaction','WindowButtonDownFcn','id',1,'interaction_fcn',{@move_map_cback,main_figure},'pointer','arrow');

update_mosaic_tab(main_figure);

% update map, calling for new mosaic. Adjusting zoom on lines that
% contributed to the mosaic
update_map_tab(main_figure,0,1,1,idx_fData);
end


