function out_struct = CFF_read_EMdgmIOP(fid, dgmVersion_warning_flag)
% Definition of #IOP datagram containing runtime parameters, exactly as
% chosen by operator in the K-Controller/SIS menus.
% For detailed description of text strings, see the separate document
% Runtime parameters set by operator.
%
% Verified correct for kmall versions H,I

out_struct.header = CFF_read_EMdgmHeader(fid);

if out_struct.header.dgmVersion>0 && dgmVersion_warning_flag
    % definition valid for IOP_VERSION 0 (kmall versions H,I)
    warning('#IOP datagram version (%i) unsupported. Continue reading but there may be issues.',out_struct.header.dgmVersion);
end

% Size in bytes of body part struct. Used for denoting size of rest of
% the datagram.
out_struct.numBytesCmnPart = fread(fid,1,'uint16');

% Information. For future use.
out_struct.info = fread(fid,1,'uint16');

% Status. For future use.
out_struct.status = fread(fid,1,'uint16');

% Runtime paramters as text format. Parameters separated by ; and lines
% separated by , delimiter. Text strings refer to names in menues of
% the K-Controller/SIS.
% For detailed description of text strings, see the separate document
% Runtime parameters set by operator
out_struct.runtime_txt = fscanf(fid, '%c',out_struct.numBytesCmnPart-6);

end