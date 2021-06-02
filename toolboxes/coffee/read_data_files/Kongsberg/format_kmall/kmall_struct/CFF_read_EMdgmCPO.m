function out_struct = CFF_read_EMdgmCPO(fid)
% #CPO - Struct of compatibility position sensor datagram.
% 
% Data from active sensor will be motion corrected if indicated by
% operator. Motion correction is applied to latitude, longitude, speed,
% course and ellipsoidal height. If the sensor is inactive, the fields will
% be marked as unavailable, defined by the parameters define
% UNAVAILABLE_LATITUDE etc.     

out_struct.header = CFF_read_EMdgmHeader(fid);

if out_struct.header.dgmVersion == 0
    % definition for CPO_VERSION 0
    
    out_struct.cmnPart    = CFF_read_EMdgmScommon(fid);
    
    % number of bytes in the actual CPO data is the total datagram size
    % (need to remove 4 bytes for the final numBytes field) minus what was
    % read in the header (20 bytes, as currently defined), the common part
    % (8 bytes, as currently defined), and the data block until the actual
    % data (40 bytes, as currently defined)  
    CPO_data_numBytes = (out_struct.header.numBytesDgm - 4) ...
        - 20 ...
        - out_struct.cmnPart.numBytesCmnPart ...
        - 40;
    
    out_struct.sensorData = CFF_read_EMdgmCPOdataBlock(fid, CPO_data_numBytes);
    
end

end


function out_struct = CFF_read_EMdgmCPOdataBlock(fid, CPO_data_numBytes)
% #CPO - Compatibility sensor position compatibility data block. Data from
% active sensor is referenced to position at antenna footprint at water
% level. Data is corrected for motion ( roll and pitch only) if enabled by
% K-Controller operator. Data given both decoded and corrected (active
% sensors), and raw as received from sensor in text string.

% UTC time from position sensor. Unit seconds. Epoch 1970-01-01. Nanosec
% part to be added for more exact time.
out_struct.timeFromSensor_sec = fread(fid,1,'uint32');

% UTC time from position sensor. Unit nano seconds remainder. 
out_struct.timeFromSensor_nanosec = fread(fid,1,'uint32');

% Only if available as input from sensor. Calculation according to format.
out_struct.posFixQuality_m = fread(fid,1,'float');

% Motion corrected (if enabled in K-Controller) data as used in depth
% calculations. Referred to antenna footprint at water level. Unit decimal
% degree. Parameter is set to define UNAVAILABLE_LATITUDE if sensor
% inactive.
out_struct.correctedLat_deg = fread(fid,1,'double');

% Motion corrected (if enabled in K-Controller) data as used in depth
% calculations. Referred to antenna footprint at water level. Unit decimal
% degree. Parameter is set to define UNAVAILABLE_LONGITUDE if sensor
% inactive.
out_struct.correctedLong_deg = fread(fid,1,'double');

% Speed over ground. Unit m/s. Motion corrected (if enabled in
% K-Controller) data as used in depth calculations. If unavailable or from
% inactive sensor, value set to define UNAVAILABLE_SPEED.
out_struct.speedOverGround_mPerSec = fread(fid,1,'float');

% Course over ground. Unit degree. Motion corrected (if enabled in
% K-Controller) data as used in depth calculations. If unavailable or from
% inactive sensor, value set to define UNAVAILABLE_COURSE.
out_struct.courseOverGround_deg = fread(fid,1,'float');

% Height of antenna footprint above the ellipsoid. Unit meter. Motion
% corrected (if enabled in K-Controller) data as used in depth
% calculations. If unavailable or from inactive sensor, value set to define
% UNAVAILABLE_ELLIPSOIDHEIGHT.
out_struct.ellipsoidHeightReRefPoint_m = fread(fid,1,'float');

% Position data as received from sensor, i.e. uncorrected for motion etc.
out_struct.posDataFromSensor = fscanf(fid, '%c', CPO_data_numBytes); 

end