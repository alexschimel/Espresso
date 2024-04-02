function fDataGroup = gridbathyBS(fDataGroup, idx_fData, procpar)
%GRIDBATHYBS  Grid bottom height field, and backscatter if possible
%
%   Grid in projected coordinates (Easting, Northing) the
%   X_BP_bottomHeight field, which is obtained after applying
%   CFF_GEOREFERENCE_WC_BOTTOM_DETECT. If the datagram source was X8, then
%   the backscatter is also available with the same dimensions and can also
%   be gridded. However, if the datagram source was WC or AP, then the
%   bottom height comes from the sample in WC corresponding to the 
%   bottom, and so the backscatter value from X8 might not have the same
%   size and thus cannot be gridded
%
%   See also ESPRESSO.

%   Copyright 2017-2021 Alexandre Schimel, Yoann Ladroit, NIWA
%   Licensed under MIT. Details on https://github.com/alexschimel/Espresso/


%% Prep

% init communication object
comms = CFF_Comms('multilines');

% start message
comms.start('Gridding bathymetry and seafloor backscatter');

% number of files
nFiles = numel(idx_fData);

% start progress
comms.progress(0,nFiles);

% init iterator
u = 0;


%% Process per file
for ii = idx_fData(:)'
    
    % iterator update
    u = u+1;
    
    % file name
    rawFile = fDataGroup{ii}.ALLfilename;
    if numel(rawFile)==1
        rawFile = rawFile{1};
    end
    
    % display for this file
    if ischar(rawFile)
        filename = CFF_file_name(rawFile,1);
        comms.step(sprintf('%i/%i: file %s',ii,nFiles,filename));
    else
        % paired files
        filename_1 = CFF_file_name(rawFile{1},1);
        filename_2_ext = CFF_file_extension(rawFile{2});
        comms.step(sprintf('%i/%i: pair of files %s and %s',ii,nFiles,filename_1,filename_2_ext));
    end

    % grid bathy
    comms.info('Gridding bathymetry');
    [gridZ, gridE, gridN] = CFF_grid_2D_data(fDataGroup{ii}.X_BP_bottomEasting,...
        fDataGroup{ii}.X_BP_bottomNorthing,...
        fDataGroup{ii}.X_BP_bottomHeight,...
        procpar.gridbathyBS_res);
    
    % grid BS
    % DEV NOTE: The bathy above can be gridded because it comes with
    % matching easting and northing. However, there is no "X_BP_bottom"
    % backscatter field. The only seafloor backscatter available comes from
    % X8 datagrams. If this was the datagram source used, then the
    % dimensions of X8_BP_ReflectivityBS match X_BP_bottomNorthing/Easting
    % and so they can be used to grid that backscatter. But if the datagram
    % source used was WC or AP, then that X8 backscatter might not have the
    % same dimensions. If this is the case, then we don't have a matching
    % easting and northing for backscatter and it cannot be gridded.
    if isfield(fDataGroup{ii},'X8_BP_ReflectivityBS') && all(size(fDataGroup{ii}.X8_BP_ReflectivityBS)==size(fDataGroup{ii}.X_BP_bottomEasting))
        comms.info('Gridding seafloor backscatter');
        gridBS = CFF_grid_2D_data(fDataGroup{ii}.X_BP_bottomEasting,...
            fDataGroup{ii}.X_BP_bottomNorthing,...
            fDataGroup{ii}.X8_BP_ReflectivityBS,...
            procpar.gridbathyBS_res);
    else
        gridBS = zeros(size(gridE),'single');
        gridBS(isnan(gridZ)) = NaN;
    end
    
    % save
    fDataGroup{ii}.X_NE_bathy = gridZ;
    fDataGroup{ii}.X_NE_bs    = gridBS;
    fDataGroup{ii}.X_1E_2DgridEasting  = gridE(1,:);
    fDataGroup{ii}.X_N1_2DgridNorthing = gridN(:,1);
    fDataGroup{ii}.X_1_2DgridHorizontalResolution = procpar.gridbathyBS_res;
    
    % successful end of this iteration
    comms.info('Done');
    
    % communicate progress
    comms.progress(ii,nFiles);
    
end


%% end message
comms.finish('Done');
