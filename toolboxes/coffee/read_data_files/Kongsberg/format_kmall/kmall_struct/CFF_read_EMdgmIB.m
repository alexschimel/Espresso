function out_struct = CFF_read_EMdgmIB(fid)
% #IB - Results from online built in test (BIST). Definition used for three
% different BIST datagrams, i.e. #IBE (BIST Error report), #IBR (BIST
% reply) or #IBS (BIST short reply).

out_struct.header = CFF_read_EMdgmHeader(fid);

if out_struct.header.dgmVersion == 0
    % definition for BIST_VERSION 0
    
    % Size in bytes of body part struct. Used for denoting size of rest of
    % the datagram.
    out_struct.numBytesCmnPart = fread(fid,1,'uint16');
    
    % 0 = last subset of the message
    % 1 = more messages to come 
    out_struct.BISTInfo = fread(fid,1,'uint16');
    
    % 0 = plain text
    % 1 = use style sheet 
    out_struct.BISTStyle = fread(fid,1,'uint8');
    
    % The BIST number executed. 
    out_struct.BISTNumber = fread(fid,1,'uint8');
    
    % 0 = BIST executed with no errors
    % positive number = warning
    % negative number = error 
    out_struct.BISTStatus = fread(fid,1,'int8');
    
    % Result of the BIST. Starts with a synopsis of the result, followed by
    % detailed descriptions.
    out_struct.BISTText = fscanf(fid, '%c',out_struct.numBytesCmnPart-6);
    
end

end