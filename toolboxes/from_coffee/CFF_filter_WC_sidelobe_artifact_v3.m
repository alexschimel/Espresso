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
% * 2018-10-09: in this new version, the filtering is using
% fData.X_SBP_WaterColumnProcessed as source data, whatever it is. By
% running this function just after CFF_initialize_WC_processing that copy
% the original data into fData.X_SBP_WaterColumnProcessed, one can filter
% the original data. If you mask after initialization, the filtering will
% be applied to that masked original data, etc.
% * 2016-10-10: v2 for new datasets recorded as SBP instead of PBS (Alex
% Schimel)
% - 2016-11-07: First version. Code taken from CFF_filter_watercolumn.m (Alex
% Schimel)
%
%%%
% Alex Schimel, Deakin University
%%%

%% Function
function [fData] = CFF_filter_WC_sidelobe_artifact_v3(fData,varargin)

%% INPUT PARSING

method_spec = 2; % default
if nargin == 1
    % fData only. keep default
elseif nargin == 2
    method_spec = varargin{1};
else
    error('wrong number of input variables')
end


%% Extract info about WCD
wcdata_class  = fData.X_1_WaterColumnProcessed_Class; % int8 or int16
wcdata_factor = fData.X_1_WaterColumnProcessed_Factor; 
wcdata_nanval = fData.X_1_WaterColumnProcessed_Nanval;
[nSamples, nBeams, nPings] = size(fData.X_SBP_WaterColumnProcessed.Data.val);


%% MAIN PROCESSING METHOD SWITCH
switch method_spec
    
    case 2
        
        
        %% prep
        
        % define 11 middle beams for reference level
        nadirBeams = (floor((nBeams./2)-5):ceil((nBeams./2)+5)); % middle beams
        
        %% Block processing
                
        % block processing setup
        blockLength = 10;
        nBlocks = ceil(nPings./blockLength);
        blocks = [ 1+(0:nBlocks-1)'.*blockLength , (1:nBlocks)'.*blockLength ];
        blocks(end,2) = nPings;
        
        for iB = 1:nBlocks
            
            % list of pings in this block
            blockPings  = (blocks(iB,1):blocks(iB,2));
            nBlockPings = length(blockPings);
            
            % grab data
            data = CFF_get_wc_data(fData,'X_SBP_WaterColumnProcessed',blockPings,1,1,'true');
            
            % grab bottom detect
            bottom = fData.X_BP_bottomSample(:,blockPings);
            
            % mean level across all beams for each range (and each ping)
            meanAcrossBeams = mean(data,2,'omitnan');
            
            % find the reference level as the median level of all samples above the median bottom sample in nadir beams:
            nadirBottom = median(bottom(nadirBeams,:)); % median value -> bottom            
            refLevel = nan(1,1,nBlockPings);
            for iP = 1:nBlockPings
                refLevel(1,1,iP) = nanmedian(reshape(data(1:nadirBottom(iP),nadirBeams,:),1,[]));
            end
            
            % statistical compensation. removing mean, then adding
            % reference level, like everyone does (correction "a" in
            % Parnum's thesis)
            data = bsxfun(@plus,bsxfun(@minus,data,meanAcrossBeams),refLevel);
            
            % convert result back into proper format
            data = data./wcdata_factor;
            data(isnan(data)) = wcdata_nanval;
            data = cast(data,wcdata_class);
            
            % save in array
            fData.X_SBP_WaterColumnProcessed.Data.val(:,:,blockPings) = data;
            
            % note that other compensations of that style are possible (to
            % be tested for performance
            
            % adding the reference level is simple, but begs the question
            % of what reference level to use? In my first paper, I
            % suggested not intriducing a reference level at all, i.e.:
            % X_SBP_L1 = bsxfun(@minus,thisPing,meanAcrossBeams);
            
            % Or we can make the compensation more complicated, for example
            % including normalization for std (correction "b" in Parnum):
            % stdAcrossBeams  = std(thisPing,[],2,'omitnan');
            % X_SBP_L1 = bsxfun(@rdivide,bsxfun(@minus,thisPing,meanAcrossBeams),stdAcrossBeams) + refLevel;
            
            % Or, going even further, re-introducing a reference standard
            % deviation:
            % stdRefLevel = std(reshape(thisPing((1:nadirBottom),nadirBeams),1,[]),'omitnan');
            % X_SBP_L1 = bsxfun(@rdivide,bsxfun(@minus,thisPing,meanAcrossBeams),stdAcrossBeams).*stdRefLevel + refLevel;

        end


    otherwise
        
        error('method_spec not recognised')
        
end
