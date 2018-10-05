% [fData] = CFF_mask_WC_data_v2(fData,varargin)
%
% DESCRIPTION
%
% Create a mask (PBS format) to remove parts of the data
%
% INPUT VARIABLES
%
% - varargin{1} "remove_angle": steering angle beyond which outer beams are
% removed (in deg ref acoustic axis)
%   - eg: 55 -> angles>55 and <-55 are removed
%   - inf (default) -> all angles are conserved
%
% - varargin{2} "remove_closerange": range from sonar (in m) within which
% samples are removed
%   - eg: 4 -> all samples within 4m range from sonar are removed
%   - 0 (default) -> all samples are conserved
%
% -varargin{3} "remove_bottomrange": range from bottom (in m) beyond which
% samples are removed. Range after bottom if positive, before bottom if
% negative
%   - eg: 2 -> all samples 2m AFTER bottom detect and beyond are removed
%   - eg: -3 -> all samples 3m BEFORE bottom detect and beyond are removed
%   (therefore including bottom detect)
%   - inf (default) -> all samples are conserved.
%
% - varargin{4} "mypolygon": horizontal polygon (in Easting, Northing
% coordinates) outside of which samples are removed.
%   - [] (default) -> all samples are conserved.
%
% OUTPUT VARIABLES
%
% - fData
%
% RESEARCH NOTES
%
% NEW FEATURES
%
% * 2017-10-10: new v2 functions because of dimensions swap (Alex Schimel)
% - 2016-12-01: Updating bottom range removal after change of bottom
% processing
% - 2016-11-07: First version. Code taken from CFF_filter_watercolumn.m
%
%%%
% Alex Schimel, Deakin University
%%%

% XXX: check that masking uses filtered bottom if it exists, original
% bottom if not

%% Function
function [fData] = CFF_mask_WC_data_v3(fData,varargin)


%% INPUT PARSING

remove_angle       = inf; % default
remove_closerange  = 0;   % default
remove_bottomrange = inf; % default
mypolygon          = [];  % default

if nargin==1
    % fData only. keep defaults
elseif nargin==2
    remove_angle = varargin{1};
elseif nargin==3
    remove_angle      = varargin{1};
    remove_closerange = varargin{2};
elseif nargin==4
    remove_angle       = varargin{1};
    remove_closerange  = varargin{2};
    remove_bottomrange = varargin{3};
elseif nargin==5
    remove_angle       = varargin{1};
    remove_closerange  = varargin{2};
    remove_bottomrange = varargin{3};
    mypolygon          = varargin{4};
else
    error('wrong number of input variables')
end


%% Source datagram
if isfield(fData,'WC_SBP_SampleAmplitudes')
    datagramSource = 'WC';
elseif isfield(fData,'WCAP_SBP_SampleAmplitudes')
    datagramSource = 'WCAP';
end


%% Extract dimensions
[nSamples, nBeams, nPings] = size(fData.(sprintf('%s_SBP_SampleAmplitudes',datagramSource)).Data.val);


%% Flag to reuse existing processed data file
if isfield(fData,'X_SBP_WaterColumnProcessed') && all(size(fData.X_SBP_WaterColumnProcessed.Data.val)==[nSamples,nBeams,nPings])
    
    % memmapfile exists and is reuseable. Data will be overwritten through
    % structure
    memmapfileAlreadyExists = 1;
    
    % re-initialize numerical arrays
    fData.X_SBP_WaterColumnProcessed.Data.val  = zeros(nSamples,nBeams,nPings,'int8');
    
else
    
    % memmapfile doesn't exist (or is to be overwritten). Data will be
    % written through fwrite 
    memmapfileAlreadyExists = 0;

    % create new memmap file
    wc_dir = CFF_WCD_memmap_folder(fData.ALLfilename{1});
    file_X_SBP_WaterColumnProcessed  = fullfile(wc_dir,'X_SBP_WaterColumnProcessed.dat');
    fidMask = fopen(file_X_SBP_WaterColumnProcessed,'w+');
    
end


%% Block processing

% main computation section will be done in blocks, and saved as numerical
% arrays or memmapfile depending on fData.(sprintf('%s_SBP_SampleAmplitudes',datagramSource)).
blockLength = 50;
nBlocks = ceil(nPings./blockLength);
blocks = [ 1+(0:nBlocks-1)'.*blockLength , (1:nBlocks)'.*blockLength ];
blocks(end) = nPings;

soundSpeed          = fData.(sprintf('%s_1P_SoundSpeed',datagramSource)).*0.1; %m/s
samplingFrequencyHz = fData.(sprintf('%s_1P_SamplingFrequencyHz',datagramSource)); %Hz
dr_samples = soundSpeed./(samplingFrequencyHz.*2);

idx_samples = (1:nSamples)';

for iB = 1:nBlocks
    
    % list of pings in this block
    blockPings  = (blocks(iB,1):blocks(iB,2));
    nBlockPings = length(blockPings);
    
    ranges = CFF_get_samples_range( idx_samples, fData.(sprintf('%s_BP_StartRangeSampleNumber',datagramSource))(:,blockPings), dr_samples(blockPings));
    
    % MASK 1: OUTER BEAMS REMOVAL
    if ~isinf(remove_angle)
        
        % extract needed data
        angles = fData.WC_BP_BeamPointingAngle(:,blockPings);
        
        % build mask: 1: to conserve, 0: to remove
        X_BP_OuterBeamsMask = int8( angles>=-abs(remove_angle)*100 & angles<=abs(remove_angle)*100 );
        
        X_1BP_OuterBeamsMask = permute(X_BP_OuterBeamsMask ,[3,1,2]);
        
        clear X_BP_OuterBeamsMask
        
    else        
        
        % conserve all data
        X_1BP_OuterBeamsMask = ones(1,nBeams,nBlockPings,'int8');
        
    end
    
    % MASK 2: CLOSE RANGE REMOVAL
    if remove_closerange>0
         
        % build mask: 1: to conserve, 0: to remove
        X_SBP_CloseRangeMask = int8(ranges>=remove_closerange);
          
    else
        
        % conserve all data
        X_SBP_CloseRangeMask = ones(nSamples,nBeams,nBlockPings,'int8');
        
    end
    
    % MASK 3: BOTTOM RANGE REMOVAL
    if ~isinf(remove_bottomrange)
        
        % extract needed data
        theta = fData.(sprintf('%s_BP_BeamPointingAngle',datagramSource))(:,blockPings)/100/180*pi;
        
        psi = 1.5/180*pi./sqrt(cos(theta));
        
        idx_theta_faible = cos(theta)>cos(theta-psi/2);
        idx_theta_fort = cos(theta)<=cos(theta-psi/2);
        
        M = zeros(size(theta),'single');
        M(idx_theta_faible) = (1./cos(theta(idx_theta_faible)+psi(idx_theta_faible)/2)-1./cos(theta(idx_theta_faible))).*fData.X_BP_bottomRange(idx_theta_faible);
        M(idx_theta_fort) = (1./cos(theta(idx_theta_fort)+psi(idx_theta_fort)/2)-1./cos(theta(idx_theta_fort)-psi(idx_theta_fort)/2)).*fData.X_BP_bottomRange(idx_theta_fort);
        
        % calculate max sample beyond which mask is to be applied
        X_BP_maxRange  = fData.X_BP_bottomRange(:,blockPings) + (remove_bottomrange-abs(M));
        X_BP_maxSample = bsxfun(@rdivide,X_BP_maxRange,dr_samples(blockPings));
        X_BP_maxSample = round(X_BP_maxSample);
        X_BP_maxSample(X_BP_maxSample>nSamples|isnan(X_BP_maxSample)) = nSamples;
        
        % build list of indices for each beam & ping
        [PP,BB] = meshgrid((1:nBlockPings),(1:nBeams));
        maxSubs = [X_BP_maxSample(:),BB(:),PP(:)];
        
        % build mask: 1: to conserve, 0: to remove
        X_SBP_BottomRangeMask = zeros(nSamples,nBeams,nBlockPings,'int8');
        for ii = 1:size(maxSubs,1)
            X_SBP_BottomRangeMask(1:maxSubs(ii,1),maxSubs(ii,2),maxSubs(ii,3)) = 1;
        end
        
        X_SBP_BottomRangeMask(isnan(X_BP_maxRange)) = 0;
        clear PP BB maxSubs X_BP_maxRange X_BP_maxSample
        
    else
        
        % conserve all data
        X_SBP_BottomRangeMask = ones(nSamples,nBeams,nBlockPings,'int8');
        
    end
    
    % MASK 4: OUTSIDE POLYGON REMOVAL
    if ~isempty(mypolygon)
        
        % build mask: 1: to conserve, 0: to remove
        X_SBP_PolygonMask = inpolygon( fData.X_SBP_sampleEasting.Data.val(:,:,blockPings), ...
                                       fData.X_SBP_sampleNorthing.Data.val(:,:,blockPings), ...
                                       mypolygon(:,1), ...
                                       mypolygon(:,2));
        X_SBP_PolygonMask = int8(X_SBP_PolygonMask);
        
    else
        
        % conserve all data
        X_SBP_PolygonMask = ones(nSamples,nBeams,nBlockPings,'int8');
        
    end
    
    % MULTIPLYING ALL MASKS
    X_SBP_TotalMask = bsxfun(@times,X_1BP_OuterBeamsMask,(X_SBP_CloseRangeMask.*X_SBP_BottomRangeMask.*X_SBP_PolygonMask));
    
    % get raw data and apply mask
    [X_SBP_WaterColumnProcessed, nan_val] = CFF_get_wc_data(fData,sprintf('%s_SBP_SampleAmplitudes',datagramSource),blockPings,1,1,'raw');
    X_SBP_WaterColumnProcessed(X_SBP_TotalMask==0) = nan_val;
    
    % saving
    if memmapfileAlreadyExists
        % save in data
        fData.X_SBP_WaterColumnProcessed.Data.val(:,:,blockPings) = X_SBP_WaterColumnProcessed;
    else
        % write into binary files:
        fwrite(fidMask,X_SBP_WaterColumnProcessed,'int8');
    end
    
end

%% finalize

% if memmap files, some finishing up code necessary...
if ~memmapfileAlreadyExists
    
    % close binary file
    fclose(fidMask);

    % add to fData as memmapfile
    fData.X_SBP_WaterColumnProcessed = memmapfile(file_X_SBP_WaterColumnProcessed, 'Format',{'int8' [nSamples nBeams nPings] 'val'},'repeat',1,'writable',true);

end
