function mosaic = init_mosaic(E_lim,N_lim,res,mode)
%INIT_MOSAIC  Initialize a new mosaic in Espresso
%
%   See also ESPRESSO.

%   Authors: Yoann Ladroit (NIWA, yoann.ladroit@niwa.co.nz) and Alex
%   Schimel (NIWA, alexandre.schimel@niwa.co.nz)
%   2017-2021; Last revision: 27-07-2021

% XXX3 clean this up with an input parser
mosaic.name     = 'New Mosaic';
mosaic.E_lim    = E_lim;
mosaic.N_lim    = N_lim;
mosaic.res      = res;

try
    mosaic.mode = mode; % 'blend' (default) or 'stitch'
catch
    mosaic.mode = 'blend';
end

mosaic.ID       = str2double(datestr(now,'yyyymmddHHMMSSFFF'));
mosaic.Fdata_ID = [];
mosaic.best_res = [];

if res > 0
    numElemMosaicE = ceil((E_lim(2)-E_lim(1))./res)+1;
    numElemMosaicN = ceil((N_lim(2)-N_lim(1))./res)+1;
    mosaic.mosaic_level = zeros(numElemMosaicN,numElemMosaicE,'single');
else
    mosaic.mosaic_level = single([]);
end


