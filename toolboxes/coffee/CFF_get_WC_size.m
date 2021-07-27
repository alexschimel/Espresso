function [nSamples, nBeams, nPings] = CFF_get_WC_size(fData,varargin)
%CFF_GET_WC_SIZE  One-line description
%
%   See also ESPRESSO.

%   Authors: Alex Schimel (NIWA, alexandre.schimel@niwa.co.nz) and Yoann
%   Ladroit (NIWA, yoann.ladroit@niwa.co.nz)
%   2017-2021; Last revision: 27-07-2021

% get source datagram
if ~isempty(varargin) && ~isempty(varargin{1})
    dg_source = varargin{1};
else
    dg_source = CFF_get_datagramSource(fData);
end

% get data size
switch dg_source
    case {'WC' 'AP'}
        fieldN = sprintf('%s_SBP_SampleAmplitudes',dg_source);        
        [nSamples, nBeams, nPings] = cellfun(@(x) size(x.Data.val),fData.(fieldN));
    case 'X8'
        nSamples = 1;
        [nBeams, nPings] = size(fData.X8_BP_ReflectivityBS);
end

nSamples = nanmax(nSamples);
nBeams = nanmax(nBeams);
nPings = nansum(nPings);