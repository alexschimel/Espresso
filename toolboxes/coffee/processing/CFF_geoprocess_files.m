function fDataGroup = CFF_geoprocess_files(rawFilesList,varargin)
%CFF_GEOPROCESS_FILES  Process location of ping and bottom data
%
%   Computes the location of the sonar head for each ping in one or several
%   converted files, as well as the location of each bottom detect. The new
%   computations are added as new fields to fdata, starting with X_ (X_1P_
%   for ping), and (X_BP_bottom_ for bottom detect).
%
%   See also CFF_CONVERT_RAW_FILES

%   Authors: Alex Schimel (NGU, alexandre.schimel@ngu.no) and Yoann
%   Ladroit (NIWA, yoann.ladroit@ensta-bretagne.fr)
%   2021; Last revision: 03-11-2021


%% Input arguments management
p = inputParser;

% list of files (or pairs of files) to convert
argName = 'rawFilesList';
argCheck = @(x) ~isempty(x) && (ischar(x) || iscell(x));
addRequired(p,argName,argCheck);

% code string for the datagram type to use as a source for the date, time,
% and counter of pings ('WC', 'AP', 'X8', etc.). Or leave empty '' to
% define automatically from datagrams available in the first file
% (default). The value is then used for all other files.
addParameter(p,'datagramSource','',@(x) ischar(x));

% code string for the coordinates' ellipsoid used for projection. See
% possible codes in CFF_LL2TM: e.g. 'wgs84', 'grs80', etc. Or leave empty
% '' to define it automatically from the first file ('wgs84', default). The
% value is then used for all other files.
addParameter(p,'ellips','',@(x) ischar(x));

% code string for the Transverse Mercator projection See possible codes in
% CFF_LL2TM: e.g. 'utm54s', 'nztm2000', etc. Or leave empty '' to define it
% automatically from the navigation in the first ping of the first file
% (default). The value is then used for all other files.
addParameter(p,'tmproj','',@(x) ischar(x));

% save fData to hard-drive? 0: no (default), 1: yes
addParameter(p,'saveFDataToDrive',0,@(x) mustBeMember(x,[0,1]));

% output fData? 0: no, 1: yes (default)
addParameter(p,'outputFData',1,@(x) mustBeMember(x,[0,1]));

% what if error during conversion? 0: to next file (default), 1: abort
addParameter(p,'abortOnError',0,@(x) mustBeMember(x,[0,1]));

% information communication (none by default)
addParameter(p,'comms',CFF_Comms());

% parse inputs
parse(p,rawFilesList,varargin{:});

% and get results
rawFilesList = p.Results.rawFilesList;
datagramSource = p.Results.datagramSource;
ellips = p.Results.ellips;
tmproj = p.Results.tmproj;
saveFDataToDrive = p.Results.saveFDataToDrive;
outputFData = p.Results.outputFData;
abortOnError = p.Results.abortOnError;
if ischar(p.Results.comms)
    comms = CFF_Comms(p.Results.comms);
else
    comms = p.Results.comms;
end
clear p


%% Prep

% start message
comms.start('Geoprocessing file(s)');

% single filename in input
if ischar(rawFilesList)
    rawFilesList = {rawFilesList};
end

% number of files
nFiles = numel(rawFilesList);

% init output
if outputFData
    fDataGroup = cell(1,nFiles);
else
    fDataGroup = [];
end

% start progress
comms.progress(0,nFiles);


%% Process files
for iF = 1:nFiles
    
    % try-catch sequence to allow continuing to next file if one fails
    try
        
        % get the file (or pair of files) to process
        rawFile = rawFilesList{iF};
        
        % display for this file
        if ischar(rawFile)
            filename = CFF_file_name(rawFile,1);
            comms.step(sprintf('%i/%i: file %s',iF,nFiles,filename));
        else
            % paired files
            filename_1 = CFF_file_name(rawFile{1},1);
            filename_2_ext = CFF_file_extension(rawFile{2});
            comms.step(sprintf('%i/%i: pair of files %s and %s',iF,nFiles,filename_1,filename_2_ext));
        end
        
        % load converted data
        fDataFolder = CFF_converted_data_folder(rawFile);
        fData = load(fullfile(fDataFolder,'fData.mat'));
        
        % First step: computing the ping navigation, aka interpolating
        % navigation data from ancillary sensors to ping time. 
        % Testing if geoprocessing parameters are already defined
        if isempty(tmproj)
            % Parameters not defined yet.
            % Define them automatically from this file.
            
            % First, test if file has already been geoprocessed
            if ~isfield(fData,'MET_tmproj')
                % File has not been geoprocessed yet.
                
                % Compute ping navigation with default parameters, i.e.
                % datagramSource as specified in data (or default), wgs84
                % ellipsoid, and UTM projection fitting the lat/long of the
                % first ping
                comms.info('Interpolate navigation data from ancillary sensors to ping time');
                fData = CFF_compute_ping_navigation(fData);
                
                % save the geoprocessing parameters for next files
                datagramSource = CFF_get_datagramSource(fData);
                ellips = fData.MET_ellips;
                tmproj = fData.MET_tmproj;
                
                comms.info(sprintf('Projection defined automatically from file''s data - ellipsoid: %s, UTM zone: %s', ellips, tmproj));
                
            else
                % File has already been geoprocessed.
                
                % No need to compute navigation again
                comms.info('Navigation data have already been processed');
                
                % save the geoprocessing parameters for next files
                datagramSource = CFF_get_datagramSource(fData);
                ellips = fData.MET_ellips;
                tmproj = fData.MET_tmproj;
                
                comms.info(sprintf('Projection taken from this file - ellipsoid: %s, UTM zone: %s', ellips, tmproj));
                
            end
            
        else
            % Parameters already defined.
            % Note that this means we may force the use of a UTM projection
            % for navigation data that is outside that zone. It should
            % still work.
            
            % Test if file has already been geoprocessed
            if isfield(fData,'MET_tmproj')
                % File has already been geoprocessed.
                % Test if the parameters are the same.
                if strcmp(fData.MET_tmproj,tmproj)
                    % Same projection used.
                    % No need to compute navigation again
                    comms.info('Navigation data have already been processed');
                else
                    % Different projection.
                    % We need to recompute navigation with desired
                    % parameters.
                    
                    % But first, remove all data fields using the old
                    % projection. Throw a warning if we do that.
                    if isfield(fData,'X_NEH_gridLevel')
                        fData = rmfield(fData,{'X_1_gridHorizontalResolution','X_1E_gridEasting','X_N1_gridNorthing','X_NEH_gridDensity','X_NEH_gridLevel'});
                        comms.info('This file contains gridded data in a projection that is different than that of the project. These gridded data were removed')
                    end
                    comms.info('Interpolate navigation data from ancillary sensors to ping time');
                    fData = CFF_compute_ping_navigation(fData, ...
                        datagramSource, ...
                        ellips, ...
                        tmproj);
                end
            else
                % File has not been geoprocessed yet.
                % Compute ping navigation with desired parameters
                comms.info('Interpolate navigation data from ancillary sensors to ping time');
                fData = CFF_compute_ping_navigation(fData, ...
                    datagramSource, ...
                    ellips, ...
                    tmproj);
            end
            
        end
        
        %% Processing bottom detect
        comms.info('Geo-reference bottom detect');
        fData = CFF_georeference_WC_bottom_detect(fData);
        
        % save fData to drive
        if saveFDataToDrive
            % get output folder and create it if necessary
            wc_dir = CFF_converted_data_folder(rawFile);
            if ~isfolder(wc_dir)
                mkdir(wc_dir);
            end
            mat_fdata_file = fullfile(wc_dir, 'fData.mat');
            comms.info('Saving');
            save(mat_fdata_file,'-struct','fData','-v7.3');
        end
        
        % add to group for output
        if outputFData
            fDataGroup{iF} = fData;
        end
        clear fData
        
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
    comms.progress(iF,nFiles);
    
end

if outputFData
    % output struct directly if only one element
    if numel(fDataGroup)==1
        fDataGroup = fDataGroup{1};
    end
end

%% end message
comms.finish('Done');

end