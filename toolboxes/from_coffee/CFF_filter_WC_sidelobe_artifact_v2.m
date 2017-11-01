function [fData] = CFF_filter_WC_sidelobe_artifact_v2(fData,varargin)
% [fData] = CFF_filter_WC_sidelobe_artifact_v2(fData,varargin)
%
% DESCRIPTION
%
% Filter water column artifact 
%
% INPUT VARIABLES
%
% - varargin{1} "method_spec": method for removal of specular reflection
%   - 0: None. Keep original
%   - 1: in devpt
%   - 2: (default)
%   - 3: de Moustier's 75th percentile
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
if isobject(fData.WC_SBP_SampleAmplitudes)
    memoryMapFlag = 1;
    [tmpdir,~,~]=fileparts(fData.WC_SBP_SampleAmplitudes.Filename);
else
    memoryMapFlag = 0;
end

if isfield(fData,'X_SBP_L1')
     memoryMapFlag = 0;
end


% MAIN PROCESSING SWITCH
switch method_spec
    
    case 0
        
        % No filtering. Keep original
        if memoryMapFlag
            % create binary file
            
            file_X_SBP_L1 = fullfile(tmpdir,'X_SBP_L1.dat');
            % open
            fileID_X_SBP_L1 = fopen(file_X_SBP_L1,'w+');
            % write
            fwrite(fileID_X_SBP_L1,fData.WC_SBP_SampleAmplitudes.Data.val./2,'int8');
            % close
            fclose(fileID_X_SBP_L1);
            % Dimensions
            [nSamples,nBeams,nPings] = size(fData.WC_SBP_SampleAmplitudes.Data.val);
            % re-open as memmapfile
            fData.X_SBP_L1 = memmapfile(file_X_SBP_L1, 'Format',{'int8' [nSamples nBeams nPings] 'val'},'repeat',1,'writable',true);
        else
            fData.X_SBP_L1.Data.val = fData.WC_SBP_SampleAmplitudes.Data.val./2;
        end
        
    case 1
        
        % for each ping, and each sample range, calculate the average level
        % over all beams and remove it
        
        % Dimensions
        [nSamples,nBeams,nPings] = size(fData.WC_SBP_SampleAmplitudes.Data.val);
        
        % init arrays
        if memoryMapFlag
            % create binary file
            file_X_SBP_L1 = fullfile(tmpdir,'X_SBP_L1.dat');
            fileID_X_SBP_L1 = fopen(file_X_SBP_L1,'w+');
        else
            % initialize numerical arrays
            fData.X_SBP_L1.Data.val = zeros(nSamples,nBeams,nPings,'int8');
        end
        
        % Compute mean level across beams:
        meanAcrossBeams   = nanmean(fData.WC_SBP_SampleAmplitudes.Data.val./2,2);
        
        % remove this mean:
        X_SBP_L1 = bsxfun(@minus,fData.WC_SBP_SampleAmplitudes.Data.val./2,meanAcrossBeams); % removing mean across beams
        
        % note the same technique could maybe be applied in other
        % dimensions? across samples?
        % meanAcrossSamples = nanmean(fData.WC_SBP_SampleAmplitudes.Data.val./2,1);
        % X_SBP_L1 = bsxfun(@minus,fData.WC_SBP_SampleAmplitudes.Data.val./2,meanAcrossSamples); % removing mean across samples
        %
        % across pings?
        % meanAcrossPings   = nanmean(fData.WC_SBP_SampleAmplitudes.Data.val./2,3);
        % X_SBP_L1 = bsxfun(@minus,fData.WC_SBP_SampleAmplitudes.Data.val./2,meanAcrossPings); % removing mean across pings
        %
        % what about across pings then across samples? (VERY experimental)
        % X_SBP_L1 = bsxfun(@minus,bsxfun(@minus,fData.WC_SBP_SampleAmplitudes.Data.val./2,meanAcrossBeams),meanAcrossSamples); % removing mean across pings THEN mean across samples (experimental)
        %
        % Maybe something could be done with the std across dimensions?
        % stdAcrossSamples  = std(fData.WC_SBP_SampleAmplitudes.Data.val./2,[],1,'omitnan');
        % stdAcrossBeams    = std(fData.WC_SBP_SampleAmplitudes.Data.val./2,[],2,'omitnan');
        % stdAcrossPings    = std(fData.WC_SBP_SampleAmplitudes.Data.val./2,[],3,'omitnan');
        
        % saving result
        if memoryMapFlag
            % write into binary files:
            fwrite(fileID_X_SBP_L1,X_SBP_L1,'single');
        else
            % save in array
            fData.X_SBP_L1.Data.val = X_SBP_L1;
        end
        
        % finalize if memmap files, some finishing up code necessary...
        if memoryMapFlag
            
            % close binary files
            fclose(fileID_X_SBP_L1);
            
            % re-open files as memmapfile
            fData.X_SBP_L1 = memmapfile(file_X_SBP_L1, 'Format',{'int8' [nSamples nBeams nPings] 'val'},'repeat',1,'writable',true);
            
        end
        
    case 2
        
        % same but a little bit more complex
        
        % Dimensions
        [nSamples,nBeams,nPings] = size(fData.WC_SBP_SampleAmplitudes.Data.val);
        
        % init arrays
        if memoryMapFlag
            % create binary file
            file_X_SBP_L1 = fullfile(tmpdir,'X_SBP_L1.dat');
            fileID_X_SBP_L1 = fopen(file_X_SBP_L1,'w+');
        else
            % initialize numerical arrays
            fData.X_SBP_L1.Data.val = zeros(nSamples,nBeams,nPings,'int8');
        end
        
        % define 11 middle beams for reference level
        nadirBeams = (floor((nBeams./2)-5):ceil((nBeams./2)+5)); % middle beams
        
        % per-ping processing
        for ip = 1:nPings
            
            % grab data
            thisPing = double(fData.WC_SBP_SampleAmplitudes.Data.val(:,:,ip))./2;
            thisPing(thisPing<=-127/2)=nan;
            thisBottom = fData.X_BP_bottomSample(:,ip);
            
            % mean level across all beams for each range (and each ping)
            meanAcrossBeams = nanmean(thisPing,2);
            
            % find the reference level as the median level of all samples above the median bottom sample in nadir beams:
            nadirBottom = median(thisBottom(nadirBeams)); % median value -> bottom
            meanRefLevel = nanmean(reshape(thisPing((1:nadirBottom),nadirBeams),1,[]));
            % question, should we calculate the mean in natural or in dB?
            
            % statistical compensation. removing mean, then adding
            % reference level, like everyone does (correction "a" in
            % Parnum's thesis)
            X_SBP_L1 = bsxfun(@minus,thisPing,meanAcrossBeams) + meanRefLevel;
            X_SBP_L1(isnan(X_SBP_L1))=-128/2;
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
                fData.X_SBP_L1.Data.val(:,:,ip) = X_SBP_L1;
            end
            
            clear X_SBP_L1 thisPing thisBottom meanAcrossBeams
            
        end
        
        % finalize if memmap files, some finishing up code necessary...
        if memoryMapFlag
            
            % close binary files
            fclose(fileID_X_SBP_L1)
            
            % re-open files as memmapfile
            fData.X_SBP_L1 = memmapfile(file_X_SBP_L1, 'Format',{'int8' [nSamples nBeams nPings] 'val'},'repeat',1,'writable',true);
            
        end
        
    case 3
        
        % DEMOUSTIER'S CORRECTION USING PERCENTILES:
        
        % Dimensions
        [nSamples,nBeams,nPings] = size(fData.WC_SBP_SampleAmplitudes.Data.val);
        
         % init arrays
        if memoryMapFlag
            % create binary file
            file_X_SBP_L1 = fullfile(tmpdir,'X_SBP_L1.dat');
            fileID_X_SBP_L1 = fopen(file_X_SBP_L1,'w+');
        else
            % initialize numerical arrays
            fData.X_SBP_L1.Data.val = zeros(nSamples,nBeams,nPings,'int8');
        end
        
        % per-ping processing
        for ip = 1:nPings
            
            % grab data
            thisPing = double(fData.WC_SBP_SampleAmplitudes.Data.val(:,:,ip)./2);
            thisPing(thisPing==-128/2)=nan;
            % calculate 75th percentile
            sevenfiveperc = nan(nSamples,1);
            for ismp = 1:nSamples
                X = thisPing(ismp,:,:);
                sevenfiveperc(ismp,1) = CFF_invpercentile(X,75);
            end
            
            % statistical compensation:
            X_SBP_L1 =  bsxfun(@minus,thisPing,sevenfiveperc);
            
            % saving result
            if memoryMapFlag
                % write into binary files:
                fwrite(fileID_X_SBP_L1,X_SBP_L1,'int8');
            else
                % save in array
                fData.X_SBP_L1.Data.val(:,:,ip) = X_SBP_L1;
            end
            
            
        end
        
        % finalize if memmap files, some finishing up code necessary...
        if memoryMapFlag
            
            % close binary files
            fclose(fileID_X_SBP_L1);
            
            % re-open files as memmapfile
            fData.X_SBP_L1 = memmapfile(file_X_SBP_L1, 'Format',{'int8' [nSamples nBeams nPings] 'val'},'repeat',1,'writable',true);
            
        end
        
    otherwise
        
        error('method_spec not recognised')
        
end


%%
% old code to adapt:
%
%
%
% % computing correcting coefficients
% for ii=1:nPings
%
%     M = fData.WC_PBS_SampleAmplitudes(ii,:,:);
%     imagesc(M)
%
%     % Compute mean and std across all beams (except Nans)
%     meanAcrossBeams = nan(1,nSamples);
%     stdAcrossBeams = nan(1,nSamples);
%     for kk=1:nSamples
%         meanAcrossBeams(1,kk) = mean(M(~isnan(M(:,kk)),kk));
%         stdAcrossBeams(1,kk)  = std(M(~isnan(M(:,kk)),kk));
%     end
%
%     % remove one f them, check the quality in result
%     MCorr1 = M - ones(nBeams,1)*meanAcrossBeams;
%
%     % reference sample, use halfway to seafloor at nadir:
%     BeamPointingAngle = fData.WC_PB_BeamPointingAngle(ii,:);
%     [a,indnadir]=min(abs(BeamPointingAngle));
%     DetectedRange = fData.WC_PB_DetectedRangeInSamples(ii,indnadir);
%     StartRangeSampleNumber = fData.WC_PB_StartRangeSampleNumber(ii,indnadir);
%     refsample = round(0.5.*(DetectedRange+StartRangeSampleNumber));
%     refmean = meanAcrossBeams(refsample);
%     refstd = stdAcrossBeams(refsample);
%
%
%     %     bottom = fData.WC_PB_DetectedRangeInSamples(ii,:);
%     %     bottom(bottom==0)=NaN;
%     %     minBottom= min(bottom);
%     %     M2 = M(:,1:minBottom-1);
%     %
%     %     % mean and std across all samples (from 0 to just before shortest bottom range)
%     %     meanAcrossSamples = nan(nBeams,1);
%     %     stdAcrossSamples = nan(nBeams,1);
%     %     for jj=1:nBeams
%     %         meanAcrossSamples(jj,1) = mean(M2(jj,~isnan(M2(jj,:))));
%     %         stdAcrossSamples(jj,1)  = std(M2(jj,~isnan(M2(jj,:))));
%     %     end
%     %
%     %     % mean and std across a number of pings?
%     %     MCorr2 = M - meanAcrossSamples*ones(1,nSamples);
%     %     MCorr3 = M - ones(nBeams,1)*meanAcrossBeams - meanAcrossSamples*ones(1,nSamples);
%     %     % then remove both, try the two orders. check the differences
%
% end
%
%
% fDataCorr2 = (((fData - MeanAcrossAllBeams*ones(1,NumberOfBeams))./(StdAcrossAllBeams*ones(1,NumberOfBeams))) .* refstd) + refmean  ;
%
% fDataCorr = fDataCorr2;