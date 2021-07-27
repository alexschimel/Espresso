function [data, correction, ref_level] = CFF_filter_WC_sidelobe_artifact_CORE(data, fData, block_pings, params)
%CFF_FILTER_WC_SIDELOBE_ARTIFACT_CORE  One-line description
%
%   [data, correction] = CFF_filter_WC_sidelobe_artifact_CORE(data,
%   fData,block_pings) filters the sidelobe artifact in water-column data
%   "data", according to one of several methods to be eventually put as
%   controllable parameters. You need to input fData and block_pings here
%   to get information on the bottom samples.    
%
%   See also ESPRESSO.

%   Authors: Alex Schimel (NIWA, alexandre.schimel@niwa.co.nz) and Yoann
%   Ladroit (NIWA, yoann.ladroit@niwa.co.nz)
%   2017-2021; Last revision: 27-07-2021


%% set algorithm parameters here

if isempty(params)
    % mode of calculation of the average value across beams
    params.avg_calc = 'mean'; % 'mean' or 'median'
    
    % reference level type of calculation: constant or from ping data
    params.ref.type = 'from_ping_data'; % 'from_ping_data'; % 'cst' or 'from_ping_data'
    
    % if constant ref, set the value here (in dB)
    params.ref.cst = -70;
    
    % if reference from ping data, set the reference area here: data from
    % middle beams above bottom (nadirWC), or all data before minimum slant
    % range (cleanWC)
    params.ref.area = 'cleanWC'; % 'nadirWC' or 'cleanWC'
    
    % if reference from ping data, set mode of calculation of the reference
    % value here
    params.ref.val_calc = 'perc25'; % 'mean', 'median', 'mode', 'perc5', 'perc10', 'perc25'
end

%% average value across beams
switch params.avg_calc
    case 'mean'
        avg_across_beams = mean(data,2,'omitnan');
    case 'median'
        avg_across_beams = median(data,2,'omitnan');
end
    

%% reference level
switch params.ref.type
    
    case 'cst'        
        
        % constant reference level, as per parameter
        ref_level = params.ref.cst .* ones(1,1,numel(block_pings));
        
    case 'from_ping_data'
        
        % get closest bottom sample (minimum slant range) in each ping
        [num_samples, ~, ~] = size(data);
        bottom_samples = CFF_get_bottom_sample(fData);
        bottom_samples = bottom_samples(:,block_pings);
        closest_bottom_sample = nanmin(bottom_samples);
        closest_bottom_sample = nanmin(ceil(closest_bottom_sample),num_samples);
        
        % indices for data extraction (getting rid of surface noise)
        id_start = ceil(nanmin(closest_bottom_sample)/10);
        id_end   = ceil(nanmax(closest_bottom_sample));
        
        % extracting reference data
        switch params.ref.area
            
            case 'nadirWC'
                % using an average noise level from all samples in the
                % water column of this ping, above the bottom, within the
                % 11 beams closest to nadir.
                [~, num_beams, ~] = size(data);
                nadir_beams = (floor((num_beams./2)-5):ceil((num_beams./2)+5));
                ref_data = data(id_start:id_end,nadir_beams,:);
                
            case 'cleanWC'
                % using an average noise level from all samples in the
                % water column of this ping, within minimum slant range,
                % aka "clean watercolumn"
                ref_data = data(id_start:id_end,:,:);
                              
        end
        
        % nan all samples beyond minimum slant range in the extracted data
        idnan = id_start-1+(1:size(ref_data,1))' >= closest_bottom_sample;
        idnan = permute(idnan,[1 3 2]);
        idnan = repmat(idnan,1,size(ref_data,2),1);
        ref_data(idnan) = NaN;
        
        % calculate ref level
        switch params.ref.val_calc
            case 'mean'
                ref_level = nanmean(ref_data,[1 2]);
            case 'median'
                ref_level = nanmedian(ref_data,[1 2]);
            case 'mode'
                ref_level = mode(ref_data,[1 2]);
            case 'perc5'
                ref_level = prctile(ref_data,5,[1 2]);
            case 'perc10'
                ref_level = prctile(ref_data,10,[1 2]);
            case 'perc25'
                ref_level = prctile(ref_data,25,[1 2]);
        end
        
end



%% compensate data
data = data - avg_across_beams + single(ref_level);

% save mean across beams for further use
correction = avg_across_beams;



%% DVPT NOTES

% I originally developed several methods to filter the sidelobe artefact.
% The overall principle is normalization. Just as for seafloor backscatter
% you normalize the level across all angles by removing the average level
% computed across all angles, here with water-column, you normalize the
% level by removign the average level computed across all ranges.
%
% There are several levels of complexity possible.
%
% At the most basic, you really only need to remove the average. The
% results as an average of 0, which is not the normal range. This is what I
% did for seafloor backscatter in my first paper. In my original code, this
% was method 1.
%
% The next level of complexity is to reintroduce a reference level after
% removing the mean. This is the most common procedure, the one retained in
% the code  here (formerly known as method 2), and the one termed
% correction "a" in Parnum's thesis.


% Usually a "normalization" implies also the standard deviation: you
% remove the mean, then divide by the standard deviation, and only then add
% a reference level). This is correction "b" in Parnum.
% You'd need to calculate the std as
%       stdAcrossBeams = std(data,0,2,'omitnan');
% and in the final calculation do instead:
%       data = (data-avg_across_beams)./stdAcrossBeams + ref_level;

% Continuing further from Parnum's idea, you could reintroduce a reference
% standard deviation, just as the reference level is actually a reference
% mean. So in order you substract the mean, divide by the std, multiply by
% the reference std, and add the reference level.
% The reference std would be calculated in the same loop as that for
% reference level as:
%       refStd(1,1,iP) = nanstd(nadir_data(:));
% and reintroduced in the final calculation as:
%       data = refStd.*(data-avg_across_beams)./stdAcrossBeams + ref_level;
%
% Another note worth thinking about: Why normalizing only across ranges?
% What about the other dimensions? Normalizing across samples would be
% calculated as:
%       meanAcrossSamples = mean(data,1,'omitnan');
% Across pings as:
%       meanAcrossPings = mean(data,3,'omitnan');
% What about across more than one dimension? Is that possible?
%
% Last note: De Moustier came across a similar solution to filter sidelobe
% artefacts except it consisted in calculating the 75% percentiles across
% all ranges, rather than the mean. Also he did not introduce a reference
% level. It would go as something like this:
% [nSamples, ~, ~] = size(fData.X_SBP_WaterColumnProcessed.Data.val);
% for ip = 1:numel(block_pings)
%     thisPing = data(:,:,ip);
%     sevenfiveperc = nan(nSamples,1); % calculate 75th percentile across all ranges
%     for ismp = 1:nSamples
%         X = thisPing(ismp,:,:);
%         sevenfiveperc(ismp,1) = CFF_invpercentile(X,75);
%     end
%     thisPing_corrected =  thisPing - sevenfiveperc;
% end

