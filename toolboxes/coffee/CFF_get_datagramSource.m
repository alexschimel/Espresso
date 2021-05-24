function datagramSource = CFF_get_datagramSource(fData,varargin)

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
    elseif isfield(fData, 'De_1P_Date')
        datagramSource = 'De';
    elseif isfield(fData, 'X8_1P_Date')
        datagramSource = 'X8';
    else
        error('can''t find a suitable datagramSource')
    end
end


