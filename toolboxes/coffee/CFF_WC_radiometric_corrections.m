%% CFF_WC_radiometric_corrections.m
%
% Apply physical (aka, not aestethic ones) corrections to the dB level in
% water-column data: TVG, dB offset, etc.
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
%
% *OUTPUT VARIABLES*
%
% * |fData|: fData structure updated with "X_SBP_WaterColumnProcessed" now
% radiometrically corrected
%
% *DEVELOPMENT NOTES*
%
% Just started this function to integrate the "transmit power re maximum"
% dB offset that is stored in Runtime Parameters (marine mammal protection
% modes I think). But ideally develop this function for future
% compensations of TVG, pulse length, etc.
%
% *NEW FEATURES*
%
% * 2019-09-24: First version.
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
function [fData] = CFF_WC_radiometric_corrections(fData)

% extract info about WCD
wcdata_class  = fData.X_1_WaterColumnProcessed_Class; % int8 or int16
wcdata_factor = fData.X_1_WaterColumnProcessed_Factor;
wcdata_nanval = fData.X_1_WaterColumnProcessed_Nanval;

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
    data = CFF_WC_radiometric_corrections_CORE(data,fData);
    
    % convert modified data back to raw format and store
    data = data./wcdata_factor;
    data(isnan(data)) = wcdata_nanval;
    fData.X_SBP_WaterColumnProcessed.Data.val(:,:,blockPings) = cast(data,wcdata_class);
    
end


