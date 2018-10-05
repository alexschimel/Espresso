% Compute samples coordinates in the swath frame (Distances across and
% upwards from sonar) from the samples range and beam pointing angle
%
% * |sampleRange| is a SBP matrix (or SB for 1 ping) of each sample's range (in m) from the sonar
% * |beam_point_angle| is a BP matrix (or B1 for 1 ping) of beam pointing angle in each ping/beam
%
% * |sampleAcrossDist| is a SBP matrix (or SB for 1 ping) of each sample's distance across (in m) from the sonar
% * |sampleUpDist| is a SBP matrix (or SB for 1 ping) of each sample's distance upwards (in m) from the sonar

function [sampleAcrossDist,sampleUpDist] = CFF_get_samples_dist(sampleRange,beam_point_angle)

% permute dimensions of input to get everything as SBP matrices
beam_point_angle = permute(beam_point_angle,[3,1,2]);

% compute outputs
sampleAcrossDist = bsxfun(@times,-sampleRange,sin(beam_point_angle));
sampleUpDist     = bsxfun(@times,-sampleRange,cos(beam_point_angle));

end