function out_struct = CFF_read_EMdgmMWC(fid)
% #MWC - Multibeam Water Column Datagram. Entire datagram containing
% several sub structs.

out_struct.header = CFF_read_EMdgmHeader(fid);

if out_struct.header.dgmVersion == 1
    % definition for MWC_VERSION 1
    
    out_struct.partition = CFF_read_EMdgmMpartition(fid);
    out_struct.cmnPart   = CFF_read_EMdgmMbody(fid);
    out_struct.txInfo    = CFF_read_EMdgmMWCtxInfo(fid);
    
    Ntx = out_struct.txInfo.numTxSectors;
    for iTx = 1:Ntx
        out_struct.sectorData(iTx) = CFF_read_EMdgmMWCtxSectorData(fid);
    end
    
    out_struct.rxInfo = CFF_read_EMdgmMWCrxInfo(fid);
    
    Nrx = out_struct.rxInfo.numBeams;
    for iRx = 1:Nrx
        out_struct.beamData_p(iRx) = CFF_read_EMdgmMWCrxBeamData(fid);
    end
    
end

end


function out_struct = CFF_read_EMdgmMWCtxInfo(fid)
% #MWC - data block 1: transmit sectors, general info for all sectors 

% Number of bytes in current struct. 
out_struct.numBytesTxInfo = fread(fid,1,'uint16');

% Number of transmitting sectors (Ntx). Denotes the number of times the
% struct EMdgmMWCtxSectorData is repeated in the datagram.
out_struct.numTxSectors = fread(fid,1,'uint16');

% Number of bytes in EMdgmMWCtxSectorData. 
out_struct.numBytesPerTxSector = fread(fid,1,'uint16');

% Byte alignment. 
out_struct.padding = fread(fid,1,'int16');

% Heave at vessel reference point, at time of ping, i.e. at midpoint of
% first tx pulse in rxfan.
out_struct.heave_m = fread(fid,1,'float');

end


function out_struct = CFF_read_EMdgmMWCtxSectorData(fid)
% #MWC - data block 1: transmit sector data, loop for all i = numTxSectors. 

% Along ship steering angle of the TX beam (main lobe of transmitted
% pulse), angle referred to transducer face. Angle as used by beamformer
% (includes stabilisation). Unit degree.   
out_struct.tiltAngleReTx_deg = fread(fid,1,'float');

% Centre frequency of current sector. Unit hertz. 
out_struct.centreFreq_Hz = fread(fid,1,'float');

% Corrected for frequency, sound velocity and tilt angle. Unit degree. 
out_struct.txBeamWidthAlong_deg = fread(fid,1,'float');

% Transmitting sector number. 
out_struct.txSectorNum = fread(fid,1,'uint16');

% Byte alignment.
out_struct.padding = fread(fid,1,'int16');

end


function out_struct = CFF_read_EMdgmMWCrxInfo(fid)
% #MWC - data block 2: receiver, general info 

% Number of bytes in current struct. 
out_struct.numBytesRxInfo = fread(fid,1,'uint16');

% Number of beams in this datagram (Nrx).
out_struct.numBeams = fread(fid,1,'uint16');

% Bytes in EMdgmMWCrxBeamData struct, excluding sample amplitudes (which have varying lengths) 
out_struct.numBytesPerBeamEntry = fread(fid,1,'uint8');

% 0 = off
% 1 = low resolution
% 2 = high resolution
out_struct.phaseFlag = fread(fid,1,'uint8');

% Time Varying Gain function applied (X). X log R + 2 Alpha R + OFS + C,
% where X and C is documented in #MWC datagram. OFS is gain offset to
% compensate for TX source level, receiver sensitivity etc.   
out_struct.TVGfunctionApplied = fread(fid,1,'uint8');

% Time Varying Gain offset used (OFS), unit dB. X log R + 2 Alpha R + OFS +
% C, where X and C is documented in #MWC datagram. OFS is gain offset to
% compensate for TX source level, receiver sensitivity etc.
out_struct.TVGoffset_dB = fread(fid,1,'int8');

% The sample rate is normally decimated to be approximately the same as the
% bandwidth of the transmitted pulse. Unit hertz.  
out_struct.sampleFreq_Hz = fread(fid,1,'float');

% Sound speed at transducer, unit m/s. 
out_struct.soundVelocity_mPerSec = fread(fid,1,'float');

end


function out_struct = CFF_read_EMdgmMWCrxBeamData(fid)
% #MWC - data block 2: receiver, specific info for each beam. 

out_struct.beamPointAngReVertical_deg = fread(fid,1,'float');

out_struct.startRangeSampleNum = fread(fid,1,'uint16');

% Two way range in samples. Approximation to calculated distance from tx to
% bottom detection [meters] = soundVelocity_mPerSec *
% detectedRangeInSamples / (sampleFreq_Hz * 2). The detected range is set
% to zero when the beam has no bottom detection. Replaced by
% detectedRangeInSamplesHighResolution for higher precision.
out_struct.detectedRangeInSamples = fread(fid,1,'uint16');

out_struct.beamTxSectorNum = fread(fid,1,'uint16');

% Number of sample data for current beam. Also denoted Ns. 
out_struct.numSampleData = fread(fid,1,'uint16');

% The same information as in detectedRangeInSamples with higher resolution.
% Two way range in samples. Approximation to calculated distance from tx to
% bottom detection [meters] = soundVelocity_mPerSec *
% detectedRangeInSamples / (sampleFreq_Hz * 2). The detected range is set
% to zero when the beam has no bottom detection.
out_struct.detectedRangeInSamplesHighResolution = fread(fid,1,'float');


% in progress from here...


% Pointer to start of array with Water Column data. Lenght of array =
% numSampleData. Sample amplitudes in 0.5 dB resolution. Size of array is
% numSampleData * int8_t. Amplitude array is followed by phase information
% if phaseFlag >0. Use (numSampleData * int8_t) to jump to next beam, or to
% start of phase info for this beam, if phase flag > 0.
out_struct.sampleAmplitude05dB_p = fread(fid,1,'int8');

end