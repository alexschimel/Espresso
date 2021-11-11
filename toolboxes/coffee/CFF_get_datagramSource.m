function datagramSource = CFF_get_datagramSource(fData,varargin)
%CFF_GET_DATAGRAMSOURCE  Get the code of the source datagram
%
%   See also ESPRESSO.

%   Authors: Alex Schimel (NIWA, alexandre.schimel@niwa.co.nz) and Yoann
%   Ladroit (NIWA, yoann.ladroit@niwa.co.nz)
%   2017-2021; Last revision: 11-11-2021

% init output
datagramSource = [];

if ~isempty(varargin) && ~isempty(varargin{1})
    datagramSource = varargin{1};
    % datagramSource was not specified, check fData for it
elseif isfield(fData,'MET_datagramSource')
    datagramSource = fData.MET_datagramSource;
end

if ~isfield(fData,sprintf('%s_1P_Date',datagramSource))
    datagramSource = [];
end

if isempty(datagramSource)
    if isfield(fData, 'AP_1P_Date')
        datagramSource = 'AP';
    elseif isfield(fData, 'WC_1P_Date')
        datagramSource = 'WC';
    elseif isfield(fData, 'X8_1P_Date')
        datagramSource = 'X8';
    elseif isfield(fData, 'De_1P_Date')
        datagramSource = 'De';
    else
        error('can''t find a suitable datagramSource')
    end
end