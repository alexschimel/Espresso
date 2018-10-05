% [fData] = CFF_filter_WC_sidelobe_artifact_v2(fData,varargin)
%
% DESCRIPTION
%
% Filter water column artifact 
%
% INPUT VARIABLES
%
% - varargin{1} "method_spec": method for removal of specular reflection
%   - 2: (default)
%
% OUTPUT VARIABLES
%
% - fData
%
% RESEARCH NOTES
%
% dataset have three dimensions: ping #, beam # and sample #.
%
% calculating the average backcatter level across samples, would allow
% us to spot the beams that have constantly higher or lower energy in a
% given ping. Doing this only for samples in the watercolumn would allow us
% to normalize the energy in the watercolumn of a ping
%
% calculating the average backcatter across all beams would allow
% us to spot the samples that have constantly higher or lower energy in a
% given ping.
%
% MORE PROCESSING ideas:
%
% the circular artifact on the bottom is due to specular reflection
% affecting all beams.
% -> remove in each ping by averaging the level at a given range across
% all beams.
% -> working on several pings at a time would work if the responsible
% reflectors are present on successive pings. They also need to stay at the
% same range so that would need some form of heave compensation. For heave
% compensation, maybe use the mean calculated on each ping and line up the
% highest return (specular).
%
% now when the specular artefacts are gone, what of the level being uneven
% across the swath in the water column? A higher level on outer beams that
% seems constant through pings? A higher level on closer ranges?
% -> Maybe calculate an average level across all pings for each beam and
% sample?
% -> Maybe such artefact is due to the difference in volume insonified that
% is not properly compensated....
% -> Since the system is roll-compensated, a given beam correspond to
% different steering angles, hence different beamwidths.
% -> Average not for each beam, but for each steering angle. Sample should
% be fine.
% 
%
% NEW FEATURES
%
% * 2016-10-10: v2 for new datasets recorded as SBP instead of PBS (Alex
% Schimel)
% - 2016-11-07: First version. Code taken from CFF_filter_watercolumn.m (Alex
% Schimel)
%
%%%
% Alex Schimel, Deakin University
%%%

%% function starts
function [fData] = CFF_filter_WC_sidelobe_artifact_v3(fData,varargin)

% XXX: check that sidelobe filtering uses masked data if it exists,
% original data if not

%% Set methods
method_spec = 2; % default
if nargin == 1
    % fData only. keep default
elseif nargin == 2
    method_spec = varargin{1};
else
    error('wrong number of input variables')
end

%% Memory Map flag
if isfield(fData,'WC_SBP_SampleAmplitudes')
    start_fmt='WC_';
elseif isfield(fData,'WCAP_SBP_SampleAmplitudes')
    start_fmt='WCAP_';
end

if isobject(fData.(sprintf('%sSBP_SampleAmplitudes',start_fmt)))
    memoryMapFlag = 1;
    wc_dir=CFF_WCD_memmap_folder(fData.ALLfilename{1});
else
    memoryMapFlag = 0;
end

if isfield(fData,'X_SBP_WaterColumnProcessed')
     memoryMapFlag = 0;
end

% MAIN PROCESSING SWITCH
switch method_spec
    
    case 2
        
        % same but a little bit more complex       
        % Dimensions
        [nSamples,nBeams,nPings] = size(fData.(sprintf('%sSBP_SampleAmplitudes',start_fmt)).Data.val);
        
        % init arrays
        if memoryMapFlag
            % create binary file
            file_X_SBP_L1 = fullfile(wc_dir,'X_SBP_WaterColumnProcessed.dat');
            fileID_X_SBP_L1 = fopen(file_X_SBP_L1,'w+');
        end
        
        % define 11 middle beams for reference level
        nadirBeams = (floor((nBeams./2)-5):ceil((nBeams./2)+5)); % middle beams
        
        % block processing setup
        blockLength = 10;
        nBlocks = ceil(nPings./blockLength);
        blocks = [ 1+(0:nBlocks-1)'.*blockLength , (1:nBlocks)'.*blockLength ];
        blocks(end,2) = nPings;
        
        % per-block processing
    
        for iB = 1:nBlocks
            
            % grab data
            thisPing = CFF_get_wc_data(fData,sprintf('%sSBP_SampleAmplitudes',start_fmt),blocks(iB,1):blocks(iB,2),1,1);
            idx_nan = isnan(thisPing);
            thisBottom = fData.X_BP_bottomSample(:,blocks(iB,1):blocks(iB,2));
            
            % mean level across all beams for each range (and each ping)
            meanAcrossBeams = mean(thisPing,2,'omitnan');
            
            % find the reference level as the median level of all samples above the median bottom sample in nadir beams:
            nadirBottom = median(thisBottom(nadirBeams,:)); % median value -> bottom
            meanRefLevel = nanmean(reshape(thisPing((1:min(nadirBottom)),nadirBeams,:),1,[]));
            % question, should we calculate the mean in natural or in dB?
            
            % statistical compensation. removing mean, then adding
            % reference level, like everyone does (correction "a" in
            % Parnum's thesis)
            X_SBP_L1 = bsxfun(@minus,thisPing,(meanAcrossBeams)) + (meanRefLevel);
            X_SBP_L1(idx_nan)=-128/2;
            % note that other compensations of that style are possible (to
            % be tested for performance
            
            % adding the reference level is simple, but begs the question
            % of what reference level to use? In my first paper, I
            % suggested not intriducing a reference level at all, i.e.:
            % X_SBP_L1 = bsxfun(@minus,thisPing,meanAcrossBeams);
            
            % Or we can make the compensation more complicated, for example
            % including normalization for std (correction "b" in Parnum):
            % stdAcrossBeams  = std(thisPing,[],2,'omitnan');
            % X_SBP_L1 = bsxfun(@rdivide,bsxfun(@minus,thisPing,meanAcrossBeams),stdAcrossBeams) + meanRefLevel;
            
            % Or, going even further, re-introducing a reference standard
            % deviation:
            % stdRefLevel = std(reshape(thisPing((1:nadirBottom),nadirBeams),1,[]),'omitnan');
            % X_SBP_L1 = bsxfun(@rdivide,bsxfun(@minus,thisPing,meanAcrossBeams),stdAcrossBeams).*stdRefLevel + meanRefLevel;
            
            % saving result
            if memoryMapFlag
                % write into binary files:
                fwrite(fileID_X_SBP_L1,X_SBP_L1,'int8');
            else
                % save in array
                X_SBP_L1(fData.X_SBP_WaterColumnProcessed.Data.val(:,:,blocks(iB,1):blocks(iB,2))==-128/2)=-128/2;
                fData.X_SBP_WaterColumnProcessed.Data.val(:,:,blocks(iB,1):blocks(iB,2)) = X_SBP_L1;
            end
            
            clear X_SBP_L1 thisPing thisBottom meanAcrossBeams
            
        end
        
        % finalize if memmap files, some finishing up code necessary...
        if memoryMapFlag
            
            % close binary files
            fclose(fileID_X_SBP_L1);
            
            % re-open files as memmapfile
            fData.X_SBP_WaterColumnProcessed = memmapfile(file_X_SBP_L1, 'Format',{'int8' [nSamples nBeams nPings] 'val'},'repeat',1,'writable',true);
            
        end
        
  
    otherwise
        
        error('method_spec not recognised')
        
end
