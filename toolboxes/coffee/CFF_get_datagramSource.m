function datagramSource = CFF_get_datagramSource(fData,varargin)

datagramSource=[];
if ~isempty(varargin)&&~isempty(varargin{1})
    datagramSource=varargin{1};
    % datagramSource was not specified, check fData for it
elseif isfield(fData,'MET_datagramSource')
    datagramSource = fData.MET_datagramSource;
end

if ~isfield(fData,sprintf('%s_1P_Date',datagramSource))
    datagramSource=[];
end

if isempty(datagramSource)
    if isfield(fData, 'WC_1P_Date')
        datagramSource = 'WC';
        fprintf(['...datagramSource not specified for ping processing. Using ''' datagramSource '''...\n']);
    elseif isfield(fData, 'AP_1P_Date')
        datagramSource = 'AP';
        fprintf(['...datagramSource not specified for ping processing. Using ''' datagramSource '''...\n']);
    elseif isfield(fData, 'De_1P_Date')
        datagramSource = 'De';
        fprintf(['...datagramSource not specified for ping processing. Using ''' datagramSource '''...\n']);
    elseif isfield(fData, 'X8_1P_Date')
        datagramSource = 'X8';
        fprintf(['...datagramSource not specified for ping processing. Using ''' datagramSource '''...\n']);
    else
        error('can''t find a suitable datagramSource')
    end
end


