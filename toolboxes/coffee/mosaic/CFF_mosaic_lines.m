function mosaic = CFF_mosaic_lines(fDataGroup,fieldname,varargin)
%CFF_MOSAIC_LINES  Mosaic a set of gridded lines
%
%   MOSAIC = CFF_MOSAIC_LINES(FDATAGROUP,FIELDNAME), where FDATAGROUP is a
%   cell array of fData structures and FIELDNAME is the (string) name of a
%   gridded data field common to these structures, creates a mosaic of that
%   data. MOSAIC is a mosaic structure whose fields include the two grids
%   'value' (containing the mosaicked value) and 'weight' (containing the
%   accumulated weight, see option 'mode' below), and other metadata.
%
%   MOSAICS = CFF_MOSAIC_LINES(FDATAGROUP,FIELDNAMES), where FIELDNAMES is
%   a cell array of strings representing the names of several gridded data
%   fields, creates a mosaic for each field, which are saved as the
%   elements of the cell array MOSAICS.
%
%   CFF_MOSAIC_LINES(...,'xy_roi',VALUE) specifies the x,y coordinates of
%   the ROI to be mosaicked and can be of two types: either a 4-elements
%   vector containing the desired min and max limits in x and y of a box
%   [x_min x_max y_min y_max], OR a Nx2 array (with N>=3) where each row is
%   the x,y coordinates of a vertex of a polygon inside which the mosaic is
%   to be calculated.
%
%   CFF_MOSAIC_LINES(...,'res',VALUE) with VALUE a positive scalar
%   specifies the desired mosaic grid size (resolution) (use the same unit
%   as 'xy_roi', i.e. usually, meters). With VALUE empty (default), the
%   grid size will be selected as the coarsest grid size of the data
%   gridded in FDATAGROUP. Note that while you can set here a finer
%   resolution than that of the gridded data, the end-resolut will not be
%   more detailed than the componenent grids. To get a better resolution,
%   you would need to re-grid the files at a finer resolution.
%
%   CFF_MOSAIC_LINES(...,'mode',VALUE) specifies the mosaicking mode, i.e.
%   the rules of how new data gets merged with existing data when adding to
%   the mosaic. Options are 'blend' (default) or 'stitch'. With 'blend',
%   the new and existing data get (possibly weighted) averaged. Actual
%   weights can be used to privilege some data, but by default, the weight
%   of a cell is the number of data points that contributed to a cell
%   value, so the iterative weighted averaging is equivalent to a normal
%   averaging. With 'stitch', we retain for each cell whichever data has
%   largest weight. Actual weights can be used to privilege some data, but
%   by default, the new data takes precedence over the old. See
%   CFF_ADD_TO_MOSAIC for detail on accumulating algorithms.
%
%   CFF_MOSAIC_LINES(...,'comms',VALUE) specifies the logging and display
%   method. See CFF_COMMS.
%
%   See also CFF_INIT_MOSAIC_V2, CFF_ADD_TO_MOSAIC, CFF_FINALIZE_MOSAIC
%   Authors: Alex Schimel (NGU, alexandre.schimel@ngu.no)
%   2017-2022; Last revision: 23-03-2022

% input parser
p = inputParser;
addRequired(p,'fDataGroup',@(x) all(CFF_is_fData_version_current(x)));
addRequired(p,'fieldname',@(x) ischar(x)||iscell(x));
addParameter(p,'xy_roi',@(u) validateattributes(u,{'numeric'},{'2d'}));
addParameter(p,'res',[],@(x) isempty(x) || x>0);
addParameter(p,'mode','blend',@(u) ismember(u,{'blend','stitch'}));
addParameter(p,'comms',CFF_Comms());
parse(p,fDataGroup,fieldname,varargin{:});
xy_roi = p.Results.xy_roi;
res = p.Results.res;
mode = p.Results.mode;
comms = p.Results.comms;
clear p;
if ischar(comms)
    comms = CFF_Comms(comms);
end

% start message
comms.start('Mosaicking data in line(s)');

% number of files
nLines = numel(fDataGroup);

% start progress
comms.progress(0,nLines);

% get coarsest resolution of component grids
if isempty(res)
    res = max(cellfun(@(x) x.X_1_2DgridHorizontalResolution, fDataGroup));
end

% if no ROI in input, do the entire dataset
if isempty(xy_roi)
    xy_roi = [NaN NaN NaN NaN];
    for iF = 1:numel(fDataGroup)
        xy_roi(1) = min( xy_roi(1), min(fDataGroup{iF}.X_1E_gridEasting) );
        xy_roi(2) = max( xy_roi(2), max(fDataGroup{iF}.X_1E_gridEasting) );
        xy_roi(3) = min( xy_roi(3), min(fDataGroup{iF}.X_N1_gridNorthing) );
        xy_roi(4) = max( xy_roi(4), max(fDataGroup{iF}.X_N1_gridNorthing) );
    end
end

% format fieldname
if ischar(fieldname)
    fieldname = {fieldname};
end
nFields = numel(fieldname);

% initialize mosaic(s)
for ii = 1:nFields
    mosaic{ii} = CFF_init_mosaic_v2(xy_roi,'res',res,'mode',mode);
end

% for backscatter and mosaicking modes involving averaging (i.e. 'blend')
% one needs to decide whether to average the dB values, or the equivalent
% amplitude or power values. The "mathematically" correct one is power, but
% is strongly affected by outliers. The best choice "aesthetically" is to
% use dB. We set here the transformation necessary before data is averaged,
% and the reverse transformation to get back in dB.
% For now we hard-code this, but perhaps eventually turn it as an input
% parameter
bs_averaging_mode = 'power';
switch bs_averaging_mode
    case 'dB'
        % no transformation as data is natively in dB.
        bs_trsfm = @(x) x;
        inv_trsfm = @(x) x;
    case 'amplitude'
        bs_trsfm = @(x) 10.^(x./20); % turn dB to amplitude
        inv_trsfm = @(x) 20.*log10(x); % inverse transformation
    case 'power'
        bs_trsfm = @(x) 10.^(x./10); % turn dB to power
        inv_trsfm = @(x) 10.*log10(x); % inverse transformation
end

% loop through fData
for ii = 1:nLines
    
    % get fData for this line
    if iscell(fDataGroup)
        fData = fDataGroup{ii};
    else
        fData = fDataGroup;
    end
    
    % display for this line
    lineName = CFF_file_name(char(CFF_onerawfileonly(fData.ALLfilename)),1);
    comms.step(sprintf('%i/%i: line %s',ii,nLines,lineName));
    
    % get x,y data
    x = fData.X_1E_2DgridEasting;
    y = fData.X_N1_2DgridNorthing;
    
    % add data to mosaic(s)
    for jj = 1:nFields
        % get data to mosaic
        v = fData.(fieldname{jj});
        % set weight
        switch mosaic{jj}.mode
            case 'blend'
                w = 1;
                % important not: 'blend' mode averages data
                if strcmp(fieldname{jj},'X_NE_bs')
                    % transform dB before averaging. Mosaic will remain in
                    % transformed unit until finalization.
                    v = bs_trsfm(v);
                end
            case 'stitch'
                w = 1./fData.X_NEH_gridMaxHorizDist;
        end
        % add to mosaic
        mosaic{jj} = CFF_add_to_mosaic(mosaic{jj},x,y,v,w);
    end
    
    % successful end of this iteration
    comms.info('Done');
    
    % communicate progress
    comms.progress(ii,nLines);
    
end

% replace zeros with nans
for ii = 1:nFields
    mosaic{ii} = CFF_finalize_mosaic(mosaic{ii});
    if strcmp(fieldname{ii},'X_NE_bs') && strcmp(mosaic{ii}.mode,'blend')
        mosaic{ii}.value = inv_trsfm(mosaic{ii}.value);
    end 
end

% end message
comms.finish('Done');

end