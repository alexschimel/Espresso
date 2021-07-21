function sampleRange = CFF_get_samples_range(idxSamples,startSampleNumber,interSamplesDistance)
%CFF_GET_SAMPLES_RANGE  Range (in m) of samples from indices
%
%   Compute samples range (in m) from sonar, based on the sample number,
%   the origin offset, and the distance between two samples. For water
%   column, you need to take into account the startRangeSampleNumber to
%   compute range as range =
%   interSamplesDistance*(idxSamples+startRangeSampleNumber). For the
%   sample corresponding to bottom detect, there should not be an offset. 
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





