function out_struct = CFF_read_EMdgmSdataInfo(fid)
% Information of repeated sensor data in one datagram.
%
% Info about data from sensor. Part included if data from sensor appears
% multiple times in a datagram.
%
% Verified correct for kmall versions H,I

% Size in bytes of current struct. 
out_struct.numBytesInfoPart = fread(fid,1,'uint16');

% Number of sensor samples added in datagram. 
out_struct.numSamplesArray = fread(fid,1,'uint16');

% Length in bytes of one whole sample (decoded and raw data). 
out_struct.numBytesPerSample = fread(fid,1,'uint16');

% Length in bytes of raw sensor data. 
out_struct.numBytesRawSensorData = fread(fid,1,'uint16');

end