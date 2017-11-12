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
    end
    
    methods
        function obj =display_config_cl(varargin)
            
            p = inputParser;
            addParameter(p,'Var_disp','wc_int',@(x) ismember(x,{'wc_int' 'bs' 'bathy'}));
            addParameter(p,'Cmap','ek60',@(x) ismember(x,{'jet' 'parula' 'ek60' 'gray'}));
            addParameter(p,'Cax_wc_int',[-35 -15],@isnumeric);
            addParameter(p,'Cax_wc',[-50 -10],@isnumeric);
            addParameter(p,'Cax_bs',[-40 -15],@isnumeric);
            addParameter(p,'Cax_bathy',[-50 -10],@isnumeric);
            addParameter(p,'MET_tmproj','',@ischar);
            
            addParameter(p,'Fdata_idx',1,@isnumeric);
            addParameter(p,'Iping',1,@isnumeric);
            addParameter(p,'AcrossDist',1,@isnumeric);
            
            parse(p,varargin{:});
            results=p.Results;
            props=fieldnames(results);
            
            for i=1:length(props)
                obj.(props{i})=results.(props{i});
            end
            
        end
    end
    
    methods
        function cax=get_cax(obj)
            switch obj.Var_disp
                case 'wc_int'
                    cax=obj.Cax_wc_int;
                case 'bs'
                    cax=obj.Cax_bs;
                case 'bathy'
                    cax=obj.Cax_bathy;
            end
            
        end
        
        function cax=set_cax(obj,cax)
            switch obj.Var_disp
                case 'wc_int'
                    obj.Cax_wc_int=cax;
                case 'bs'
                    obj.Cax_bs=cax;
                case 'bathy'
                    obj.Cax_bathy=cax;
            end
            
        end
        function zone=get_zone(obj)
            tmp=textscan(obj.MET_tmproj,'utm%2d%c');
            zone=double(tmp{1});
            switch tmp{2}
                case 'S'
                    zone=-zone;
            end
        end
        
    end
end

