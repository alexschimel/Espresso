%% display_config_cl.m
%
% Class for Espresso features (polygon and points)
%
%% Help
%
% *PROPERTIES*
%
% * |Var_disp|: Description (Default: ).
% * |Cax_wc_int|: Description (Default: ).
% * |Cax_wc|: Description (Default: ).
% * |Cax_bs|: Description (Default: ).
% * |Cax_bathy|: Description (Default: ).
% * |Cmap|: Description (Default: ).
% * |Fdata_idx|: Description (Default: ).
% * |Iping|: Description (Default: ).
% * |AcrossDist|: Description (Default: ).
% * |MET_tmproj|: Description (Default: ).
% * |Mode|: Description (Default: ).
% * |StackPingWidth|: Description (Default: ).
% * |StackAngularWidth|: Description (Default: ).
% * |Act_features|: Description (Default: ).
%
% *METHODS*
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
classdef display_config_cl <handle
    
    properties (SetObservable = true)
        Var_disp
        Cax_wc_int
        Cax_wc
        Cax_bs
        Cax_bathy
        Cmap
        Fdata_idx
        Iping
        AcrossDist
        MET_tmproj
        Mode
        StackPingWidth
        StackAngularWidth
        StackAngularMode
        Act_features
    end
    
    methods
        function obj = display_config_cl(varargin)
            
            p = inputParser;
            addParameter(p,'Var_disp','wc_int',@(x) ismember(x,{'wc_int' 'bs' 'bathy'})); % variable to be displayed on the map
            addParameter(p,'Cmap','ek60',@(x) ismember(x,{'jet' 'parula' 'ek60' 'gray'}));
            addParameter(p,'Cax_wc_int',[-35 -15],@isnumeric); % colour axis limits for the map when variable displayed is integrated water column
            addParameter(p,'Cax_wc',[-50 -10],@isnumeric); % colour axis limits for the WC view
            addParameter(p,'Cax_bs',[-40 -15],@isnumeric); % colour axis limits for the map when variable displayed is backscatter
            addParameter(p,'Cax_bathy',[-50 -10],@isnumeric); % colour axis limits for the map when variable displayed is bathymetry
            addParameter(p,'Mode','Normal',@ischar); % Mode of mouse interaction with the map
            addParameter(p,'MET_tmproj','',@ischar); % UTM projection of the map
            addParameter(p,'Fdata_idx',1,@isinteger); % Index of active line
            addParameter(p,'Iping',1,@isinteger); % Index of current ping number
            addParameter(p,'AcrossDist',0,@isnumeric); % Across distance for pointer
            addParameter(p,'StackPingWidth',200,@isnumeric); % half-length of ping window for stacked view computation
            addParameter(p,'StackAngularWidth',[-10 10],@isnumeric); % angular aperture for stacked view computation (in degrees)
            addParameter(p,'StackAngularMode','range',@isnumeric);
            addParameter(p,'Act_features',{},@iscell); % active features
            
            parse(p,varargin{:});
            results = p.Results;
            props = fieldnames(results);
            
            for i = 1:length(props)
                obj.(props{i}) = results.(props{i});
            end
            
        end
    end
    
    methods
        function cax = get_cax(obj)
            switch obj.Var_disp
                case 'wc_int'
                    cax = obj.Cax_wc_int;
                case 'bs'
                    cax = obj.Cax_bs;
                case 'bathy'
                    cax = obj.Cax_bathy;
            end
            
        end
        
        function cax = set_cax(obj,cax)
            switch obj.Var_disp
                case 'wc_int'
                    obj.Cax_wc_int = cax;
                case 'bs'
                    obj.Cax_bs = cax;
                case 'bathy'
                    obj.Cax_bathy = cax;
            end
            
        end
        
        function zone = get_zone(obj)
            % get UTM zone as numerical
            
            tmp = textscan(obj.MET_tmproj,'utm%2d%c');
            zone = double(tmp{1});
            switch tmp{2}
                case 'S'
                    zone = -zone;
            end
        end
        
        function set_zone(obj,zone)
            % set UTM zone from numerical input
            
            if zone>0
                hemi = 'N';
            else
                hemi = 'S';
            end
            zone = abs(zone);
            
            tmp = ['utm' num2str(zone) hemi];
            
            obj.MET_tmproj = tmp;
     
        end
        
        function cleanup(obj,main_figure)
            
            %% re-initialize if there are no data to display
            
            fData_tot = getappdata(main_figure,'fData');
            
            if isempty(fData_tot)
                
                % clear all visible data
                no_data_clear_all_displays(main_figure);
                
                % reinitialize disp_config
                disp_config = display_config_cl();
                setappdata(main_figure,'disp_config',disp_config);
                
                return;
            end
            
            
            %% ensure disp_config info is correct

            % disp_config "Fdata_idx" should not exceed total number of fData loaded
            if obj.Fdata_idx > numel(fData_tot)
                obj.Fdata_idx = numel(fData_tot);
                obj.Iping = 1;
            end
            
            % Iping should not be superior to total number of pings in currenf fData
            fData = fData_tot{obj.Fdata_idx};
            datagramSource = fData.MET_datagramSource;
            if obj.Iping > numel(fData.(sprintf('%s_1P_PingCounter',datagramSource)))
                obj.Iping = 1;
            end
            
        end
        
    end
end

