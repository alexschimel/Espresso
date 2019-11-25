function [nSamples, nBeams, nPings] = CFF_get_WC_size(fData)

fieldN=sprintf('%s_SBP_SampleAmplitudes',CFF_get_datagramSource(fData));

[nSamples, nBeams, nPings]=cellfun(@(x) size(x.Data.val),fData.(fieldN));

nSamples=nanmax(nSamples);
nBeams=nanmax(nBeams);
nPings=nansum(nPings);