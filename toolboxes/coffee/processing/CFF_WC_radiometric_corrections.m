function [fData] = CFF_WC_radiometric_corrections(fData)
%CFF_WC_RADIOMETRIC_CORRECTIONS  One-line description
%
%   Apply physical (aka, not aestethic ones) corrections to the dB level in
%   water-column data: TVG, dB offset, etc.
%
%   *INPUT VARIABLES*
%   * |fData|: Required. Structure for the storage of kongsberg EM series
%   multibeam data in a format more convenient for processing. The data is
%   recorded as fields coded "a_b_c" where "a" is a code indicating data
%   origing, "b" is a code indicating data dimensions, and "c" is the data
%   name. See the help of function CFF_convert_ALLdata_to_fData.m for
%   description of codes.
%
%   *OUTPUT VARIABLES*
%   * |fData|: fData structure updated with "X_SBP_WaterColumnProcessed"
%   now radiometrically corrected
%
%   *DEVELOPMENT NOTES*
%   Just started this function to integrate the "transmit power re maximum"
%   dB offset that is stored in Runtime Parameters (marine mammal
%   protection modes I think). But ideally develop this function for future
%   compensations of TVG, pulse length, etc.
%
%   See also ESPRESSO.

%   Authors: Alex Schimel (NIWA, alexandre.schimel@niwa.co.nz) and Yoann
%   Ladroit (NIWA, yoann.ladroit@niwa.co.nz)
%   2017-2021; Last revision: 24-09-2019

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
    data = CFF_WC_radiometric_corrections_CORE(data,fData);
    
    % convert modified data back to raw format and store
    data = data./wcdata_Factor;
    data(isnan(data)) = wcdata_Nanval;
    fData.X_SBP_WaterColumnProcessed.Data.val(:,:,blockPings) = cast(data,wcdata_Class);
    
end

