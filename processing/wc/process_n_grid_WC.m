%
% NOTE: if I did the job well, this function is now never called anymore.
% TO delete... Alex 4th oct 18
%
%
%% Function
function fData = process_n_grid_WC(fData,varargin)

%% input parsing

p = inputParser;

addRequired(p,'fData',@(x) isstruct(x)||isempty(x))

addParameter(p,'bot_filter',1,@isnumeric);
addParameter(p,'mask_params',struct('r_min',1,'r_bot',1,'angle_mask',inf),@isstruct);
addParameter(p,'masking',1,@isnumeric);
addParameter(p,'sidelobe',1,@isnumeric);
addParameter(p,'process',0,@isnumeric);
addParameter(p,'grid',0,@isnumeric);
addParameter(p,'dataToGrid','original',@(x) ischar(x));
addParameter(p,'res',1,@(x) isnumeric(x)&&x>0);
addParameter(p,'vert_res',1,@(x) isnumeric(x)&&x>0);
addParameter(p,'dim','3D',@(x) ismember(x,{'2D' '3D'}));
addParameter(p,'dr_sub',4,@(x) isnumeric(x)&&x>0);
addParameter(p,'db_sub',2,@(x) isnumeric(x)&&x>0);
addParameter(p,'e_lim',[],@isnumeric);
addParameter(p,'n_lim',[],@isnumeric);

parse(p,fData,varargin{:});


%% bottom filtering
if  p.Results.bot_filter>0 && p.Results.process == 1
    
    % parameters
    flagParams.type = 'all';
    flagParams.variable = 'slope';
    flagParams.threshold = 30;
    
    disp('...Filtering bottom detect...');
    
    fData = CFF_filter_WC_bottom_detect_v2(fData,...
        'method','filter',...
        'pingBeamWindowSize',[3 3],...
        'maxHorizDist',inf,...
        'flagParams',flagParams,...
        'interpolate','yes');
end


%% masking and filtering sidelobe artefact
if ( p.Results.masking>0 && p.Results.process==1 ) || ~isfield(fData,'X_SBP_Masked')
    
    disp('...Creating mask...');
    
    fData = CFF_mask_WC_data_v3(fData,p.Results.mask_params.angle_mask,p.Results.mask_params.r_min,-p.Results.mask_params.r_bot);
    
    disp('...Filtering sidelobe artifacts...');
    
    fData = CFF_filter_WC_sidelobe_artifact_v3(fData,2);
    
end

%% gridding
if p.Results.grid>0
    
    disp('...Gridding water-column data...');
    
    fData = CFF_grid_watercolumn_v3(fData,...
        'dataToGrid',p.Results.dataToGrid,...
        'res',p.Results.res,...
        'vert_res',p.Results.vert_res,...
        'dim',p.Results.dim,...
        'dr_sub',p.Results.dr_sub,...
        'db_sub',p.Results.db_sub,...
        'e_lim',p.Results.e_lim,...
        'n_lim',p.Results.n_lim);
    
end