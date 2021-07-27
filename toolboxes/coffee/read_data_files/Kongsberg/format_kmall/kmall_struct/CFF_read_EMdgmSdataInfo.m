function out_struct = CFF_read_EMdgmSdataInfo(fid)
%CFF_READ_EMDGMSDATAINFO  Read Data section of S datagram in kmall file
%
%   Information of repeated sensor data in one datagram.
%
%   Info about data from sensor. Part included if data from sensor appears
%   multiple times in a datagram.
%
%   Verified correct for kmall versions H,I
%
%   See also CFF_READ_KMALL_FROM_FILEINFO, ESPRESSO.

%   Authors: Alex Schimel (NIWA, alexandre.schimel@niwa.co.nz) and Yoann
%   Ladroit (NIWA, yoann.ladroit@niwa.co.nz)
%   2017-2021; Last revision: 27-07-2021

% Size in bytes of current struct.
out_struct.numBytesInfoPart = fread(fid,1,'uint16');

% Number of sensor samples added in datagram.
out_struct.numSamplesArray = fread(fid,1,'uint16');

% Length in bytes of one whole sample (decoded and raw data).
out_struct.numBytesPerSample = fread(fid,1,'uint16');

% Length in bytes of raw sensor data.
out_struct.numBytesRawSensorData = fread(fid,1,'uint16');

end