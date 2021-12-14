function fDataGroup = CFF_grid_lines(fDataGroup,varargin)
%CFF_GRID_LINES  Create Easting-Northing grids of data in a group of fData
%
%   Description
%
%   See also XXX

%   Authors: Alex Schimel (NGU, alexandre.schimel@ngu.no) and Yoann
%   Ladroit (NIWA, yoann.ladroit@ensta-bretagne.fr)
%   2021-2021; Last revision: 23-11-2021


%% Input arguments management
p = inputParser;

% input fData
addRequired(p,'fDataGroup',@(x) all(CFF_is_fData_version_current(x)));

% grid resolution in m
addParameter(p,'res',1,@mustBePositive);

% save fData to hard-drive? 0: no (default), 1: yes
addParameter(p,'saveFDataToDrive',0,@(x) mustBeMember(x,[0,1]));

% what if error during conversion? 0: to next file (default), 1: abort
addParameter(p,'abortOnError',0,@(x) mustBeMember(x,[0,1]));

% information communication (none by default)
addParameter(p,'comms',CFF_Comms());

% parse inputs
parse(p,fDataGroup,varargin{:});

% and get results
for ff = fields(p.Results)'
    eval(sprintf('%s = p.Results.%s;',ff{1},ff{1}));
end
clear p
if ischar(comms)
    comms = CFF_Comms(comms);
end


%% Prep

% start message
comms.start('Gridding data in line(s)');

% number of files
nLines = numel(fDataGroup);

% start progress
comms.progress(0,nLines);


%% Process files
for ii = 1:nLines
    
    % try-catch sequence to allow continuing to next file if one fails
    try
        
        % get fData for this line
        if iscell(fDataGroup)
            fData = fDataGroup{ii};
        else
            fData = fDataGroup;
        end
            
        % display for this line
        lineName = CFF_file_name(char(CFF_onerawfileonly(fData.ALLfilename)),1);
        comms.step(sprintf('%i/%i: line %s',ii,nLines,lineName));
        
        % data to grid: bathy and backscatter if available
        % DEV NOTE: The bathy above can be gridded because it comes with
        % matching easting and northing. However, there is no "X_BP_bottom"
        % backscatter field. The only seafloor backscatter available comes
        % from X8 datagrams. If this was the datagram source used, then the
        % dimensions of X8_BP_ReflectivityBS match
        % X_BP_bottomNorthing/Easting and so they can be used to grid that
        % backscatter. But if the datagram source used was WC or AP, then
        % that X8 backscatter might not have the same dimensions. If this
        % is the case, then we don't have a matching easting and northing
        % for backscatter and it cannot be gridded.
        flagGridBS = CFF_is_field_or_prop(fData,'X8_BP_ReflectivityBS') &&  all(size(fData.X8_BP_ReflectivityBS)==size(fData.X_BP_bottomEasting)); 
        if flagGridBS
            comms.info('Gridding bathymetry and backscatter');
            
            if CFF_is_field_or_prop(fData,'X_1_bathyInterpolant')
                bathyInterpolant = fData.X_1_bathyInterpolant;
            else
                bathyInterpolant = [];
            end
            if CFF_is_field_or_prop(fData,'X_1_bsInterpolant')
                bsInterpolant = fData.X_1_bsInterpolant;
            else
                bsInterpolant = [];
            end
            
            % grid bathy and BS
            [gridV, gridE, gridN, interpolant] = CFF_grid_2D_data(fData.X_BP_bottomEasting,...
                fData.X_BP_bottomNorthing,...
                {fData.X_BP_bottomHeight, fData.X8_BP_ReflectivityBS},...
                res,...
                {bathyInterpolant,bsInterpolant});
           
            % calculate slope
            comms.info('Calculating slope');
            [gridSlopeX,gridSlopeY] = gradient(gridV{1});
            gridSlope = sqrt(gridSlopeX.^2 + gridSlopeY.^2);
            
            % save everything
            fData.X_NE_bathy = gridV{1};
            fData.X_NE_bs    = gridV{2};
            fData.X_NE_slope = gridSlope;
            fData.X_1E_2DgridEasting  = gridE(1,:);
            fData.X_N1_2DgridNorthing = gridN(:,1);
            fData.X_1_2DgridHorizontalResolution = res;
            fData.X_1_bathyInterpolant = interpolant{1};
            fData.X_1_bsInterpolant = interpolant{2};
            
        else
            comms.info('Gridding bathymetry');
            
            if CFF_is_field_or_prop(fData,'X_1_bathyInterpolant')
                bathyInterpolant = fData.X_1_bathyInterpolant;
            else
                bathyInterpolant = [];
            end
            
            % grid bathy
            [gridZ, gridE, gridN, bathyInterpolant] = CFF_grid_2D_data(fData.X_BP_bottomEasting,...
                fData.X_BP_bottomNorthing,...
                fData.X_BP_bottomHeight,...
                res,...
                bathyInterpolant);
            
            % dummy gridBS
            gridBS = zeros(size(gridZ),'single');
            gridBS(isnan(gridZ)) = NaN;
            
            % calculate slope
            comms.info('Calculating slope');
            [gridSlopeX,gridSlopeY] = gradient(gridZ);
            gridSlope = sqrt(gridSlopeX.^2 + gridSlopeY.^2);
            
            % save everything
            fData.X_NE_bathy = gridZ;
            fData.X_NE_bs    = gridBS;
            fData.X_NE_slope = gridSlope;
            fData.X_1E_2DgridEasting  = gridE(1,:);
            fData.X_N1_2DgridNorthing = gridN(:,1);
            fData.X_1_2DgridHorizontalResolution = res;
            fData.X_1_bathyInterpolant = bathyInterpolant;
            
        end
        
        % gridding pingcounter as BP to display ping data as grids
        comms.info('Gridding indices for Runtime Parameters');
        x = fData.X_BP_bottomEasting;
        x = x(:);
        y = fData.X_BP_bottomNorthing;
        y = y(:);
        iX = floor((x-gridE(1))/res)+1;
        iY = floor((y-gridN(1))/res)+1;
        subs = single([iY iX]);
        sz = single([numel(gridN) numel(gridE)]);
        nB = size(fData.X8_B1_BeamNumber,1);
        val = reshape(ones(nB,1)*fData.X8_1P_PingCounter,[],1);
        NE_gridPingCounter = accumarray(subs,val,sz,@(x) nanmin(x),NaN);
        
        %indexing in Ru_1D
        % do column per column
        X_NE_indexInRu_1D = nan(size(NE_gridPingCounter));
        nC = size(X_NE_indexInRu_1D,2);
        for iC = 1:nC
            A = NE_gridPingCounter(:,iC) - fData.Ru_1D_PingCounter;
            A(A<0) = max(A(:));
            [M,I] = min(A,[],2);
            I(isnan(M)) = NaN;
            X_NE_indexInRu_1D(:,iC) = I;
        end
        fData.X_NE_indexInRu_1D = X_NE_indexInRu_1D;
        % old way creates a 3D matrix that can be too big
%         A = NE_gridPingCounter - permute(fData.Ru_1D_PingCounter,[3,1,2]);
%         A(A<0) = max(A(:));
%         [M,I] = min(A,[],3);
%         I(isnan(M)) = NaN;
%         fData.X_NE_indexInRu_1D = I;

        % save fData to drive
        if saveFDataToDrive
            % get output folder and create it if necessary
            rawFile = fData.ALLfilename;
            wc_dir = CFF_converted_data_folder(rawFile);
            if ~isfolder(wc_dir)
                mkdir(wc_dir);
            end
            mat_fdata_file = fullfile(wc_dir, 'fData.mat');
            comms.info('Saving');
            save(mat_fdata_file,'-struct','fData','-v7.3');
        end
        
        % save fData back into group
        if iscell(fDataGroup)
            fDataGroup{ii} = fData;
        else
            fDataGroup = fData;
        end
        
        % successful end of this iteration
        comms.info('Done');
        
    catch err
        if abortOnError
            % just rethrow error to terminate execution
            rethrow(err);
        else
            % log the error and continue
            errorFile = CFF_file_name(err.stack(1).file,1);
            errorLine = err.stack(1).line;
            errrorFullMsg = sprintf('%s (error in %s, line %i)',err.message,errorFile,errorLine);
            comms.error(errrorFullMsg);
        end
    end
    
    % communicate progress
    comms.progress(ii,nLines);
    
end

% output fDataGroup as single struct if that was the input
if isstruct(fDataGroup)
    fDataGroup = fDataGroup{1};
end


%% end message
comms.finish('Done');

end