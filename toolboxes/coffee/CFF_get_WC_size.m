function [nSamples, nBeams, nPings] = CFF_get_WC_size(fData)

switch CFF_get_datagramSource(fData)
    case {'WC' 'AP'}
        fieldN=sprintf('%s_SBP_SampleAmplitudes',CFF_get_datagramSource(fData));
        
        [nSamples, nBeams, nPings]=cellfun(@(x) size(x.Data.val),fData.(fieldN));
    case 'X8'
        nSamples=1;
        [nBeams, nPings]=size(fData.X8_BP_ReflectivityBS);
end


nSamples=nanmax(nSamples);
nBeams=nanmax(nBeams);
nPings=nansum(nPings);