function fDataGroup = CFF_convert_raw_files(rawFilesList,varargin)
%CFF_CONVERT_RAW_FILES Read raw data file(s) and convert to fData format
%
%   Reads contents of one or several multibeam raw data files and convert
%   each of them to the CoFFee fData format used for data processing on
%   Matlab. Data supported are Kongsberg EM series binary data file in
%   .all format (.all or .wcd, or pair of .all/.wcd) or .kmall format
%   (.kmall or .kmwcd, or pair of .kmall/.kmwcd) and Reson-Teledyne .s7k
%   format. converts every
%   datagram supported. 
%
%   fDataGroup = CFF_CONVERT_RAW_FILES(rawFile) converts single, non-paired
%   file rawFile specified with full path either as a character string (e.g.
%   rawFilesList='D:\Data\myfile.all') or a 1x1 cell containing the
%   character string (e.g. rawFilesList={'D:\Data\myfile.all'}).
%
%   fDataGroup = CFF_CONVERT_RAW_FILES(pairedRawFiles) converts pair of
%   files specified as a 1x1 cell containing a 2x1 cell where each cell
%   contain the full path as character string (e.g.
%   rawFilesList={{'D:\Data\myfile.all','D:\Data\myfile.wcd'}}). Note: If
%   you omit the double cell (i.e.
%   rawFilesList={'D:\Data\myfile.all','D:\Data\myfile.wcd'}), the two
%   files will be converted separately.
%
%   fDataGroup = CFF_CONVERT_RAW_FILES(rawFilesList) converts a cell vector
%   where each cell contains a file or pair of files to convert, specified
%   as above either a character string, or 2x1 cells of paired files (e.g.
%   rawFilesList =
%   {'D:\Data\mySingleFile.all',
%   {'D:\Data\myPairedFile.all','D:\Data\myPairedFile.wcd'}}). 
%   Note: Use CFF_LIST_RAW_FILES_IN_DIR to generate rawFilesList from a
%   folder containing raw data files.
%
%   By default, CFF_CONVERT_RAW_FILES converts every datagram supported. It
%   does not reconvert a file that has already been converted if it's found
%   on the disk (fData.mat) with the suitable version. In this case, the
%   data are simply loaded. If an error is encountered, the error message
%   is logged and processing moves onto the next file. Use the format
%   fDataGroup = CFF_CONVERT_RAW_FILES(...,Name,Parameter) to modify this
%   default behaviour. Options below:
%
%   'conversionType': 'Z&BS' will only convert datagrams necessary for
%   bathymetry and backscatter processing (e.g. for Ristretto).
%   Water-column datagrams are ignored in this mode. 
%   'conversionType': 'WCD' will only
%   convert datagrams necessary for water-column data processing (e.g. for
%   Espresso). Note: this includes datagrams for bathymetry and backscatter
%   processing. Use 'conversionType': 'everything' (default) to convert
%   every datagram supported.
%
%   'saveFDataToDrive': 1 will save the converted fData to the hard-drive.
%   Use 'saveFDataToDrive': 0 (default) to prevent this. Note that if
%   water-column datagrams are present and converted, then this parameter
%   is overriden and fData is saved to the hard-drive anyway. Converted
%   date are in the 'Coffee_files' folder created in the same folder as the
%   raw data files.
%
%   'forceReconvert': 1 will force the conversion of a raw data file, even
%   if a suitable converted file is found on the hard-drive. Use
%   'forceReconvert': 0 (default) for skipping conversion if possible.
%
%   'outputFData': 0 will clear fData after conversion of each file so that
%   the function returns empty. This avoids memory errors when converting
%   many files. Use this with 'saveFDataToDrive': 1 to save fData on the
%   hard-drive instead. Use 'outputFData': 1 (default) to conserve and
%   return fData.
%
%   'abortOnError': 1 will interrupt processing if an error is encountered.
%   Use 'abortOnError': 0 (default) for the function to log the error
%   message and move onto the next file.
%
%   'convertEvenIfDtgrmsMissing': 1 will continue conversion even if the
%   datagrams required by 'conversionType' are not all found in a file. Use
%   'convertEvenIfDtgrmsMissing': 0 (default) to stop conversion instead.
%
%   'dr_sub': N where N is an integer will decimate water-column data in
%   range by a factor of N. By default, 'dr_sub': 1 so that all data are
%   read and converted.
%
%   'db_sub': N where N is an integer will decimate water-column data in
%   beam by a factor of N. By default, 'db_sub': 1 so that all data are
%   read and converted.
%   
%   'comms': 'disp' will display text and progress information in the
%   command window.
%   'comms': 'textprogressbar': will display text and progress information
%   in a text progress bar in the command window.
%   'comms': 'waitbar': will display text and progress information
%   in a Matlab waitbar figure. 
%   'comms': '' (default) will not display any text and progress
%   information.
%
%   See also ESPRESSO, RISTRETTO, CFF_CONVERTED_DATA_FOLDER,
%   CFF_ARE_RAW_FILES_CONVERTED, CFF_READ_ALL, CFF_READ_S7K,
%   CFF_READ_KMALL, CFF_CONVERT_ALLDATA_TO_FDATA,
%   CFF_CONVERT_S7KDATA_TO_FDATA, CFF_CONVERT_KMALLDATA_TO_FDATA, CFF_COMMS

%   Authors: Alex Schimel (NGU, alexandre.schimel@ngu.no) and Yoann
%   Ladroit (NIWA, yoann.ladroit@ensta-bretagne.fr)
%   2021; Last revision: 19-08-2021


%% Input arguments management
p = inputParser;

% list of files (or pairs of files) to convert
argName = 'rawFilesList';
argCheck = @(x) ~isempty(x) && (ischar(x) || iscell(x));
addRequired(p,argName,argCheck);

% purpose of conversion: 'Z&BS' for bathy and BS processing ignoring
% water-column data (e.g. Ristretto) (default), 'WCD' for WCD processing
% (e.g. for Espresso, note: fData also includes bathy and BS in this case),
% 'everything' to force conversion of all supported datagrams in the raw
% data.
addParameter(p,'conversionType','everything',@(x) mustBeMember(x,{'everything','WCD','Z&BS'}));

% save fData to hard-drive? 0: no (default), 1: yes
% Note that if we convert for WCD processing, we will disregard that info
% and save fData to drive anyway
addParameter(p,'saveFDataToDrive',0,@(x) mustBeMember(x,[0,1]));

% what if file already converted? 0: to next file (default), 1: reconvert
addParameter(p,'forceReconvert',0,@(x) mustBeMember(x,[0,1]));

% output fData? 0: no, 1: yes (default)
% Unecessary in apps like Espresso, but useful in scripts
addParameter(p,'outputFData',1,@(x) mustBeMember(x,[0,1]));

% what if error during conversion? 0: to next file (default), 1: abort
addParameter(p,'abortOnError',0,@(x) mustBeMember(x,[0,1]));

% what if missing required dtgrms? 0: to next file (def), 1: convert anyway
addParameter(p,'convertEvenIfDtgrmsMissing',0,@(x) mustBeMember(x,[0,1]));

% decimation factor in range and beam (def 1, aka no decimation)
addParameter(p,'dr_sub',1,@(x) isnumeric(x)&&x>0&&mod(x,1)==0);
addParameter(p,'db_sub',1,@(x) isnumeric(x)&&x>0&&mod(x,1)==0);

% information communication (none by default)
addParameter(p,'comms',CFF_Comms());

% parse inputs
parse(p,rawFilesList,varargin{:});

% and get results
rawFilesList = p.Results.rawFilesList;
forceReconvert = p.Results.forceReconvert;
abortOnError = p.Results.abortOnError;
convertEvenIfDtgrmsMissing = p.Results.convertEvenIfDtgrmsMissing;
conversionType = p.Results.conversionType;
dr_sub = p.Results.dr_sub;
db_sub = p.Results.db_sub;
saveFDataToDrive = p.Results.saveFDataToDrive;
outputFData = p.Results.outputFData;
if ischar(p.Results.comms)
    comms = CFF_Comms(p.Results.comms);
else
    comms = p.Results.comms;
end
clear p


%% Prep

% start message
comms.start('Reading and converting file(s)');

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


%% Read and convert files
for iF = 1:nFiles
    
    % try-catch sequence to allow continuing to next file if one fails
    try
        
        % get the file (or pair of files) to convert
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
        
        % file format
        [~,~,f_ext] = fileparts(CFF_onerawfileonly(rawFile));
        if strcmpi(f_ext,'.all') || strcmpi(f_ext,'.wcd')
            file_format = 'Kongsberg_all';
        elseif strcmpi(f_ext,'.kmall') || strcmpi(f_ext,'.kmwcd')
            file_format = 'Kongsberg_kmall';
        elseif strcmpi(f_ext,'.s7k')
            file_format = 'Reson_s7k';
        else
            error('Cannot be converted. Format ("%s") not supported',f_ext);
        end
        
        % convert, reconvert, update, or ignore based on file status
        [idxConverted,idxFDataUpToDate,idxHasWCD] = CFF_are_raw_files_converted(rawFile);
        if ~idxConverted
            % File is not converted yet: proceed with conversion.
            comms.info('Never converted. Try to convert');
        else
            % File has already been converted...
            if forceReconvert
                % ...but asking for reconversion: proceed with
                % reconversion.
                comms.info('Already converted. Try to re-convert');
            else
                % ...and not asking for reconversion: examine its status a
                % bit more in detail.
                if ~idxFDataUpToDate || (strcmp(conversionType,'WCD') && ~idxHasWCD)
                    % Converted file is unsuitable, as it's using an
                    % outdated format OR it does not have the WCD data we
                    % need: update it aka reconvert.
                    comms.info('Already converted but unsuitable. Try to update conversion');
                else
                    % Converted file is suitable and doesn't need to be
                    % reconverted.
                    if outputFData
                        % we need in in output, so load it now
                        comms.info('Already converted and suitable. Try to load');
                        wc_dir = CFF_converted_data_folder(rawFile);
                        mat_fdata_file = fullfile(wc_dir, 'fData.mat');
                        fDataGroup{iF} = load(mat_fdata_file);
                        comms.info('Done');
                    else
                        % we don't need in output, just ignore
                        comms.info('Already converted and suitable. Ignore');
                    end
                    % in both cases, communicate progress and move on to
                    % next file
                    comms.progress(iF,nFiles);
                    continue
                end
            end
        end
         
        % reading and converting depending on file format
        switch file_format
            case 'Kongsberg_all'
                
                % datagram types to read
                switch conversionType
                    case 'WCD'
                        dtgsAllRequired = [73, ... % installation parameters (73)
                            80, ...                % position (80)
                            82];                   % runtime parameters (82)
                        dtgsOptional = 88;         % X8 depth (88)
                        dtgsEitherOf = [107, ...   % water-column (107)
                            114];                  % Amplitude and Phase (114)
                        dtgs = sort(unique([dtgsAllRequired, dtgsOptional, dtgsEitherOf]));
                    case 'Z&BS'
                        dtgsAllRequired = [73, ... % installation parameters (73)
                            80, ...                % position (80)
                            82, ...                % runtime parameters (82)
                            88];                   % X8 depth (88)
                        dtgs = sort(unique(dtgsAllRequired));
                    case 'everything'
                        % convert every datagrams supported
                        dtgs = [];
                end
                
                % conversion step 1: read what we can
                if ischar(rawFile)
                    comms.info('Reading data in file');
                else
                    comms.info('Reading data in pair of files');
                end
                [EMdata,iDtgsParsed] = CFF_read_all(rawFile, dtgs);
                
                if ~strcmp(conversionType,'everything')
                    % if requesting conversion specifically for WCD or
                    % Z&BS, a couple of checks are necessary
                    
                    % check if all required datagrams have been found 
                    iDtgsRequired = ismember(dtgsAllRequired,dtgs(iDtgsParsed));
                    if ~all(iDtgsRequired)
                        strdisp = sprintf('File is missing required datagram types (%s).',strjoin(string(dtgs(~iDtgsRequired)),', '));
                        if convertEvenIfDtgrmsMissing
                            % log message and resume conversion
                            comms.info([strdisp ' Converting anyway']);
                        else
                            % abort conversion by throwing error
                            error([strdisp ' Conversion aborted']);
                        end
                    end
                    
                    % if requesting conversion for WCD, check if at least
                    % one type of water-column datagram has been found
                    if strcmp(conversionType,'WCD') && ~any(ismember(dtgsEitherOf,dtgs(iDtgsParsed)))
                        strdisp = 'File does not contain water-column datagrams.';
                        if convertEvenIfDtgrmsMissing
                            % log message and resume conversion
                            comms.info([strdisp ' Converting anyway'])
                        else
                            % abort conversion by throwing error
                            error([strdisp ' Conversion aborted']);
                        end
                    end
                    
                end
                
                % conversion step 2: convert
                comms.info('Converting to fData format');
                fData = CFF_convert_ALLdata_to_fData(EMdata,dr_sub,db_sub);
                
                % set datagram source
                switch conversionType
                    case 'WCD'
                        % use AP if they exist
                        if ismember(114,dtgs(iDtgsParsed))
                            fData.MET_datagramSource = 'AP';
                        else
                            fData.MET_datagramSource = 'WC';
                        end
                    case 'Z&BS'
                        fData.MET_datagramSource = 'X8';
                    case 'everything'
                        % choose whatever is available
                        fData.MET_datagramSource = CFF_get_datagramSource(fData);
                end
                
                % sort fields by name
                fData = orderfields(fData);
                
            case 'Reson_s7k'
                
                % relevant datagrams:
                % R1015_Navigation
                % R1003_Position
                % R7000_SonarSettings
                % R7001_7kConfiguration
                % R7004_7kBeamGeometry
                % R7027_RAWdetection
                % R7018_7kBeamformedData
                % R7042_CompressedWaterColumn
                dg_wc = [1015 1003 7000 7001 7004 7027 7018 7042];
                
                % step 1: read
                [RESONdata, iDtgsParsed] = CFF_read_s7k(rawFile,dg_wc);
                
                % if not all datagrams were found at this point, message and abort
                if ~all(iDtgsParsed)
                    if ~any((iDtgsParsed(7:8)))
                        textprogressbar('File does not contain water-column datagrams (either R7018 or R7042). Check file contents. Conversion aborted.');
                        continue;
                    elseif ~any(iDtgsParsed(1:2))
                        textprogressbar('File does not contain position datagrams (either R1015 or R1003). Check file contents. Conversion aborted.');
                        continue;
                    elseif ~all(iDtgsParsed(3:6))
                        textprogressbar('File does not contain all necessary datagrams. Check file contents. Conversion aborted.');
                        continue;
                    end
                end
                
                if iDtgsParsed(end)
                    datagramSource = 'AP';
                else
                    datagramSource = 'WC';
                end
                
                % step 2: convert
                fData = CFF_convert_S7Kdata_to_fData(RESONdata,dr_sub,db_sub);
                
                % add datagram source
                fData.MET_datagramSource = CFF_get_datagramSource(fData,datagramSource);
                
                % sort fields by name
                fData = orderfields(fData);
                
            case 'Kongsberg_kmall'
                
                % relevant datagrams:
                % * #IIP Installation Parameters
                % * #SPO Position
                % * #MRZ Bathy and BS
                % * #MWC Water-column Data
                dg_wc = {'#IIP','#SPO','#MRZ','#MWC'};
                
                % for test/debug:
                % warning('DEBUGGING!') % uncomment this if using one below
                % dg_wc = {'#IIP'};
                % dg_wc = {'#SPO'};
                % dg_wc = {'#MRZ'};
                % dg_wc = {'#MWC'};
                % dg_wc = {}; % everything
                
                % step 1: read
                [EMdata,iDtgsParsed] = CFF_read_kmall(rawFile, dg_wc);
                
                % if not all datagrams were found at this point, message and abort
                if ~isempty(dg_wc) && ~all(iDtgsParsed)
                    strdisp = sprintf('File is missing necessary datagrams (%s). Conversion aborted.', strjoin(dg_wc(~iDtgsParsed),', '));
                    textprogressbar(strdisp);
                    continue
                end
                
                datagramSource = 'WC'; % XXX1 to update this confusing datagramsource business eventually
                
                % step 2: convert
                fData = CFF_convert_KMALLdata_to_fData(EMdata,dr_sub,db_sub);
                
                % add datagram source
                fData.MET_datagramSource = CFF_get_datagramSource(fData,datagramSource);
                
                % sort fields by name
                fData = orderfields(fData);
        end
        
        % save fData to drive
        if saveFDataToDrive || strcmp(conversionType,'WCD')
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
    % output struct direclty if only one element
    if numel(fDataGroup)==1
        fDataGroup = fDataGroup{1};
    end
end

%% end message
comms.finish('Done');

end


