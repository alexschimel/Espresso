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
addParameter(p,'reconvertFiles',0,@(x) mustBeMember(x,[0,1]));

% what if error during conversion? 0: to next file (def), 1: abort
addParameter(p,'abortOnError',0,@(x) mustBeMember(x,[0,1]));

% what if missing required dtgrms? 0: to next file (def), 1: convert anyway
addParameter(p,'convertEvenIfDtgrmsMissing',0,@(x) mustBeMember(x,[0,1]));

% convert for WCD processing (includes bathy/BS) or only bathy/BS (default)
addParameter(p,'conversionType','Z&BS',@(x) mustBeMember(x,{'WCD','Z&BS'}));

% decimation factor in range and beam (def 1, aka no decimation)
addParameter(p,'dr_sub',1,@(x) isnumeric(x)&&x>0&&mod(x,1)==0);
addParameter(p,'db_sub',1,@(x) isnumeric(x)&&x>0&&mod(x,1)==0);

% save fData to hard-drive? 0: no (default), 1: yes
addParameter(p,'saveFDataToDrive',0,@(x) mustBeMember(x,[0,1]));

% information communication (none by default)
addParameter(p,'comms',CFF_Comms());

% parse inputs
parse(p,files_to_convert,varargin{:});

% and get results
files_to_convert = p.Results.files_to_convert;
reconvertFiles = p.Results.reconvertFiles;
abortOnError = p.Results.abortOnError;
convertEvenIfDtgrmsMissing = p.Results.convertEvenIfDtgrmsMissing;
conversionType = p.Results.conversionType;
dr_sub = p.Results.dr_sub;
db_sub = p.Results.db_sub;
saveFDataToDrive = p.Results.saveFDataToDrive;
if ischar(p.Results.comms)
    comms = CFF_Comms(p.Results.comms);
else
    comms = p.Results.comms;
end
clear p


%% Prep

% start message
comms.startMsg('Reading and converting file(s)');

% number of files
nFiles = numel(files_to_convert);

% general timer
timer_start = now;

% init output
fDataGroup = cell(1,nFiles);

% start progress
comms.progrVal(0,nFiles);


%% Read and convert files
for iF = 1:nFiles
    
    % try-catch sequence to allow continuing to next file if one fails
    try
        
        % get the file (or pair of files) to convert
        file_to_convert = files_to_convert{iF};

        % display name for file (or pair of files)
        if ischar(file_to_convert)
            file_to_convert_disp = sprintf('file "%s"',file_to_convert);
        else
            % paired file
            file_to_convert_disp = sprintf('pair of files "%s" and "%s"',file_to_convert{1},file_to_convert{2});
        end
        % fprintf('%i/%i: %s.\n',iF,nFiles,file_to_convert_disp);
        
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
        
        % test if file already converted
        bool_already_converted = CFF_are_raw_files_converted(file_to_convert);
        
        % management & display
        if isempty(file_format)
            % format not supported, on to next file.
            comms.infoMsg(sprintf('Cannot convert file %i. Format (%s) not supported.',iF,f_ext));
            continue
        elseif bool_already_converted && ~reconvertFiles
            % already converted and not asking for reconversion, on to next
            % file. 
            comms.infoMsg(sprintf('File %i already converted, and not asking for reconversion.',iF));
            continue
        elseif bool_already_converted && reconvertFiles
            % already converted and asking for reconversion, proceed.
            comms.infoMsg(sprintf('File %i already converted. Started re-converting at %s.',iF,datestr(now)));
        else
            % not yet converted, proceed.
            comms.infoMsg(sprintf('Converting file %i at %s.',iF,datestr(now)));
        end
        
        % reading and converting
        switch file_format
            case 'Kongsberg_all'
                
                % relevant datagrams:
                % * installation parameters (73)
                % * position (80)
                % * runtime parameters (82)
                % * X8 depth (88)
                % * water-column (107)
                % * Amplitude and Phase (114)
                datagrams_to_parse = [73 80 82 88 107 114];
                
                % step 1: read
                [EMdata,datags_parsed_idx] = CFF_read_all(file_to_convert, datagrams_to_parse);
                
                % if not all datagrams were found at this point, message and abort
                if nansum(datags_parsed_idx)<5
                    if ~any(datags_parsed_idx(5:6)) && any(datags_parsed_idx(4:6))
                        textprogressbar('File does not contain water-column datagrams. Conversion aborted.');
                        continue;
                    elseif  ~all(datags_parsed_idx(1:3)) || ~any(datags_parsed_idx(4:6))
                        textprogressbar('File does not contain all necessary datagrams. Check file contents. Conversion aborted.');
                        continue;
                    end
                end
                
                if datags_parsed_idx(end)
                    datagramSource = 'AP';
                else
                    datagramSource = 'WC';
                end
                
                % step 2: convert
                fData = CFF_convert_ALLdata_to_fData(EMdata,dr_sub,db_sub);
                
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
                [RESONdata, datags_parsed_idx] = CFF_read_s7k(file_to_convert,dg_wc);
                
                % if not all datagrams were found at this point, message and abort
                if ~all(datags_parsed_idx)
                    if ~any((datags_parsed_idx(7:8)))
                        textprogressbar('File does not contain water-column datagrams (either R7018 or R7042). Check file contents. Conversion aborted.');
                        continue;
                    elseif ~any(datags_parsed_idx(1:2))
                        textprogressbar('File does not contain position datagrams (either R1015 or R1003). Check file contents. Conversion aborted.');
                        continue;
                    elseif ~all(datags_parsed_idx(3:6))
                        textprogressbar('File does not contain all necessary datagrams. Check file contents. Conversion aborted.');
                        continue;
                    end
                end
                
                if datags_parsed_idx(end)
                    datagramSource = 'AP';
                else
                    datagramSource = 'WC';
                end
                
                % step 2: convert
                fData = CFF_convert_S7Kdata_to_fData(RESONdata,dr_sub,db_sub);
                
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
                [EMdata,datags_parsed_idx] = CFF_read_kmall(file_to_convert, dg_wc);
                
                % if not all datagrams were found at this point, message and abort
                if ~isempty(dg_wc) && ~all(datags_parsed_idx)
                    strdisp = sprintf('File is missing necessary datagrams (%s). Conversion aborted.', strjoin(dg_wc(~datags_parsed_idx),', '));
                    textprogressbar(strdisp);
                    continue
                end
                
                datagramSource = 'WC'; % XXX1 to update this confusing datagramsource business eventually
                
                % step 2: convert
                fData = CFF_convert_KMALLdata_to_fData(EMdata,dr_sub,db_sub);
                
        end
        
        % add datagram source
        fData.MET_datagramSource = CFF_get_datagramSource(fData,datagramSource);
        
        % and save
        if saveFDataToDrive
            % get output folder and create it if necessary
            wc_dir = CFF_converted_data_folder(file_to_convert);
            if ~isfolder(wc_dir)
                mkdir(wc_dir);
            end
            mat_fdata_file = fullfile(wc_dir, 'fData.mat');
            save(mat_fdata_file,'-struct','fData','-v7.3');
        end
        
        % add to group for output
        fDataGroup{iF} = fData;
        
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
   
    % communicate progress
    comms.progrVal(iF,nFiles);
    
end

% output struct direclty if only one element
if numel(fDataGroup)==1
    fDataGroup = fDataGroup{1};
end

% general timer
timer_end = now;
duration_sec = (timer_end-timer_start)*24*60*60;
duration_min = (timer_end-timer_start)*24*60;
fprintf('Done. Total duration: ~%.2f seconds (~%.2f minutes).\n\n',duration_sec,duration_min);


%% end message
comms.endMsg('Done.');

end

