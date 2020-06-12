function [nSamples, nBeams, nPings] = CFF_get_WC_size(fData,varargin)

if ~isempty(varargin)&&~isempty(varargin{1})
    dg_source=varargin{1};
else
    dg_source = CFF_get_datagramSource(fData);
end

switch dg_source
    case {'WC' 'AP'}
        fieldN=sprintf('%s_SBP_SampleAmplitudes',dg_source);        
        [nSamples, nBeams, nPings]=cellfun(@(x) size(x.Data.val),fData.(fieldN));
    case 'X8'
        nSamples=1;
        [nBeams, nPings]=size(fData.X8_BP_ReflectivityBS);
end


nSamples=nanmax(nSamples);
nBeams=nanmax(nBeams);
nPings=nansum(nPings);