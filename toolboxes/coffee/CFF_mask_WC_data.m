%% CFF_mask_WC_data.m
%
% Mask water-column data to remove unwanted samples
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
% * |remove_angle|: Optional. Steering angle beyond which outer beams are
% removed (in deg ref acoustic axis). Example: 55 -> angles>55 and <-55 are
% removed. Default: inf (all angles are conserved).
% * |remove_closerange|: Optional. Range from sonar (in m) within which
% samples are removed. Example: 4 -> all samples within 4m range from sonar
% are removed. Default: 0 (all samples are conserved).
% * |remove_bottomrange|: Optional. Range from bottom (in m) beyond which
% samples are removed. Range after bottom if positive, before bottom if
% negative. Example: 2 -> all samples 2m AFTER bottom detect and beyond are
% removed. Example: -3 -> all samples 3m BEFORE bottom detect and beyond
% are removed (therefore including bottom detect). Default: inf (all
% samples are conserved). 
% * |mypolygon|: Optional. Horizontal polygon (in Easting, Northing
% coordinates) outside of which samples are removed. Defualt: [] (all
% samples are conserved). 
%
% *OUTPUT VARIABLES*
%
% * |fData|: fData structure updated with "X_SBP_WaterColumnProcessed" now
% masked.
%
% *DEVELOPMENT NOTES*
%
% * check that masking uses filtered bottom if it exists, original bottom
% if not.
%
% *NEW FEATURES*
%
% * 2018-10-11: Updated header before adding to Coffee v3
% * 2017-10-10: new v2 functions because of dimensions swap (Alex Schimel)
% - 2016-12-01: Updating bottom range removal after change of bottom
% processing
% - 2016-11-07: First version. Code taken from CFF_filter_watercolumn.m
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
% Alexandre Schimel, Deakin University, NIWA. Yoann Ladroit, NIWA.

%% Function
function [fData] = CFF_mask_WC_data(fData,varargin)

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
blocks(end) = nPings;

% block processing
for iB = 1:nBlocks
    
    % list of pings in this block
    blockPings  = (blocks(iB,1):blocks(iB,2));
    
    % grab data in dB
    data = CFF_get_WC_data(fData,'X_SBP_WaterColumnProcessed','iPing',blockPings,'output_format','true');

    % core processing
    data = CFF_mask_WC_data_CORE(data, fData, blockPings, varargin{:});
        
    % convert modified data back to raw format and store
    data = data./wcdata_factor;
    data(isnan(data)) = wcdata_nanval;
    fData.X_SBP_WaterColumnProcessed.Data.val(:,:,blockPings) = cast(data,wcdata_class);

end



