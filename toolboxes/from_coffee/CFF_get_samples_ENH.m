% Compute samples' coordinates in the geographical frame (Easting, Northing,
% Height) from their coordinates in the swath frame (Distances across and
% upwards). This requires the geographical coordinates of the swath frame
% origin (sonar), and the orientation of the swath frame in the
% geographical frame (vessel's heading).
%
% * |sonarEasting| is 1P matrix (or 1 scalar for 1 ping) of the sonar's Easting coordinate in the geographical frame
% * |sonarNorthing| is 1P matrix (or 1 scalar for 1 ping) of the sonar's Northing coordinate in the geographical frame
% * |sonarHeight| is 1P matrix (or 1 scalar for 1 ping) of the sonar's Height coordinate in the geographical frame
% * |heading| is 1P matrix (or 1 scalar for 1 ping) of the swathe's heading
% * |sampleAcrossDist| is a SBP matrix (or SB for 1 ping) of each sample's distance across (in m) from the sonar
% * |sampleUpDist| is a SBP matrix (or SB for 1 ping) of each sample's distance upwards (in m) from the sonar
%
% * |sampleEasting| is a SBP matrix (or SB for 1 ping) of each sample's Easting coordinate in the geographical frame
% * |sampleNorthing| is a SBP matrix (or SB for 1 ping) of each sample's Northing coordinate in the geographical frame
% * |sampleHeight| is a SBP matrix (or SB for 1 ping) of each sample's Height coordinate in the geographical frame


%% Function 
function [sampleEasting, sampleNorthing, sampleHeight] = CFF_get_samples_ENH(sonarEasting,sonarNorthing,sonarHeight,heading,sampleAcrossDist,sampleUpDist)

% permute dimensions of input to get everything as SBP matrices
sonarEasting  = permute(sonarEasting,[3,1,2]); 
sonarNorthing = permute(sonarNorthing,[3,1,2]); 
sonarHeight   = permute(sonarHeight,[3,1,2]);
heading       = permute(heading,[3,1,2]);

% compute outputs
sampleEasting  = bsxfun(@plus,sonarEasting,bsxfun(@times,sampleAcrossDist,cos(heading)));
sampleNorthing = bsxfun(@plus,sonarNorthing,bsxfun(@times,sampleAcrossDist,sin(heading)));
sampleHeight   = bsxfun(@plus,sonarHeight,sampleUpDist);

end
