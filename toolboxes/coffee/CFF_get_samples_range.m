function sampleRange = CFF_get_samples_range(idxSamples,startSampleNumber,interSamplesDistance)
%CFF_GET_SAMPLES_RANGE  Range (in m) of samples from indices
%
%   Compute range (in m) from sonar of samples, based on the sample number
%   and the distance between two samples (in m). For water column data, the
%   sample number must be corrected by a fixed offset
%   (startRangeSampleNumber).
%
%   CFF_GET_SAMPLES_RANGE(I,S,D) returns the range of samples of index I,
%   considering the start offset S, and the inter-sample distance D.
%
%   See also CFF_INTER_SAMPLE_DISTANCE

%   Authors: Alex Schimel (NIWA, alexandre.schimel@niwa.co.nz) and Yoann
%   Ladroit (NIWA, yoann.ladroit@niwa.co.nz)
%   2017-2021; Last revision: 21-07-2021

% permute dimensions of input to get everything as SBP matrices
startSampleNumber    = permute(startSampleNumber,[3,1,2]);
interSamplesDistance = permute(interSamplesDistance,[3,1,2]);

% compute outputs
sampleRange = (idxSamples+startSampleNumber).*interSamplesDistance;

end





