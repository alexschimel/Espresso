function [fData] = CFF_mask_WC_data_v3(fData,varargin)
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


%% Extract dimensions
[nSamples, nBeams, nPings] = size(fData.WC_SBP_SampleAmplitudes.Data.val);


%% Set methods
remove_angle       = inf; % default
remove_closerange  = 0; % default
remove_bottomrange = inf; % default
mypolygon          = []; % default
if nargin==1
    % fData only. keep defaults
elseif nargin==2
    remove_angle = varargin{1};
elseif nargin==3
    remove_angle = varargin{1};
    remove_closerange = varargin{2};
elseif nargin==4
    remove_angle = varargin{1};
    remove_closerange = varargin{2};
    remove_bottomrange =varargin{3};
elseif nargin==5
    remove_angle = varargin{1};
    remove_closerange = varargin{2};
    remove_bottomrange =varargin{3};
    mypolygon = varargin{4};
else
    error('wrong number of input variables')
end

%% Memory Map flag
if isobject(fData.WC_SBP_SampleAmplitudes)
    memoryMapFlag = 1;
else
    memoryMapFlag = 0;
end

if isfield(fData,'X_SBP_Masked')
     memoryMapFlag = 0;
end

%% init arrays

if memoryMapFlag
    % create binary file
    wc_dir=get_wc_dir(fData.ALLfilename{1});
    file_X_SBP_Mask = fullfile(wc_dir,'X_SBP_Masked.dat');
    fileID_X_SBP_Mask = fopen(file_X_SBP_Mask,'w+');
else
    % initialize numerical arrays
    fData.X_SBP_Masked.Data.val      = zeros(nSamples,nBeams,nPings,'int8');
end


%% Block processing

% main computation section will be done in blocks, and saved as numerical
% arrays or memmapfile depending on fData.WC_SBP_SampleAmplitudes.
blockLength = 50;
nBlocks = ceil(nPings./blockLength);
blocks = [ 1+(0:nBlocks-1)'.*blockLength , (1:nBlocks)'.*blockLength ];
blocks(end) = nPings;

soundSpeed          = fData.WC_1P_SoundSpeed.*0.1; %m/s
samplingFrequencyHz = fData.WC_1P_SamplingFrequencyHz; %Hz
dr_samples = soundSpeed./(samplingFrequencyHz.*2);


idx_samples = (1:nSamples)';

for iB = 1:nBlocks
    
    % txt = sprintf('block #%i/%i',iB,nBlocks);
    % disp(txt);
    
    % list of pings in this block
    blockPings  = (blocks(iB,1):blocks(iB,2));
    nBlockPings = length(blockPings);
    
      
    ranges=get_samples_range(...
        idx_samples,...
        fData.WC_BP_StartRangeSampleNumber(:,blockPings),...
        dr_samples(blockPings));
    
    
    % MASK 1: OUTER BEAMS REMOVAL
    if ~isinf(remove_angle)
        
        % extract needed data
        angles = fData.WC_BP_BeamPointingAngle(:,blockPings);
        
        % build mask: 1: to conserve, 0: to remove
        X_BP_AngleMask = int8( angles>=-abs(remove_angle)*100 & angles<=abs(remove_angle)*100 );
        
        X_1BP_Mask = permute(X_BP_AngleMask ,[3,1,2]);
        
        clear X_BP_AngleMask angles
        
    else        
        % conserve all data
        X_1BP_Mask = ones(nSamples,nBeams,nBlockPings,'int8');
        
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
        theta=fData.WC_BP_BeamPointingAngle(:,blockPings)/100/180*pi;
        
        psi=1.5/180*pi./sqrt(cos(theta));
        
        idx_theta_faible=cos(theta)>cos(theta-psi/2);
        idx_theta_fort=cos(theta)<=cos(theta-psi/2);
        
        M=zeros(size(theta),'single');
        M(idx_theta_faible)=(1./cos(theta(idx_theta_faible)+psi(idx_theta_faible)/2)-1./cos(theta(idx_theta_faible))).*fData.X_BP_bottomRange(idx_theta_faible);
        M(idx_theta_fort)=(1./cos(theta(idx_theta_fort)+psi(idx_theta_fort)/2)-1./cos(theta(idx_theta_fort)-psi(idx_theta_fort)/2)).*fData.X_BP_bottomRange(idx_theta_fort);
        
        
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
        
        X_SBP_BottomRangeMask(isnan(X_BP_maxRange))=0;
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
    X_SBP_Mask = bsxfun(@times,X_1BP_Mask,(X_SBP_CloseRangeMask.*X_SBP_BottomRangeMask.*X_SBP_PolygonMask));
    amp=single(fData.WC_SBP_SampleAmplitudes.Data.val(:,:,blockPings))./2;
    amp(X_SBP_Mask==0)=-128/2;
    % saving
    if memoryMapFlag
        % write into binary files:
        fwrite(fileID_X_SBP_Mask,amp,'int8');
    else
        % save in data
        fData.X_SBP_Masked.Data.val(:,:,blockPings) = amp;
    end
    
end

%% finalize

% if memmap files, some finishing up code necessary...
if memoryMapFlag
    
    % close binary files
    fclose(fileID_X_SBP_Mask);

    % re-open files as memmapfile
    fData.X_SBP_Masked = memmapfile(file_X_SBP_Mask, 'Format',{'int8' [nSamples nBeams nPings] 'val'},'repeat',1,'writable',true);

end
