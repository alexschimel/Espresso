function convert_files(files_to_convert, flag_force_convert)
%CONVERT_FILES  Convert raw data files to CoFFee format (fData)
%
%   See also ESPRESSO.

%   Authors: Alex Schimel (NIWA, alexandre.schimel@niwa.co.nz) and Yoann
%   Ladroit (NIWA, yoann.ladroit@niwa.co.nz)
%   2017-2021; Last revision: 21-07-2021

% NOTE: HARD-CODED PARAMETERS subsampling factors:
dr_sub = 1; % none at this stage, subsampling occuring at processing
db_sub = 1; % none at this stage, subsampling occuring at processing

% general timer
timer_start = now;

% number of files and start display
n_files = numel(files_to_convert);
if isempty(files_to_convert)
    fprintf('Requesting conversion, but no files in input. Abort.\n\n');
    return
else
    if n_files == 1
        fprintf('Requested conversion of 1 raw data file (or pair of files) at %s...\n', datestr(now));
    else
        fprintf('Requested conversion of %i raw data files (or pairs of files) at %s...\n', n_files, datestr(now));
    end
end

% for each file
for nF = 1:n_files
    
    % using a try-catch sequence to allow continuing to the next file if
    % conversion of one fails.
    try
        
        % get the file (or pair of files) to convert
        file_to_convert = files_to_convert{nF};
        
        % start of display for this file
        if ischar(file_to_convert)
            file_to_convert_disp = sprintf('file "%s"',file_to_convert);
        else
            % paired file
            file_to_convert_disp = sprintf('pair of files "%s" and "%s"',file_to_convert{1},file_to_convert{2});
        end
        fprintf('%i/%i: %s.\n',nF,n_files,file_to_convert_disp);
        
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
            % format not supported, abort.
            fprintf('...Cannot be converted. Format not (yet?) supported: "%s".\n',f_ext);
            continue
        elseif bool_already_converted && ~flag_force_convert
            % already converted and not asking for reconversion, abort.
            fprintf('...Already converted (and not asking for reconversion).\n');
            continue
        elseif bool_already_converted && flag_force_convert
            % already converted but asking for reconversion, proceed.
            fprintf('...Already converted. Started re-converting at %s. \n',datestr(now));
        else
            % not yet converted, proceed.
            fprintf('...Started converting at %s. \n',datestr(now));
        end
        textprogressbar('...Progress: ');
        textprogressbar(0);
        tic
        
        % First, clean up any existing converted data
        wc_dir = CFF_converted_data_folder(file_to_convert);
        clean_delete_fdata(wc_dir);
        
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
                
                % step 1: read
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
                
                % step 2: convert
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
                % R7018_7kBeamformedData
                % R7042_CompressedWaterColumn
                dg_wc = [1015 1003 7000 7001 7004 7027 7018 7042];
                
                % step 1: read
                [RESONdata, datags_parsed_idx] = CFF_read_s7k(file_to_convert,dg_wc);
                textprogressbar(50);
                
                % if not all datagrams were found at this point, message and abort
                %                 if ~all(datags_parsed_idx)
                %                     if ~any((datags_parsed_idx(7:8)))
                %                         textprogressbar('File does not contain water-column datagrams (either R7018 or R7042). Check file contents. Conversion aborted.');
                %                         continue;
                %                     elseif ~any(datags_parsed_idx(1:2))
                %                         textprogressbar('File does not contain position datagrams (either R1015 or R1003). Check file contents. Conversion aborted.');
                %                         continue;
                %                     elseif ~all(datags_parsed_idx(3:6))
                %                         textprogressbar('File does not contain all necessary datagrams. Check file contents. Conversion aborted.');
                %                         continue;
                %                     end
                %                 end
                
                if datags_parsed_idx(end)
                    datagramSource = 'AP';
                else
                    datagramSource = 'WC';
                end
                
                % step 2: convert
                fData = CFF_convert_S7Kdata_to_fData(RESONdata,dr_sub,db_sub);
                textprogressbar(90);
                
            case 'Kongsberg_kmall'
                
                % relevant datagrams:
                % dg_wc = {'#IIP'}; % Installation Parameters only
                % dg_wc = {'#IOP'}; % Runtime parameters only
                % dg_wc = {'#SPO'}; % Position only
                % dg_wc = {'#MRZ'}; % Bathy and BS only
                % dg_wc = {'#MWC'}; % WCD only
                dg_wc = {'#IIP','#IOP','#SPO','#MRZ','#MWC'}; % all five above
                % dg_wc = {}; % everything, for test
                
                [EMdata,datags_parsed_idx] = CFF_read_kmall(file_to_convert, dg_wc);
                datagramSource = 'WC'; % XXX1 to update this confusing datagramsource business eventually
                
                % step 2: convert
                fData = CFF_convert_KMALLdata_to_fData(EMdata,dr_sub,db_sub);
                textprogressbar(90);
                
        end
        
        % add datagram source
        fData.MET_datagramSource = CFF_get_datagramSource(fData,datagramSource);
        
        % and save
        save(mat_fdata_file,'-struct','fData','-v7.3');
        clear fData;
        
        % disp
        textprogressbar(100)
        fprintf(' Done. Duration: ~%.2f seconds.\n',toc);
        
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
fprintf('Done. Total duration: ~%.2f seconds (~%.2f minutes).\n\n',duration_sec,duration_min);
