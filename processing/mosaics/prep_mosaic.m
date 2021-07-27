function [mosaic, fData_tot] = prep_mosaic(mosaic,fData_tot)
%PREP_MOSAIC  One-line description
%
%   See also ESPRESSO.

%   Authors: Yoann Ladroit (NIWA, yoann.ladroit@niwa.co.nz) and Alex
%   Schimel (NIWA, alexandre.schimel@niwa.co.nz)
%   2017-2021; Last revision: 27-07-2021

% mosaic boundaries
E_lim = mosaic.E_lim;
N_lim = mosaic.N_lim;

for iF = 1:numel(fData_tot)
    
    fData = fData_tot{iF};
    
    if ~isfield(fData,'X_1E_gridEasting')
        mosaic.Fdata_ID(iF) = 0;
        continue;
    end
    
    E = fData.X_1E_gridEasting;
    N = fData.X_N1_gridNorthing;
    
    % check if overlap between data grid boundaries and mosaic boundaries
    idx_keep_E = E>E_lim(1) & E<E_lim(2);
    idx_keep_N = N>N_lim(1) & N<N_lim(2);
    
    if ~any(idx_keep_E) || ~any(idx_keep_N)
        % no overlap
        mosaic.Fdata_ID(iF) = 0;
        continue;
    end
    
    % if still here, there is some overlap. But that overlap might not
    % actually contain data, so check for this too
    
    % grab data and format if necessary
    L = fData.X_NEH_gridLevel;
    
    if isa(L,'gpuArray')
        L = gather(L);
    end
    if size(L,3)>1
        L = nanmean(L,3);
    end
    
    % remove the data falling outside the mosaic
    L(~idx_keep_N,:) = [];
    L(:,~idx_keep_E) = [];
    
    % check if data remaining is all NaN
    if all(isnan(L(:)))
        % no data within requested mosaic bounds for that fData
        mosaic.Fdata_ID(iF) = 0;
        continue;
    end
    
    % if still here, this file can contribute to the mosaic
    mosaic.Fdata_ID(iF) = fData.ID;
    
    % is this file's resolution worst than what we have so far
    mosaic.res = nanmax(fData.X_1_gridHorizontalResolution,mosaic.res);
    
end

% remove from fData_tot those that are not necessary anymore
fData_tot(mosaic.Fdata_ID==0) = [];

% remove the blank IDs
mosaic.Fdata_ID(mosaic.Fdata_ID==0) = [];

% if any overlapping file has been found and coarsest resolution found,
% initialize the mosaic 
if mosaic.res>0
    numElemMosaicE = ceil((E_lim(2)-E_lim(1))./mosaic.res)+1;
    numElemMosaicN = ceil((N_lim(2)-N_lim(1))./mosaic.res)+1;
    mosaic.mosaic_level = zeros(numElemMosaicN,numElemMosaicE,'single');
else
    mosaic.mosaic_level = single([]);
end

mosaic.best_res = mosaic.res;



