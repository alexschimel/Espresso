function out_struct = CFF_read_EMdgmMRZ(fid)
% #MRZ - Multibeam Raw Range and Depth datagram. The datagram also contains
% seabed image data.
%
% Datagram consists of several structs. The MRZ datagram replaces several
% old datagrams: raw range (N 78), depth (XYZ 88), seabed image (Y 89)
% datagram, quality factor (O 79) and runtime (R 52).
%
% Depths points (x,y,z) are calculated in meters, georeferred to the
% position of the vessel reference point at the time of the first
% transmitted pulse of the ping. The depth point coordinates x and y are in
% the surface coordinate system (SCS), and are also given as delta latitude
% and delta longitude, referred to origo of the VCS/SCS, at the time of the
% midpoint of the first transmitted pulse of the ping (equals time used in
% the datagram header timestamp).
% See Coordinate systems for introduction to spatial reference points and
% coordinate systems. Reference points are also described in Reference
% points and offsets. Explanation of the xyz reference points is also
% illustrated in the figure below.

out_struct.header = CFF_read_EMdgmHeader(fid);

if out_struct.header.dgmVersion == 2
    % definition for MRZ_VERSION 2
    
    out_struct.partition = CFF_read_EMdgmMpartition(fid);
    out_struct.cmnPart   = CFF_read_EMdgmMbody(fid);
    out_struct.pingInfo  = CFF_read_EMdgmMRZ_pingInfo(fid);
    
    % in progress from here...
    
    out_struct.sectorInfo = CFF_read_EMdgmMRZ_txSectorInfo(fid);
    out_struct.rxInfo     = CFF_read_EMdgmMRZ_rxInfo(fid);
    out_struct.extraDetClassInfo = CFF_read_EMdgmMRZ_extraDetClassInfo(fid);
    out_struct.sounding          = CFF_read_EMdgmMRZ_sounding(fid);
    out_struct.SIsample_desidB   = fread(fid,1,'int16');
    
    
end

end

function out_struct = CFF_read_EMdgmMRZ_pingInfo(fid)
% #MRZ - ping info. Information on vessel/system level, i.e. information
% common to all beams in the current ping.

% Number of bytes in current struct. 
out_struct.numBytesInfoData = fread(fid,1,'uint16');

% Byte alignment. 
out_struct.padding0 = fread(fid,1,'uint16');

% Ping rate. Filtered/averaged. 
out_struct.pingRate_Hz = fread(fid,1,'float');

% 0 = Eqidistance
% 1 = Equiangle
% 2 = High density 
out_struct.beamSpacing = fread(fid,1,'uint8');

% Depth mode. Describes setting of depth in K-Controller. Depth mode
% influences the PUs choice of pulse length and pulse type. If operator has
% manually chosen the depth mode to use, this is flagged by adding 100 to
% the mode index.
%
% Number 	Auto setting 	Number 	Manual setting
% 0         Very shallow 	100 	Very shallow
% 1         Shallow         101 	Shallow
% 2         Medium          102 	Medium
% 3         Deep            103 	Deep
% 4         Deeper          104 	Deeper
% 5         Very deep       105 	Very deep
% 6         Extra deep      106 	Extra deep
% 7         Extreme deep 	107 	Extreme deep 
out_struct.depthMode = fread(fid,1,'uint8');

% XXX
out_struct.subDepthMode = fread(fid,1,'uint8');

% XXX
out_struct.distanceBtwSwath = fread(fid,1,'uint8');

% XXX
out_struct.detectionMode = fread(fid,1,'uint8');

% XXX
out_struct.pulseForm = fread(fid,1,'uint8');

% XXX
out_struct.padding1 = fread(fid,1,'uint16');

% XXX
out_struct.frequencyMode_Hz = fread(fid,1,'float');

% XXX
out_struct.freqRangeLowLim_Hz = fread(fid,1,'float');

% XXX
out_struct.freqRangeHighLim_Hz = fread(fid,1,'float');

% XXX
out_struct.maxTotalTxPulseLength_sec = fread(fid,1,'float');

% XXX
out_struct.maxEffTxPulseLength_sec = fread(fid,1,'float');

% XXX
out_struct.maxEffTxBandWidth_Hz = fread(fid,1,'float');

% XXX
out_struct.absCoeff_dBPerkm = fread(fid,1,'float');

% XXX
out_struct.portSectorEdge_deg = fread(fid,1,'float');

% XXX
out_struct.starbSectorEdge_deg = fread(fid,1,'float');

% XXX
out_struct.portMeanCov_deg = fread(fid,1,'float');

% XXX
out_struct.starbMeanCov_deg = fread(fid,1,'float');

% XXX
out_struct.portMeanCov_m = fread(fid,1,'int16');

% XXX
out_struct.starbMeanCov_m = fread(fid,1,'int16');

% XXX
out_struct.modeAndStabilisation = fread(fid,1,'uint8');

% XXX
out_struct.runtimeFilter1 = fread(fid,1,'uint8');

% XXX
out_struct.runtimeFilter2 = fread(fid,1,'uint16');

% XXX
out_struct.pipeTrackingStatus = fread(fid,1,'uint32');

% XXX
out_struct.transmitArraySizeUsed_deg = fread(fid,1,'float');

% XXX
out_struct.receiveArraySizeUsed_deg = fread(fid,1,'float');

% XXX
out_struct.transmitPower_dB = fread(fid,1,'float');

% XXX
out_struct.SLrampUpTimeRemaining = fread(fid,1,'uint16');

% XXX
out_struct.padding2 = fread(fid,1,'uint16');

% XXX
out_struct.yawAngle_deg = fread(fid,1,'float');

% XXX
out_struct.numTxSectors = fread(fid,1,'uint16');

% XXX
out_struct.numBytesPerTxSector = fread(fid,1,'uint16');

% XXX
out_struct.headingVessel_deg = fread(fid,1,'float');

% XXX
out_struct.soundSpeedAtTxDepth_mPerSec = fread(fid,1,'float');

% XXX
out_struct.txTransducerDepth_m = fread(fid,1,'float');

% XXX
out_struct.z_waterLevelReRefPoint_m = fread(fid,1,'float');

% XXX
out_struct.x_kmallToall_m = fread(fid,1,'float');

% XXX
out_struct.y_kmallToall_m = fread(fid,1,'float');

% XXX
out_struct.latLongInfo = fread(fid,1,'uint8');

% XXX
out_struct.posSensorStatus = fread(fid,1,'uint8');

% XXX
out_struct.attitudeSensorStatus = fread(fid,1,'uint8');

% XXX
out_struct.padding3 = fread(fid,1,'uint8');

% XXX
out_struct.latitude_deg = fread(fid,1,'double');

% XXX
out_struct.longitude_deg = fread(fid,1,'double');

% XXX
out_struct.ellipsoidHeightReRefPoint_m = fread(fid,1,'float');

% XXX
out_struct.bsCorrectionOffset_dB = fread(fid,1,'float');

% XXX
out_struct.lambertsLawApplied = fread(fid,1,'uint8');

% XXX
out_struct.iceWindow = fread(fid,1,'uint8');

% XXX
out_struct.activeModes = fread(fid,1,'uint16');

end

function out_struct = CFF_read_EMdgmMRZ_txSectorInfo(fid)
end

function out_struct = CFF_read_EMdgmMRZ_rxInfo(fid)
end

function out_struct = CFF_read_EMdgmMRZ_extraDetClassInfo(fid)
end

function out_struct = CFF_read_EMdgmMRZ_sounding(fid)
end