% Compute samples range (in m) from sonar, based on the sample number, the
% origin offset, and the distance between two samples
% 
% * |idx_samples| is a S1 vector of samples indices
% * |start_sample_range| is a BP matrix (or B1 for 1 ping) of the number of the first sample in each ping/beam
% * |dr| is 1P matrix (or 1 scalar for 1 ping) of the distance between two samples in each beam
%
% * |sampleRange| is a SBP matrix (or SB for 1 ping) of each sample's range (in m) from the sonar

%% Function
function sampleRange = CFF_get_samples_range(idx_samples,start_sample_range,dr)

% permute dimensions of input to get everything as SBP matrices
start_sample_range = permute(start_sample_range,[3,1,2]);
dr                 = permute(dr,[3,1,2]); 

% compute outputs
sampleRange = bsxfun(@times,bsxfun(@plus,idx_samples,start_sample_range),dr);

end





