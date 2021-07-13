function out_struct = CFF_read_EMdgmIIP(fid, dgmVersion_warning_flag)
% Definition of #IIP datagram containing installation parameters and sensor
% format settings.
% Details in separate document Installation parameters
%
% Verified correct for kmall versions H,I

out_struct.header = CFF_read_EMdgmHeader(fid);

if out_struct.header.dgmVersion>0 && dgmVersion_warning_flag
    % definition valid only for IIP_VERSION 0 (kmall versions H,I)
    warning('#IIP datagram version (%i) unsupported. Continue reading but there may be issues.',out_struct.header.dgmVersion);
end

% Size in bytes of body part struct. Used for denoting size of rest of
% the datagram.
out_struct.numBytesCmnPart = fread(fid,1,'uint16');

% Information. For future use.
out_struct.info = fread(fid,1,'uint16');

% Status. For future use.
out_struct.status = fread(fid,1,'uint16');

% Installation settings as text format. Parameters separated by ; and
% lines separated by , delimiter.
% For detailed description of text strings, see the separate document
% Installation parameters
out_struct.install_txt = fscanf(fid, '%c',out_struct.numBytesCmnPart-6);

end