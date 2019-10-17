function [flags,sample_size,mag_fmt,phase_fmt]=CFF_get_R7042_flags(flag_dec)

if isnumeric(flag_dec)
    flag_bin=dec2bin(flag_dec, 32);    
else   
    flag_bin = flag_dec;
end
sample_size=0;
mag_fmt='';
phase_fmt='';

flags.dataTruncatedBeyondBottom=0;
flags.magnitudeOnly=0;
flags.int8BitCompression=0;
flags.downsamplingDivisor=0;
flags.downsamplingType=0;
flags.int32BitsData=0;
flags.compressionFactorAvailable=0;
flags.segmentNumbersAvailable=0;

% Bit 0 : Use maximum bottom detection point in each beam to
% limit data. Data is included up to the bottom detection point
% + 10%. This flag has no effect on systems which do not
% perform bottom detection.
flags.dataTruncatedBeyondBottom = bin2dec(flag_bin(32-0));

% Bit 1 : Include magnitude data only (strip phase)
flags.magnitudeOnly = bin2dec(flag_bin(32-1));

% Bit 2 : Convert mag to dB, then compress from 16 bit to 8 bit
% by truncation of 8 lower bits. Phase compression simply
% truncates lower (least significant) byte of phase data.
flags.int8BitCompression = bin2dec(flag_bin(32-2));

% Bit 3 : Reserved.

% Bit 4-7 : Downsampling divisor. Value = (BITS >> 4). Only
% values 2-16 are valid. This field is ignored if downsampling
% is not enabled (type = “none”).
flags.downsamplingDivisor = bin2dec(flag_bin(32-7:32-4));

% Bit 8-11 : Downsampling type:
%             0x000 = None
%             0x100 = Middle value
%             0x200 = Peak value
%             0x300 = Average value
flags.downsamplingType = bin2dec(flag_bin(32-11:32-8));

% Bit 12: 32 Bits data
flags.int32BitsData = bin2dec(flag_bin(32-12));

% Bit 13: Compression factor available
flags.compressionFactorAvailable = bin2dec(flag_bin(32-13));

% Bit 14: Segment numbers available
flags.segmentNumbersAvailable = bin2dec(flag_bin(32-14));


 % figure the size of a "sample" in bytes based on those flags
            if flags.magnitudeOnly
                if flags.int32BitsData && ~flags.int8BitCompression
                    % F) 32 bit Mag (32 bits total, no phase)
                    sample_size = 4;
                    mag_fmt='float32';
                elseif ~flags.int32BitsData && flags.int8BitCompression
                    % D) 8 bit Mag (8 bits total, no phase)
                    sample_size = 1;
                    mag_fmt='int8';
                elseif ~flags.int32BitsData && ~flags.int8BitCompression
                    % B) 16 bit Mag (16 bits total, no phase)
                    sample_size = 2;
                    mag_fmt='int16';
                else
                    % if both flags.int32BitsData and flags.int8BitCompression are
                    % =1, then I am not quite sure how it would work given
                    % how I understand the file format documentation.
                    % Throw error if you ever get this case and look for
                    % more information about data format...
                    warning('%s: WC compression flag issue',fieldname);
                end
                phase_fmt='';
            else
                if ~flags.int32BitsData && flags.int8BitCompression
                    % C) 8 bit Mag & 8 bit Phase (16 bits total)
                    sample_size = 2;
                    phase_fmt='int8';
                    mag_fmt='int8';
                elseif ~flags.int32BitsData && ~flags.int8BitCompression
                    % A) 16 bit Mag & 16bit Phase (32 bits total)
                    sample_size = 4;
                    phase_fmt='int16';
                    mag_fmt='int16';                  
                else
                    % Again, if both flags.int32BitsData and
                    % flags.int8BitCompression are = 1, I don't know what the
                    % result would be.
                    
                    % There is another weird case: if flags.int32BitsData=1 and
                    % flags.int8BitCompression=0, I would assume it would 32
                    % bit Mab & 32 bit Phase (64 bits total), but that case
                    % does not exist in the documentation. Instead you have
                    % a case E) 32 bit Mag & 8 bit Phase (40 bits total),
                    % which I don't understand could happen. Also, that
                    % would screw the code as we read the data in bytes,
                    % aka multiples of 8 bits. We would need to modify the
                    % code to work per bit if we ever had such a case.
                    
                    % Anyway, throw error if you ever get here and look for
                    % more information about data format...

                end
            end
