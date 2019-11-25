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
function [data, correction] = CFF_filter_WC_sidelobe_artifact_CORE(data, fData, blockPings)

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


%% calculate mean level across all beams for each range (and each ping)
meanAcrossBeams = mean(data,2,'omitnan');
%medianAcrossBeams = median(data,2,'omitnan');

%% define and calculate a reference level
% for reference level in each ping, we will use the average level of all
% samples in the water column of this ping, above the bottom, within the
% beams closest to nadir.

% find the 11 beams nearest to nadir

[~, nBeams, ~] = size(data);

nadirBeams = (floor((nBeams./2)-5):ceil((nBeams./2)+5));

% calculate the average bottom detect for those beams for each ping
bottom = fData.X_BP_bottomSample(nadirBeams,blockPings);


% calculate the average level in the WC above the average bottom detect,
% and within the nadir beams
refLevel = nan(1,1,numel(blockPings));
process='mode';

switch process
    case 'mode'
        nadirBottom = round(inpaint_nans(nanmin(bottom)));
        for iP = 1:numel(blockPings)
            nadir_data = data(1:nadirBottom(iP),:,iP);
            refLevel(1,1,iP) = mode(nadir_data(~isnan(nadir_data)));
        end
    case 'med'
        nadirBottom = round(inpaint_nans(nanmedian(bottom)));
        for iP = 1:numel(blockPings)
            nadir_data = data(1:nadirBottom(iP),nadirBeams,iP);
            refLevel(1,1,iP) = nanmedian(nadir_data(:));
        end
end

%% compensate data for mean level and introduce reference level
data = data - meanAcrossBeams + refLevel;

% save mean across beams for further use
correction = meanAcrossBeams;

%% MORE DVPT NOTES

% Usually a "normalization" implies also the standard deviation: you
% remove the mean, then divide by the standard deviation, and only then add
% a reference level). This is correction "b" in Parnum.
% You'd need to calculate the std as
%       stdAcrossBeams = std(data,0,2,'omitnan');
% and in the final calculation do instead:
%       data = (data-meanAcrossBeams)./stdAcrossBeams + refLevel;

% Continuing further from Parnum's idea, you could reintroduce a reference
% standard deviation, just as the reference level is actually a reference
% mean. So in order you substract the mean, divide by the std, multiply by
% the reference std, and add the reference level.
% The reference std would be calculated in the same loop as that for
% reference level as:
%       refStd(1,1,iP) = nanstd(nadir_data(:));
% and reintroduced in the final calculation as:
%       data = refStd.*(data-meanAcrossBeams)./stdAcrossBeams + refLevel;
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
% for ip = 1:numel(blockPings)
%     thisPing = data(:,:,ip);
%     sevenfiveperc = nan(nSamples,1); % calculate 75th percentile across all ranges
%     for ismp = 1:nSamples
%         X = thisPing(ismp,:,:);
%         sevenfiveperc(ismp,1) = CFF_invpercentile(X,75);
%     end
%     thisPing_corrected =  thisPing - sevenfiveperc;
% end

