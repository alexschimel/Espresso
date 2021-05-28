function out_struct = CFF_read_EMdgmCHE(fid)
% #CHE - Struct of compatibility heave sensor datagram.
%
% Used for backward compatibility with .all datagram format. Sent before
% #MWC (water column datagram) datagram if compatibility mode is enabled.
% The multibeam datagram body is common with the #MWC datagram.

out_struct.header = CFF_read_EMdgmHeader(fid);

if out_struct.header.dgmVersion == 0
    % definition for CHE_VERSION 0
    
    out_struct.cmnPart = CFF_read_EMdgmMbody(fid);
    out_struct.data    = CFF_read_EMdgmCHEdata(fid);
    
end

end


function out_struct = CFF_read_EMdgmCHEdata(fid)
% #CHE - Heave compatibility data part. Heave reference point is at
% transducer instead of at vessel reference point.

% Heave. Unit meter. Positive downwards.
out_struct.heave_m = fread(fid,1,'float');

end