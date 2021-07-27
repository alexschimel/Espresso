classdef display_config_cl <handle
    %DISPLAY_CONFIG_CL  Information about current display on Espresso
    %
    %   See also ESPRESSO.
    
    %   Authors: Alex Schimel (NIWA, alexandre.schimel@niwa.co.nz) and Yoann
    %   Ladroit (NIWA, yoann.ladroit@niwa.co.nz)
    %   2017-2021; Last revision: 27-07-2021
    
    properties (SetObservable = true)
        AcrossDist         % Across distance for pointer
        Act_features       % active features
        Cax_bathy          % colour axis limits for the map when variable displayed is bathymetry
        Cax_bs             % colour axis limits for the map when variable displayed is backscatter
        Cax_wc             % colour axis limits for the WC view
        Cax_wc_int         % colour axis limits for the map when variable displayed is integrated water column
        Cmap
        Fdata_ID           % ID of active line
        Iping              % Index of current ping number
        MET_datagramSource % Source datagram for watercolumn data
        MET_ellips         % UTM projection of the map, normally 'wgs84'
        MET_tmproj         % UTM projection of the map
        Mode               % Mode of mouse interaction with the map
        StackAngularMode
        StackAngularWidth  % angular aperture for stacked view computation (in degrees)
        StackPingWidth     % half-length of ping window for stacked view computation
        Var_disp           % variable to be displayed on the map
    end
    
    methods
        function obj = display_config_cl(varargin)
            % instantiation method
            
            % input parser
            p = inputParser;
            addParameter(p,'AcrossDist',0,@isnumeric);
            addParameter(p,'Act_features',{},@iscell);
            addParameter(p,'Cax_bathy',[-500 -100],@isnumeric);
            addParameter(p,'Cax_bs',[-40 -15],@isnumeric);
            addParameter(p,'Cax_wc',[-50 -10],@isnumeric);
            addParameter(p,'Cax_wc_int',[-35 -15],@isnumeric);
            addParameter(p,'Cmap','ek60',@(x) ismember(x,{'jet' 'parula' 'ek60' 'gray'}));
            addParameter(p,'Fdata_ID',[],@isnumeric);
            addParameter(p,'Iping',1,@isinteger);
            addParameter(p,'MET_datagramSource','',@(x) ismember(x,{'WC' 'AP'}));
            addParameter(p,'MET_ellips','',@ischar);
            addParameter(p,'MET_tmproj','',@ischar);
            addParameter(p,'Mode','Normal',@ischar);
            addParameter(p,'StackAngularMode','range',@isnumeric);
            addParameter(p,'StackAngularWidth',[-30 30],@isnumeric);
            addParameter(p,'StackPingWidth',300,@isnumeric);
            addParameter(p,'Var_disp','wc_int',@(x) ismember(x,{'wc_int' 'bs' 'bathy'}));
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
            % get color axis limits
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
            % set color axis limits
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
            % detect and clean up mismatches between disp_config and data
            % available.
            
            fData_tot = getappdata(main_figure,'fData');
            
            % 1. check there are data
            % if there are no data, re-initialize disp_config and exit
            if isempty(fData_tot)
                disp_config = display_config_cl();
                setappdata(main_figure,'disp_config',disp_config);
                return;
            end
            
            % 2. check fData_ID is correct
            % if disp_config's Fdata_ID is not in the list of existing
            % data, reset it to the first file and exit
            IDs = cellfun(@(c) c.ID,fData_tot);
            if ~ismember(obj.Fdata_ID, IDs)
                obj.Fdata_ID = IDs(1);
                obj.Iping = 1;
                return;
            end
            
            % 3. check iping is correct
            % Iping should not be superior to total number of pings in
            % current fData
            fData = fData_tot{obj.Fdata_ID == IDs};
            datagramSource = CFF_get_datagramSource(fData);
            nPings = numel(fData.(sprintf('%s_1P_PingCounter',datagramSource)));
            if obj.Iping > nPings
                obj.Iping = 1;
                return;
            end
            
        end
        
    end
end

