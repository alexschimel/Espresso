%% convert_files.m
%
% Convert raw data files to CoFFee format (fData)
%
%% Help
%
% *AUTHOR, AFFILIATION & COPYRIGHT*
%
% Yoann Ladroit, Alexandre Schimel NIWA. Type |help Espresso.m| for
% copyright information.

%% Function
function convert_files(files_to_convert)

% NOTE: HARD-CODED PARAMETERS subsampling factors:
dr_sub = 1; % none for now
db_sub = 1; % none for now

% general timer
timer_start = now;

% number of files and start display
n_files = numel(files_to_convert);
if isempty(files_to_convert)
    fprintf('Conversion requested but no files in input. Abort\n');
    return
else
    fprintf('CONVERT %i raw data files (or pairs of files). Started at %s.\n', n_files, datestr(now));
end

% for each file
for nF = 1:n_files
    
    % using a try-catch sequence to allow continuing to the next file if
    % conversion of one fails.
    try
        
        % get the file (or pair of files) to convert
        file_to_convert = files_to_convert{nF};
        
        % name of file(s) for display
        if ischar(file_to_convert)
            file_to_convert_disp = sprintf('file "%s"',file_to_convert);
        else
            % paired file
            file_to_convert_disp = sprintf('pair of files "%s" and "%s"',file_to_convert{1},file_to_convert{2});
        end
        
        % check file format
        [~,~,f_ext] = fileparts(CFF_onerawfileonly(file_to_convert));
        if strcmpi(f_ext,'.all') || strcmpi(f_ext,'.wcd')
            file_format = 'Kongsberg_all';
        elseif strcmpi(f_ext,'.kmall') || strcmpi(f_ext,'.kmwcd')
            file_format = 'Kongsberg_kmall';
        elseif strcmpi(f_ext,'.kmall') || strcmpi(f_ext,'.kmwcd')
            file_format = 'Reson_s7k';
        else
            error('Raw file extension not recognized as a supported format.');
        end
        
        % First, clean up any existing converted data
        wc_dir = CFF_converted_data_folder(file_to_convert);
        clean_delete_fdata(wc_dir);
        
        % Now we can convert from a clean slate
        
        % display
        fprintf('%i/%i: Now converting %s...\n',nF,n_files,file_to_convert_disp);
        textprogressbar(sprintf('Started at %s. Progress: ',datestr(now)));
        textprogressbar(0);
        tic
        
        % create output folder
        mkdir(wc_dir);
        
        % define mat filename
        mat_fdata_file = fullfile(wc_dir, 'fData.mat');
        
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
                
                % step 1: convert to ALLdata format
                [EMdata,datags_parsed_idx] = CFF_read_all(file_to_convert, datagrams_to_parse);
                textprogressbar(50);
                
                if datags_parsed_idx(end)
                    datagramSource = 'AP';
                else
                    datagramSource = 'WC';
                end
                
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
                
                % step 2: convert to fdata
                fData = CFF_convert_ALLdata_to_fData(EMdata,dr_sub,db_sub);
                
                textprogressbar(90);
                
            case 'Reson_s7k'
                
                % relevant datagrams:
                % R1015_Navigation
                % R1003_Position
                % R7000_SonarSettings
                % R7001_7kConfiguration
                % R7004_7kBeamGeometry
                % R7027_RAWdetection
                % R7018_Water_column
                % R7042_CompressedWaterColumn
                dg_wc = [1015 1003 7000 7001 7004 7027 7018 7042];
                
                [RESONdata, datags_parsed_idx] = CFF_read_s7k(file_to_convert,dg_wc);
                textprogressbar(50);
                
                % if not all datagrams were found at this point, message and abort
                if ~all(datags_parsed_idx)
                    if ~any((datags_parsed_idx(7:8)))
                        textprogressbar('File does not contain water-column datagrams. Check file contents. Conversion aborted.');
                        continue;
                    elseif ~all(datags_parsed_idx(3:6))||~any(datags_parsed_idx(1:2))
                        textprogressbar('File does not contain all necessary datagrams. Check file contents. Conversion aborted.');
                        continue;
                    end
                end
                
                if datags_parsed_idx(end)
                    datagramSource = 'AP';
                else
                    datagramSource = 'WC';
                end
                
                % if output file does not exist OR if forcing reconversion, simply convert
                fData = CFF_convert_S7Kdata_to_fData(RESONdata,dr_sub,db_sub);
                
                textprogressbar(90);
                
                
            case 'Kongsberg_kmall'
                
                [EMdata,datags_parsed_idx] = CFF_read_kmall(file_to_convert);
                
        end
        
        % add datagram source
        fData.MET_datagramSource = CFF_get_datagramSource(fData,datagramSource);
        
        % and save
        save(mat_fdata_file,'-struct','fData','-v7.3');
        clear fData;
        
        % disp
        textprogressbar(100)
        textprogressbar(sprintf(' done. Duration: ~%.2f seconds.\n',toc));
        
    catch err
        fprintf('%s: ERROR converting %s\n',datestr(now,'HH:MM:SS'),file_to_convert_disp);
        if ~isdeployed
            rethrow(err);
        else
            [~,f_temp,e_temp] = fileparts(err.stack(1).file);
            err_str = sprintf('Error in file %s, line %d: %s',[f_temp e_temp],err.stack(1).line,err.message);
            fprintf('%s\n\n',err_str);
        end
    end
    
end

% general timer
timer_end = now;
duration_sec = (timer_end-timer_start)*24*60*60;
duration_min = (timer_end-timer_start)*24*60;
fprintf('DONE. Total duration: ~%.2f seconds (~%.2f minutes).\n\n',duration_sec,duration_min);
