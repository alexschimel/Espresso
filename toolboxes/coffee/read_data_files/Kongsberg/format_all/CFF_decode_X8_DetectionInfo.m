function [S2, cat] = CFF_decode_X8_DetectionInfo(data)


dat = reshape(data,[],1);

% init output
S = nan(size(dat));

cat = categorical({...
    'valid, amplitude detection',... % 0
    'valid, phase detection',... % 1
    'invalid, normal detection',... % 2
    'invalid, interpolated or extrapolated from neighbour detections',... % 3
    'invalid, estimated',... % 4
    'invalid, rejected candidate',... % 5
    'invalid, no detection data available '... % 6
    });


dat = dec2bin(dat, 8);

bit7 = str2num(dat(:,1));
bits0to3 = bin2dec(dat(:,5:end));


S(~bit7 & bits0to3==0) = 0;
S(~bit7 & bits0to3==1) = 1;
S(bit7 & bits0to3==0) = 2;
S(bit7 & bits0to3==1) = 3;
S(bit7 & bits0to3==2) = 4;
S(bit7 & bits0to3==3) = 5;
S(bit7 & bits0to3==4) = 6;

S2 = reshape(S,size(data));

