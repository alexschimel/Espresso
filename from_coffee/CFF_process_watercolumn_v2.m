%% CFF_process_watercolumn_v2.m
%
% Calculates the XY position in the swathe frame and the XYZ position in
% the geographical frame of each WC sample.
%
% Important Note: this code executes the same calculations on the WC
% samples as CFF_process_WC_bottom_detect_v2.m executes on the bottom
% detection samples. (The reason they're separated is to allow reprocessing
% bottom detect after filtering, without reprocessing the samples). If an
% improvement is made to one of these two functions, do it on the other as
% well.
%
%% Help
%
% *USE*
%
% TODO: write longer description of function
%
% *INPUT VARIABLES*
%
% * |input_variable_1|: TODO: write description and info on variable
%
% *OUTPUT VARIABLES*
%
% * |output_variable_1|: TODO: write description and info on variable
%
% *RESEARCH NOTES*
%
% *NEW FEATURES*
%
% * 2017-10-10: removed the saving of beampointinganglerad (Alex Schimel)
% * 2017-10-10: updated header and some comments and order of calculations
% after updating CFF_process_WC_bottom_detect_v2.m (Alex Schimel).
% * 2017-10-06: new header (Alex Schimel).
% * 2017-10-06: saving as new version (v2) because change in order of
% dimensions (Alex Schimel).
% * 2017-10-06: complete revamping for big files using memmapfile
% * 2017-09-26: Changed the building of "SBP_" arrays from using repmat to
% using multiplications by ones arrays. Takes much less time and memory for
% bigger files.
% * 2016-12-01: Removed the bottom detect part and put it in its own
% function (CFF_process_WC_bottom_detect.m)
% * 2014-02-26: First version. Code adapted from old processing scripts
%
% *EXAMPLE*
%
% TODO: write examples
%
% *AUTHOR, AFFILIATION & COPYRIGHT*
%
% Alexandre Schimel, NIWA.

%% Function
function [fData] = CFF_process_watercolumn_v2(fData,varargin)

%% input parsing

% init
p = inputParser;

% required
addRequired(p,'fData',@isstruct);

% parse
parse(p,fData,varargin{:})

% get results
% no optional
clear p


%% Extract data

% Extract needed ping info
X_11P_soundSpeed          = permute(fData.WC_1P_SoundSpeed.*0.1,[3,1,2]); %m/s
X_11P_samplingFrequencyHz = permute(fData.WC_1P_SamplingFrequencyHz,[3,1,2]); %Hz
X_11P_sonarHeight         = permute(fData.X_1P_pingH,[3,1,2]); %m
X_11P_sonarEasting        = permute(fData.X_1P_pingE,[3,1,2]); %m
X_11P_sonarNorthing       = permute(fData.X_1P_pingN,[3,1,2]); %m
X_11P_gridConvergenceDeg  = permute(fData.X_1P_pingGridConv,[3,1,2]); %deg
X_11P_vesselHeadingDeg    = permute(fData.X_1P_pingHeading,[3,1,2]); %deg
X_1_sonarHeadingOffsetDeg = fData.IP_ASCIIparameters.S1H; %deg

% Extract needed beam info
X_1BP_startRangeSampleNumber = permute(fData.WC_BP_StartRangeSampleNumber,[3,1,2]);
X_1BP_beamPointingAngleDeg   = permute(fData.WC_BP_BeamPointingAngle.*0.01,[3,1,2]); %deg
X_1BP_beamPointingAngleRad   = deg2rad(X_1BP_beamPointingAngleDeg);

% dimensions
[nSamples,nBeams,nPings] = size(fData.WC_SBP_SampleAmplitudes.Data.val);


%% Pre Computations

% OWTT distance traveled in one sample
fData.X_11P_oneSampleDistance = X_11P_soundSpeed./(X_11P_samplingFrequencyHz.*2);

% Compute the horizontal rotation angle between the swath frame (Ys forward
% and Yp northing)
% In THEORY, real-time compensation of roll and pitch means the Z for the
% swath frame is exactly the same as Z for elevation, so that we only need
% to rotate in the horizontal frame. In effect, we may want to recompute
% the true up pointing angle for the swath. For now, we'll make it simple:
X_11P_thetaDeg = - mod( X_11P_gridConvergenceDeg + X_11P_vesselHeadingDeg + X_1_sonarHeadingOffsetDeg, 360 );
X_11P_thetaRad = deg2rad(X_11P_thetaDeg);

% Index of samples (starting with zero)
X_S1_indices = (0:nSamples-1)';


%% Memory Map flag
if isobject(fData.WC_SBP_SampleAmplitudes)
    memoryMapFlag = 1;
else
    memoryMapFlag = 0;
end

%% init arrays

if memoryMapFlag
    
    % create binary files for each variable of interest
    file_X_SBP_sampleRange = ['.' filesep 'temp' filesep 'X_SBP_sampleRange.dat'];
    fileID_X_SBP_sampleRange = fopen(file_X_SBP_sampleRange,'w+');
    file_X_SBP_sampleUpDist = ['.' filesep 'temp' filesep 'X_SBP_sampleUpDist.dat'];
    fileID_X_SBP_sampleUpDist = fopen(file_X_SBP_sampleUpDist,'w+');
    file_X_SBP_sampleAcrossDist = ['.' filesep 'temp' filesep 'X_SBP_sampleAcrossDist.dat'];
    fileID_X_SBP_sampleAcrossDist = fopen(file_X_SBP_sampleAcrossDist,'w+');
    file_X_SBP_sampleEasting = ['.' filesep 'temp' filesep 'X_SBP_sampleEasting.dat'];
    fileID_X_SBP_sampleEasting = fopen(file_X_SBP_sampleEasting,'w+');
    file_X_SBP_sampleNorthing = ['.' filesep 'temp' filesep 'X_SBP_sampleNorthing.dat'];
    fileID_X_SBP_sampleNorthing = fopen(file_X_SBP_sampleNorthing,'w+');
    file_X_SBP_sampleHeight = ['.' filesep 'temp' filesep 'X_SBP_sampleHeight.dat'];
    fileID_X_SBP_sampleHeight = fopen(file_X_SBP_sampleHeight,'w+');
    
else
    
    % initialize numerical arrays
    fData.X_SBP_sampleRange.Data.val      = nan(nSamples,nBeams,nPings);
    fData.X_SBP_sampleUpDist.Data.val     = nan(nSamples,nBeams,nPings);
    fData.X_SBP_sampleAcrossDist.Data.val = nan(nSamples,nBeams,nPings);
    fData.X_SBP_sampleEasting.Data.val    = nan(nSamples,nBeams,nPings);
    fData.X_SBP_sampleNorthing.Data.val   = nan(nSamples,nBeams,nPings);
    fData.X_SBP_sampleHeight.Data.val     = nan(nSamples,nBeams,nPings);
    
end


%% Block processing

% main computation section will be done in blocks, and saved as numerical
% arrays or memmapfile depending on fData.WC_SBP_SampleAmplitudes.
% 
% I tested a number of block lengths and 3,4,5 seem to perform best. 1 is
% pretty long and 2 still quite long. Large numbers: 20, 50, 100 perform
% worst and worst. 
blockLength = 5;
nBlocks = ceil(nPings./blockLength);
blocks = [ 1+(0:nBlocks-1)'.*blockLength , (1:nBlocks)'.*blockLength ];
blocks(end) = nPings;

for iB = 1:nBlocks
    
    % txt = sprintf('block #%i/%i',iB,nBlocks);
    % disp(txt);
    
    % list of pings in this block
    blockPings  = (blocks(iB,1):blocks(iB,2));
    
    % range = oneSampleDistance*(sampleIndex+startRangeSampleNumber)
    X_SBP_sampleRange = bsxfun(@times,bsxfun(@plus,X_S1_indices,X_1BP_startRangeSampleNumber(:,:,blockPings)),fData.X_11P_oneSampleDistance(:,:,blockPings));
    
    % Cartesian coordinates in the swath frame:
    % - origin: sonar face
    % - Xs: across distance (positive ~starboard) = -range*sin(pointingAngle)
    % - Ys: along distance (positive ~forward) = 0
    % - Zs: up distance (positive up) = -range*cos(pointingAngle)
    X_SBP_sampleUpDist     = bsxfun(@times,-X_SBP_sampleRange,cos(X_1BP_beamPointingAngleRad(:,:,blockPings)));
    X_SBP_sampleAcrossDist = bsxfun(@times,-X_SBP_sampleRange,sin(X_1BP_beamPointingAngleRad(:,:,blockPings)));
    
    % Projected coordinates:
    % - origin: the (0,0) Easting/Northing projection reference and datum reference
    % - Xp: Easting (positive East) = sonarEasting + sampleAcrossDist*cos(heading)
    % - Yp: Northing (grid North, positive North) = sonarNorthing + sampleAcrossDist*sin(heading)
    % - Zp: Elevation/Height (positive up) = sonarHeight + sampleUpDist
    X_SBP_sampleEasting  = bsxfun(@plus,X_11P_sonarEasting(:,:,blockPings),bsxfun(@times,X_SBP_sampleAcrossDist,cos(X_11P_thetaRad(:,:,blockPings))));
    X_SBP_sampleNorthing = bsxfun(@plus,X_11P_sonarNorthing(:,:,blockPings),bsxfun(@times,X_SBP_sampleAcrossDist,sin(X_11P_thetaRad(:,:,blockPings))));
    X_SBP_sampleHeight   = bsxfun(@plus,X_11P_sonarHeight(:,:,blockPings),X_SBP_sampleUpDist);
    
    if memoryMapFlag
        % write into binary files:
        fwrite(fileID_X_SBP_sampleRange,X_SBP_sampleRange,'single');
        fwrite(fileID_X_SBP_sampleUpDist,X_SBP_sampleUpDist,'single');
        fwrite(fileID_X_SBP_sampleAcrossDist,X_SBP_sampleAcrossDist,'single');
        fwrite(fileID_X_SBP_sampleEasting,X_SBP_sampleEasting,'double');
        fwrite(fileID_X_SBP_sampleNorthing,X_SBP_sampleNorthing,'double');
        fwrite(fileID_X_SBP_sampleHeight,X_SBP_sampleHeight,'single');
    else
        % save in data
        fData.X_SBP_sampleRange.Data.val(:,:,blockPings)      = X_SBP_sampleRange;
        fData.X_SBP_sampleUpDist.Data.val(:,:,blockPings)     = X_SBP_sampleUpDist ;
        fData.X_SBP_sampleAcrossDist.Data.val(:,:,blockPings) = X_SBP_sampleAcrossDist;
        fData.X_SBP_sampleEasting.Data.val(:,:,blockPings)    = X_SBP_sampleEasting;
        fData.X_SBP_sampleNorthing.Data.val(:,:,blockPings)   = X_SBP_sampleNorthing;
        fData.X_SBP_sampleHeight.Data.val(:,:,blockPings)     = X_SBP_sampleHeight;
    end
    
    
end


%% finalize

% if memmap files, some finishing up code necessary...
if memoryMapFlag
    
    % close binary files
    fclose(fileID_X_SBP_sampleRange);
    fclose(fileID_X_SBP_sampleUpDist);
    fclose(fileID_X_SBP_sampleAcrossDist);
    fclose(fileID_X_SBP_sampleEasting);
    fclose(fileID_X_SBP_sampleNorthing);
    fclose(fileID_X_SBP_sampleHeight);
    
    % re-open files as memmapfile
    fData.X_SBP_sampleRange      = memmapfile(file_X_SBP_sampleRange,      'Format',{'single' [nSamples nBeams nPings] 'val'},'repeat',1,'writable',false);
    fData.X_SBP_sampleUpDist     = memmapfile(file_X_SBP_sampleUpDist,     'Format',{'single' [nSamples nBeams nPings] 'val'},'repeat',1,'writable',false);
    fData.X_SBP_sampleAcrossDist = memmapfile(file_X_SBP_sampleAcrossDist, 'Format',{'single' [nSamples nBeams nPings] 'val'},'repeat',1,'writable',false);
    fData.X_SBP_sampleEasting    = memmapfile(file_X_SBP_sampleEasting,    'Format',{'double' [nSamples nBeams nPings] 'val'},'repeat',1,'writable',false);
    fData.X_SBP_sampleNorthing   = memmapfile(file_X_SBP_sampleNorthing,   'Format',{'double' [nSamples nBeams nPings] 'val'},'repeat',1,'writable',false);
    fData.X_SBP_sampleHeight     = memmapfile(file_X_SBP_sampleHeight,     'Format',{'single' [nSamples nBeams nPings] 'val'},'repeat',1,'writable',false);
    
end


