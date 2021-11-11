function [SBP_sampleAcrossDistance,SBP_sampleUpwardsDistance] = CFF_get_samples_dist(SBP_sampleRange,BP_beamPointingAngle)
%CFF_GET_SAMPLES_DIST  Samples' coordinates in the swath frame
%
%   Compute samples' coordinates in the swath frame (Distances across and
%   upwards from sonar) from the samples' range and beam pointing angle.
%   Calculate sample(s) cartesian coordinates in the swath frame:
%   - origin: sonar face
%   - Xs: across distance (positive ~starboard) = -range*sin(pointingAngle)
%   - Ys: along distance (positive ~forward) = 0
%   - Zs: up distance (positive up) = -range*cos(pointingAngle)
%
%   *INPUT VARIABLES*
%
%   * |SBP_sampleRange|: Required. A SBP matrix (or SB for 1 ping, or 1BP for a
%   common sample across all beams and pings, etc.) of each sample's range
%   (in m) from the sonar
%   * |beamPointingAngle|: Required. A BP matrix (or B1 for 1 ping) of beam
%   pointing angle in each ping/beam
%
%   *OUTPUT VARIABLES*
%
%   * |sampleAcrossDistance|: A SBP matrix (or SB for 1 ping) of each
%   sample's distance across (in m) from the sonar.
%   * |sampleUpwardsDistance|: A SBP matrix (or SB for 1 ping) of each
%   sample's distance upwards (in m) from the sonar.
%
%   See also CFF_GET_SAMPLES_RANGE.

%   Authors: Alex Schimel (NIWA, alexandre.schimel@niwa.co.nz) and Yoann
%   Ladroit (NIWA, yoann.ladroit@niwa.co.nz)
%   2017-2021; Last revision: 11-11-2021

% permute dimensions of input to get everything as SBP matrices
SBP_beamPointingAngle = permute(BP_beamPointingAngle,[3,1,2]);

% compute outputs
SBP_sampleAcrossDistance  = -SBP_sampleRange.*sin(SBP_beamPointingAngle);
SBP_sampleUpwardsDistance = -SBP_sampleRange.*cos(SBP_beamPointingAngle);

end