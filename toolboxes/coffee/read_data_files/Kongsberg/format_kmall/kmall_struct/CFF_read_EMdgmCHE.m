function out_struct = CFF_read_EMdgmCHE(fid, dgmVersion_warning_flag)
% #CHE - Struct of compatibility heave sensor datagram.
%
% Used for backward compatibility with .all datagram format. Sent before
% #MWC (water column datagram) datagram if compatibility mode is enabled.
% The multibeam datagram body is common with the #MWC datagram.
%
% Verified correct for kmall versions H,I

out_struct.header = CFF_read_EMdgmHeader(fid);

if out_struct.header.dgmVersion>0 && dgmVersion_warning_flag
    % definition valid for CHE_VERSION 0 (kmall versions H,I)
    warning('#CHE datagram version (%i) unsupported. Continue reading but there may be issues.',out_struct.header.dgmVersion);
end

out_struct.cmnPart = CFF_read_EMdgmMbody(fid);
out_struct.data    = CFF_read_EMdgmCHEdata(fid);

end


function out_struct = CFF_read_EMdgmCHEdata(fid)
% #CHE - Heave compatibility data part. Heave reference point is at
% transducer instead of at vessel reference point.
%
% Verified correct for kmall versions H,I

% Heave. Unit meter. Positive downwards.
out_struct.heave_m = fread(fid,1,'float');

end