function fDataGroup = CFF_convert_raw_files(files_to_convert,varargin)
%CFF_CONVERT_RAW_FILES Summary of this function goes here
%   Detailed explanation goes here


%% Input arguments management
p = inputParser;

% list of files (or pairs of files) to convert
argName = 'files_to_convert';
argCheck = @(x) ~isempty(x) && (ischar(x) || iscell(x));
addRequired(p,argName,argCheck);

% what if file already converted? 0: to next file (default), 1: reconvert
addParameter(p,'forceReconvert',0,@(x) mustBeMember(x,[0,1]));

% what if error during conversion? 0: to next file (default), 1: abort
addParameter(p,'abortOnError',0,@(x) mustBeMember(x,[0,1]));

% what if missing required dtgrms? 0: to next file (def), 1: convert anyway
addParameter(p,'convertEvenIfDtgrmsMissing',0,@(x) mustBeMember(x,[0,1]));

% convert for WCD processing (includes bathy/BS) or only bathy/BS (default)
addParameter(p,'conversionType','Z&BS',@(x) mustBeMember(x,{'WCD','Z&BS'}));

% decimation factor in range and beam (def 1, aka no decimation)
addParameter(p,'dr_sub',1,@(x) isnumeric(x)&&x>0&&mod(x,1)==0);
addParameter(p,'db_sub',1,@(x) isnumeric(x)&&x>0&&mod(x,1)==0);

% save fData to hard-drive? 0: no (default), 1: yes
% Note that if we convert for WCD processing, we will disregard that info
% and save fData to drive anyway
addParameter(p,'saveFDataToDrive',0,@(x) mustBeMember(x,[0,1]));

% output fData? 0: no, 1: yes (default)
% Unecessary in apps like Espresso, but useful in scripts
addParameter(p,'outputFData',1,@(x) mustBeMember(x,[0,1]));

% information communication (none by default)
addParameter(p,'comms',CFF_Comms());

% parse inputs
parse(p,files_to_convert,varargin{:});

% and get results
files_to_convert = p.Results.files_to_convert;
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

% number of files
nFiles = numel(files_to_convert);

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
        file_to_convert = files_to_convert{iF};
        
        % display for this file
        if ischar(file_to_convert)
            filename = CFF_file_name(file_to_convert,1);
            comms.step(sprintf('%i/%i: file %s. ',iF,nFiles,filename));
        else
            % paired files
            filename_1 = CFF_file_name(file_to_convert{1},1);
            filename_2_ext = CFF_file_extension(file_to_convert{2});
            comms.step(sprintf('%i/%i: pair of files %s and %s. ',iF,nFiles,filename_1,filename_2_ext));
        end
        
        % file format
        [~,~,f_ext] = fileparts(CFF_onerawfileonly(file_to_convert));
        if strcmpi(f_ext,'.all') || strcmpi(f_ext,'.wcd')
            file_format = 'Kongsberg_all';
        elseif strcmpi(f_ext,'.kmall') || strcmpi(f_ext,'.kmwcd')
            file_format = 'Kongsberg_kmall';
        elseif strcmpi(f_ext,'.s7k')
            file_format = 'Reson_s7k';
        else
            file_format = [];
        end
        
        % convert, reconvert, update, or ignore based on file status
        [idxConverted,idxFDataUpToDate,idxHasWCD] = CFF_are_raw_files_converted(file_to_convert);
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
                        comms.info('Already converted and suitable. Loading');
                        wc_dir = CFF_converted_data_folder(file_to_convert);
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
                end
                
                % conversion step 1: read what we can
                if ischar(file_to_convert)
                    comms.info('Reading data in file');
                else
                    comms.info('Reading data in pair of files');
                end
                [EMdata,iDtgsParsed] = CFF_read_all(file_to_convert, dtgs);
                
                % check if all required datagrams have been found
                iDtgsRequired = ismember(dtgsAllRequired,dtgs(iDtgsParsed));
                if ~all(iDtgsRequired)
                    strdisp = sprintf('File is missing necessary datagram types (%s).',strjoin(string(dtgs(~iDtgsRequired)),', '));
                    if convertEvenIfDtgrmsMissing
                        % log message and resume conversion
                        comms.info(strdisp);
                    else
                        % disp message and abort conversion
                        strdisp = strcat(strdisp, ' Conversion aborted.');
                        textprogressbar(strdisp);
                        continue;
                    end
                end
                
                % for WCD, check if at least one type of water-column
                % datagram has been found
                if strcmp(conversionType,'WCD') && ~any(ismember(dtgsEitherOf,dtgs(iDtgsParsed)))
                    strdisp = 'File does not contain water-column datagrams.';
                    if convertEvenIfDtgrmsMissing
                        comms.info(strdisp);
                    else
                        strdisp = strcat(strdisp, ' Conversion aborted.');
                        textprogressbar(strdisp);
                        continue;
                    end
                end
                
                % set datagram source
                switch conversionType
                    case 'WCD'
                        % use AP if they exist
                        if ismember(114,dtgs(iDtgsParsed))
                            datagramSource = 'AP';
                        else
                            datagramSource = 'WC';
                        end
                    case 'Z&BS'
                        datagramSource = 'X8';
                end
                
                % conversion step 2: convert
                comms.info('Converting to fData format');
                fData = CFF_convert_ALLdata_to_fData(EMdata,dr_sub,db_sub);
                
                % add datagram source
                fData.MET_datagramSource = CFF_get_datagramSource(fData,datagramSource);
                
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
                [RESONdata, iDtgsParsed] = CFF_read_s7k(file_to_convert,dg_wc);
                
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
                [EMdata,iDtgsParsed] = CFF_read_kmall(file_to_convert, dg_wc);
                
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
            wc_dir = CFF_converted_data_folder(file_to_convert);
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
        
    catch err
        
        % display which file as this info is not in the error message
        fprintf('%s: ERROR converting %s\n',datestr(now,'HH:MM:SS'),file_to_convert_disp);
        
        if abortOnError
            rethrow(err);
        else
            % print error information for developers before moving onto
            % next file
            [~,f_temp,e_temp] = fileparts(err.stack(1).file);
            fprintf('Error in %s (line %d): %s\n',[f_temp e_temp],err.stack(1).line,err.message);
        end
    end
    
    % end of this iteration
    comms.info('Done');
       
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
comms.finish('Done.');

end


