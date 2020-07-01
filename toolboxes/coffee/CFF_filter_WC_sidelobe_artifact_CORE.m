%% CFF_filter_WC_sidelobe_artifact_CORE.m
%
% _This section contains a very short description of the function, for the
% user to know this function is part of the software and what it does for
% it. Example below to replace. Delete these lines XXX._
%
% Template of ESP3 function header. XXX
%
%% Help
%
% *USE*
%
% _This section contains a more detailed description of what the function
% does and how to use it, for the interested user to have an overall
% understanding of its function. Example below to replace. Delete these
% lines XXX._
%
% This is a text file containing the basic comment template to add at the
% start of any new ESP3 function to serve as function help. XXX
%
% *INPUT VARIABLES*
%
% _This section contains bullet points of input variables with description
% and information. Put input variable and other valid entries or defaults
% between | symbols so it shows as monospace. Information section to
% contain, in order: requirement (i.e. Required/Optional/Paramter), valid
% type (e.g. Num, Positive num, char, 1xN cell array, etc.) and default
% value if there is one (e.g. Default: '10'). Example below to replace.
% Delete these lines XXX._
%
% * |input_variable_1|: Description (Information). XXX
% * |input_variable_2|: Description (Information). XXX
% * |input_variable_3|: Description (Information). XXX
%
% *OUTPUT VARIABLES*
%
% _This section contains bullet points of output variables with description
% and information. See input variables for template. Example below to
% replace. Delete these lines XXX._
%
% * |output_variable_1|: Description (Information). XXX
% * |output_variable_2|: Description (Information). XXX
%
% *DEVELOPMENT NOTES*
%
% _This section describes what features are temporary, needed future
% developments and paper references. Example below to replace. Delete these
% lines XXX._
%
% * research point 1. XXX
% * research point 2. XXX
%
% *NEW FEATURES*
%
% _This section contains dates and descriptions of major updates. Example
% below to replace. Delete these lines XXX._
%
% * YYYY-MM-DD: second version. Describes the update. XXX
% * YYYY-MM-DD: first version. XXX
%
% *EXAMPLE*
%
% _This section contains examples of valid function calls. Note that
% example lines start with 3 white spaces so that the publish function
% shows them correctly as matlab code. Example below to replace. Delete
% these lines XXX._
%
%   example_use_1; % comment on what this does. XXX
%   example_use_2: % comment on what this line does. XXX
%
% *AUTHOR, AFFILIATION & COPYRIGHT*
%
% _This last section contains at least author name and affiliation. Delete
% these lines XXX._
%
% Yoann Ladroit, Alexandre Schimel, NIWA. XXX

%% Function
function [data, correction] = CFF_filter_WC_sidelobe_artifact_CORE(data, fData, block_pings)


%% set algorithm parameters here

% mode of calculation of the average value across beams
params.avg_calc = 'mean'; % 'mean' or 'median'

% reference level type of calculation: constant or from ping data
params.ref.type = 'from_ping_data'; % 'cst' or 'from_ping_data'

% if constant ref, set the value here (in dB)
params.ref.cst = -70;

% if reference from ping data, set the reference area here: data from
% middle beams above bottom (nadirWC), or all data before minimum slant
% range (cleanWC)
params.ref.area = 'cleanWC'; % 'nadirWC' or 'cleanWC'

% if reference from ping data, set mode of calculation of the reference
% value here
params.ref.val_calc = 'perc25'; % 'mean', 'median', 'mode', 'perc10', 'perc25'


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
        
        switch params.ref.area
            
            case 'nadirWC'
                % using an average noise level from all samples in the
                % water column of this ping, above the bottom, within the 
                % beams closest to nadir.
                
                % find the 11 beams nearest to nadir
                [num_samples, num_beams, ~] = size(data);
                nadir_beams = (floor((num_beams./2)-5):ceil((num_beams./2)+5));
                
                % calculate the average bottom detect for those beams for each ping
                bottom_samples = CFF_get_bottom_sample(fData);
                bottom_samples = bottom_samples(nadir_beams,block_pings);
                nadir_bottom = round(inpaint_nans(nanmin(bottom_samples)));
                nadir_bottom(nadir_bottom>num_samples) = num_samples;
                
                % init ref level vector
                ref_level = nan(1,1,numel(block_pings));
                
                % calculate ref level
                switch params.ref.val_calc
                    
                    case 'mean'
                        for iP = 1:numel(block_pings)
                            nadirWC = data(1:nadir_bottom(iP),nadir_beams,iP);
                            ref_level(1,1,iP) = nanmean(nadirWC(:));
                        end
                    case 'median'
                        for iP = 1:numel(block_pings)
                            nadirWC = data(1:nadir_bottom(iP),nadir_beams,iP);
                            ref_level(1,1,iP) = nanmedian(nadirWC(:));
                        end
                    case 'mode'
                        for iP = 1:numel(block_pings)
                            nadirWC = data(1:nadir_bottom(iP),nadir_beams,iP);
                            ref_level(1,1,iP) = mode(nadirWC(~isnan(nadirWC)));
                        end
                    case 'perc10'
                        for iP = 1:numel(block_pings)
                            nadirWC = data(1:nadir_bottom(iP),nadir_beams,iP);
                            ref_level(1,1,iP) = prctile(nadirWC(:),10);
                        end
                    case 'perc25'
                        for iP = 1:numel(block_pings)
                            nadirWC = data(1:nadir_bottom(iP),nadir_beams,iP);
                            ref_level(1,1,iP) = prctile(nadirWC(:),25);
                        end
                end

                
            case 'cleanWC'
                % using an average noise level from all samples in the
                % water column of this ping, within minimum slant range
                
                [num_samples, ~, ~] = size(data);
                
                bottom_samples = CFF_get_bottom_sample(fData);
                bottom_samples = bottom_samples(:,block_pings);
                closest_bottom_sample = nanmin(bottom_samples);
                closest_bottom_sample = nanmin(ceil(closest_bottom_sample),num_samples);
                
                % init ref level vector
                ref_level = nan(1,1,numel(block_pings));
                
                % calculate ref level
                id_start = ceil(nanmin(closest_bottom_sample)/10);%gettimg rid of surface noise. Removes spurious bands...
                id_end = ceil(nanmax(closest_bottom_sample));
                cleanWC = data(id_start:id_end,:,:);
                idnan=(id_start-1+(1:size(cleanWC,1))'>=closest_bottom_sample);
                idnan=permute(idnan,[1 3 2]);
                cleanWC(repmat(idnan,1,size(cleanWC,2),1))=nan;
                
                switch params.ref.val_calc                    
                    case 'mean'
                        ref_level = nanmean(cleanWC,[1 2]);                       
                    case 'median'
                        ref_level = nanmedian(cleanWC,[1 2]);
                    case 'mode'
                        ref_level = mode(cleanWC,[1 2]);
                   case 'perc5'
                        ref_level = prctile(cleanWC,5,[1 2]);
                    case 'perc10'
                        ref_level = prctile(cleanWC,10,[1 2]);
                    case 'perc25'
                        ref_level = prctile(cleanWC,25,[1 2]);
                end
                
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

