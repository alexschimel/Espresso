function convert_files(files_to_convert, files_already_converted, reconvert_flag)

% HARD-CODED PARAMETER:
% the source datagram that will be used throughout the program for
% processing
% by default is 'WC' but 'AP' can be used for Amplitude-Phase datagrams
% instead. If there is no water-column datagram, you can still use Espresso
% to convert and load and display data, using the depths datagrams 'De' or
% 'X8'


% general timer
timer_start = now;

% for each file
for nF = 1:numel(files_to_convert)
    
    % using a try-catch sequence to allow continuing to the next file if
    % conversion of one fails.
    try
        
        % get file to convert
        file_to_convert = files_to_convert{nF};
        
        [~,~,f_ext] = fileparts(file_to_convert);
        
        if isempty(f_ext)||strcmpi(f_ext,'.db')
            if isfile([file_to_convert,'.wcd'])
                f_ext = '.wcd';
            elseif isfile([file_to_convert,'.all'])
                f_ext = '.all';
            elseif isfile([file_to_convert,'.s7k'])
                f_ext = '.s7k';
            end
        end
        
        % get folder for converted data
        folder_for_converted_data = CFF_converted_data_folder(file_to_convert);
        
        % converted filename fData
        mat_fdata_file = fullfile(folder_for_converted_data,'fdata.mat');
        
        % subsampling factors:
        dr_sub = 1; % none for now
        db_sub = 1; % none for now
        
        dr_sub_old = 0;
        db_sub_old = 0;
        ver = '0.0';
        
        if isfile(mat_fdata_file)
            fData_old = load(mat_fdata_file);
            if isfield(fData_old,'MET_Fmt_version')
                % added a version for fData
                ver = fData_old.MET_Fmt_version;
            end
            dr_sub_old = fData_old.dr_sub;
            db_sub_old = fData_old.db_sub;
        else
            fData_old = {};
        end
        
        convert = reconvert_flag || ~isfile(mat_fdata_file) || ~strcmpi(ver,CFF_get_current_fData_version) || dr_sub_old~=dr_sub || db_sub_old~=db_sub || ~files_already_converted(nF);
        
        % if file already converted and not asking for reconversion, exit here
        if ~convert
            fprintf('File "%s" (%i/%i) is already converted.\n',file_to_convert,nF,numel(files_to_convert));
            continue;
        end
        
        clean_fdata(fData_old);
        if isfile(mat_fdata_file)
            delete(mat_fdata_file);
        end
        fData_old = {};
        
        % Otherwise, starting conversion...
        fprintf('\nConverting file "%s" (%i/%i)...\n',file_to_convert,nF,numel(files_to_convert));
        textprogressbar(sprintf('...Started at %s. Progress: ',datestr(now)));
        textprogressbar(0);
        tic
        
        % if output folder doesn't exist, create it
        MATfilepath = fileparts(mat_fdata_file);
        if ~exist(MATfilepath,'dir') && ~isempty(MATfilepath)
            mkdir(MATfilepath);
        end
        
        switch f_ext
            case {'.all' '.wcd'}
                
                % set datagram source
                %             datagramSource = 'WC'; % 'AP', 'De', 'X8'
                %
                %             switch datagramSource
                %                 case 'WC'
                %                     wc_d = 107;
                %                 case 'AP'
                %                     wc_d = 114;
                %                 case 'De'
                %                     wc_d = 68;
                %             end
                
                % We also need installation parameters (73), position (80), and runtime
                % parameters (82) datagrams. List datagrams required
                dg_wc = [73 80 82 88 107 114];
                
                % conversion to ALLdata format
                [EMdata,datags_parsed_idx] = CFF_read_all(file_to_convert, dg_wc);
                textprogressbar(50);
                
                if datags_parsed_idx(end)
                    datagramSource='AP';
                else
                    datagramSource='WC';
                end
                
                % if not all datagrams were found at this point, message and abort
                if nansum(datags_parsed_idx)<5
                    if ~any(datags_parsed_idx(5:6))&&any(datags_parsed_idx(4:6))
                        textprogressbar('File does not contain water-column datagrams. Conversion aborted.');
                        continue;
                    elseif  ~all(datags_parsed_idx(1:3))||~any(datags_parsed_idx(4:6))
                        textprogressbar('File does not contain all necessary datagrams. Check file contents. Conversion aborted.');
                        continue;
                    end
                end
                
            case '.s7k'
                
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
                
            otherwise
                continue;
        end
        
        switch f_ext
            case {'.all' '.wcd'}
                % if output file does not exist OR if forcing reconversion, simply convert
                fData = CFF_convert_ALLdata_to_fData(EMdata,dr_sub,db_sub,fData_old);
                
                textprogressbar(90);
                
            case '.s7k'
                % if output file does not exist OR if forcing reconversion, simply convert
                fData = CFF_convert_S7Kdata_to_fData(RESONdata,dr_sub,db_sub,fData_old);
                
                textprogressbar(90);
        end
        
        % add datagram source
        fData.MET_datagramSource = CFF_get_datagramSource(fData,datagramSource);
        
        % and save
        save(mat_fdata_file,'-struct','fData','-v7.3');
        clear fData;
        
        % disp
        textprogressbar(100)
        textprogressbar(sprintf(' done. Elapsed time: %f seconds.\n',toc));
        
    catch err
        [~,f_temp,e_temp] = fileparts(err.stack(1).file);
        err_str = sprintf('Error in file %s, line %d',[f_temp e_temp],err.stack(1).line);
        fprintf('%s: ERROR converting file %s \n%s\n',datestr(now,'HH:MM:SS'),file_to_convert,err_str);
        fprintf('%s\n\n',err.message);
        if ~isdeployed
            rethrow(err);
        end
    end
    
end

% general timer
timer_end = now;
fprintf('Total time for conversion: %f seconds (~%.2f minutes).\n\n',(timer_end-timer_start)*24*60*60,(timer_end-timer_start)*24*60);
