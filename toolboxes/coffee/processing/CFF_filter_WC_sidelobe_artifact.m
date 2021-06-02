%% CFF_filter_WC_sidelobe_artifact.m
%
% Filter the water column specular/sidelobe artifact
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
% * |fData|: Required. Structure for the storage of kongsberg EM series
% multibeam data in a format more convenient for processing. The data is
% recorded as fields coded "a_b_c" where "a" is a code indicating data
% origing, "b" is a code indicating data dimensions, and "c" is the data
% name. See the help of function CFF_convert_ALLdata_to_fData.m for
% description of codes.
% * |method_spec|: Optional/Parameters. Method for removal of specular
% reflection. Default: 2
%
% *OUTPUT VARIABLES*
%
% * |fData|: fData structure updated with "X_SBP_WaterColumnProcessed" now
% filtered.
%
% *DEVELOPMENT NOTES*
%
% * IMPORTANT: only method 2 has been updated. All other methods don't
% work. to update XXX.
% * dataset have three dimensions: ping #, beam # and sample #. Calculating
% the average backcatter level across samples, would allow
% us to spot the beams that have constantly higher or lower energy in a
% given ping. Doing this only for samples in the watercolumn would allow us
% to normalize the energy in the watercolumn of a ping. Calculating the
% average backcatter across all beams would allow
% us to spot the samples that have constantly higher or lower energy in a
% given ping.
% * the circular artifact on the bottom is due to specular reflection
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
% *NEW FEATURES*
%
% * 2018-10-11: Updated header before adding to Coffee v3
% * 2018-10-09: in this new version, the filtering is using
% fData.X_SBP_WaterColumnProcessed as source data, whatever it is. By
% running this function just after CFF_initialize_WC_processing that copy
% the original data into fData.X_SBP_WaterColumnProcessed, one can filter
% the original data. If you mask after initialization, the filtering will
% be applied to that masked original data, etc.
% * 2016-10-10: v2 for new datasets recorded as SBP instead of PBS
% * 2016-11-07: First version. Code taken from CFF_filter_watercolumn.m
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
% Alexandre Schimel, Waikato University, Deakin University, NIWA.
% Yoann Ladroit, NIWA.

%% Function
function [fData] = CFF_filter_WC_sidelobe_artifact(fData)

% extract info about WCD
wcdata_Class  = fData.X_1_WaterColumnProcessed_Class; % int8 or int16
wcdata_Factor = fData.X_1_WaterColumnProcessed_Factor;
wcdata_Nanval = fData.X_1_WaterColumnProcessed_Nanval;
[nSamples, nBeams, nPings] = CFF_get_WC_size(fData);

% block processing setup
mem = CFF_memory_available;
blockLength = ceil(mem/(nSamples*nBeams*8)/20);
nBlocks = ceil(nPings./blockLength);
blocks = [ 1+(0:nBlocks-1)'.*blockLength , (1:nBlocks)'.*blockLength ];
blocks(end,2) = nPings;

% block processing
for iB = 1:nBlocks
    
    % list of pings in this block
    blockPings  = (blocks(iB,1):blocks(iB,2));
    
    % grab data in dB
    data = CFF_get_WC_data(fData,'X_SBP_WaterColumnProcessed','iPing',blockPings,'output_format','true');
    
    % core processing
    [data, correction] = CFF_filter_WC_sidelobe_artifact_CORE(data, fData, blockPings,[]);
    
    % convert result back to raw format and store
    data = data./wcdata_Factor;
    data(isnan(data)) = wcdata_Nanval;
    fData.X_SBP_WaterColumnProcessed.Data.val(:,:,blockPings) = cast(data,wcdata_Class);
    
end


