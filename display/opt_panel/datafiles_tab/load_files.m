function [fData, disp_config] = load_files(fData, files_to_load, disp_config)
%LOAD_FILES  Load converted data (fData) into Espresso
%
%   See also ESPRESSO.

%   Authors: Yoann Ladroit (NIWA, yoann.ladroit@niwa.co.nz) and Alex
%   Schimel (NIWA, alexandre.schimel@niwa.co.nz)
%   2017-2021; Last revision: 27-07-2021

%% Prep

% start message
comms = CFF_Comms('multilines');
comms.start('Loading file(s)');

% single filename in input
if ischar(files_to_load)
    files_to_load = {files_to_load};
end

% number of files
nFiles = numel(files_to_load);

% start progress
comms.progress(0,nFiles);


%% Load files
for iF = 1:nFiles
    
    % try-catch sequence to allow continuing to next file if one fails
    try
        
        % get the file (or pair of files) to load
        file_to_load = files_to_load{iF};
        
        % display for this file
        if ischar(file_to_load)
            filename = CFF_file_name(file_to_load,1);
            comms.step(sprintf('%i/%i: file %s',iF,nFiles,filename));
        else
            % paired files
            filename_1 = CFF_file_name(file_to_load{1},1);
            filename_2_ext = CFF_file_extension(file_to_load{2});
            comms.step(sprintf('%i/%i: pair of files %s and %s',iF,nFiles,filename_1,filename_2_ext));
        end
        
        % converted filename fData
        folder_for_converted_data = CFF_converted_data_folder(file_to_load);
        mat_fdata_file = fullfile(folder_for_converted_data,'fdata.mat');
        
        % loading temp
        fData_temp = load(mat_fdata_file);
        
        % check if paths in fData are accurate and change them if necessary
        dirchange_flag = 0; % init flag to trigger a re-save
        
        % checking paths to .all/.wcd
        for nR = 1:length(fData_temp.ALLfilename)
            [filepath_in_fData,name,ext] = fileparts(fData_temp.ALLfilename{nR});
            filepath_actual = fileparts(file_to_load);
            if ~strcmp(filepath_in_fData,filepath_actual)
                fData_temp.ALLfilename{nR} = fullfile(filepath_actual,[name ext]);
                dirchange_flag = 1;
            end
        end
        
        % checking path to water-column data binary files
        fields = {'WC_SBP_SampleAmplitudes' 'AP_SBP_SampleAmplitudes' 'AP_SBP_SamplePhase' 'X_SBP_WaterColumnProcessed'};
        dirchange_flag = 0;
        for ifi = 1:numel(fields)
            if isfield(fData_temp,fields{ifi})
                if ~iscell(fData_temp.(fields{ifi}))
                    fData_temp.(fields{ifi}) = {fData_temp.(fields{ifi})};
                end
                for ic = 1:numel(fData_temp.(fields{ifi}))
                    if ~isempty(fData_temp.(fields{ifi}){ic})
                        [filepath_in_fData,name,ext] = fileparts(fData_temp.(fields{ifi}){ic}.Filename);
                        if ~strcmp(filepath_in_fData,folder_for_converted_data)
                            fData_temp.(fields{ifi}){ic}.Filename = fullfile(folder_for_converted_data,[name ext]);
                            dirchange_flag = 1;
                        end
                    end
                end
            end
            
        end
        
        % saving on disk if changes have been made
        if dirchange_flag
            fprintf('...This file has been moved from the directory where it was originally converted/processed. Paths were fixed. Now saving the data back onto disk...\n');
            try
                save(mat_fdata_file,'-struct','fData_temp','-v7.3');
            catch
                warning('Saving file not possible, but fixed data are loaded in Espresso and session can continue.');
            end
        end
        
        
        %% Interpolating navigation data from ancillary sensors to ping time
        
        if strcmp(disp_config.MET_tmproj,'')
            % Project has no projection yet, let's use the one for that file.
            
            % First, test if file has already been projected...
            if isfield(fData_temp,'MET_tmproj')
                % File has already been projected, no need to do it again. Use
                % that info for project
                
                fprintf('...This file''s navigation data has already been processed.\n');
                
                % save the info in disp_config
                disp_config.MET_datagramSource = CFF_get_datagramSource(fData_temp);
                disp_config.MET_ellips         = fData_temp.MET_ellips;
                disp_config.MET_tmproj         = fData_temp.MET_tmproj;
                
            else
                % first time processing this file, use the default ellipsoid
                % and projection that are relevant to the data
                
                % Interpolating navigation data from ancillary sensors to ping
                % time
                fprintf('...Interpolating navigation data from ancillary sensors to ping time...\n');
                fData_temp = CFF_compute_ping_navigation(fData_temp);
                
                % save the info in disp_config
                disp_config.MET_datagramSource = CFF_get_datagramSource(fData_temp);
                disp_config.MET_ellips         = fData_temp.MET_ellips;
                disp_config.MET_tmproj         = fData_temp.MET_tmproj;
                
            end
            
            fprintf('...Projection for this session defined from navigation data in this first loaded file (ellipsoid: %s, UTM zone: %s).\n', disp_config.MET_ellips, disp_config.MET_tmproj);
            
        else
            % Project already has a projection so use this one. Note that this
            % means we may force the use of a UTM projection for navigation
            % data that is outside that zone. It should still work.
            
            if isfield(fData_temp,'MET_tmproj')
                % if this file already has a projection
                
                if strcmp(fData_temp.MET_tmproj,disp_config.MET_tmproj)
                    % file has already been projected at the same projection as
                    % project, no need to do it again.
                    
                    fprintf('...This file''s navigation data has already been processed.\n');
                    
                else
                    % file has already been projected but at a different
                    % projection than project. We're going to reprocess the
                    % navigation, but any gridding needs to be removed first.
                    % Throw a warning if we do that.
                    if isfield(fData_temp,'X_NEH_gridLevel')
                        fData_temp = rmfield(fData_temp,{'X_1_gridHorizontalResolution','X_1E_gridEasting','X_N1_gridNorthing','X_NEH_gridDensity','X_NEH_gridLevel'});
                        warning('This file contains gridded data in a projection that is different than that of the project. These gridded data were removed.')
                    end
                    
                    % Interpolating navigation data from ancillary sensors to
                    % ping time
                    fprintf('...Interpolating navigation data from ancillary sensors to ping time...\n');
                    fData_temp = CFF_compute_ping_navigation(fData_temp, ...
                        disp_config.MET_datagramSource, ...
                        disp_config.MET_ellips, ...
                        disp_config.MET_tmproj);
                    
                end
                
            else
                % File has not been projected yet, just do it now using
                % project's info
                
                % Interpolating navigation data from ancillary sensors to ping
                % time
                fprintf('...Interpolating navigation data from ancillary sensors to ping time...\n');
                fData_temp = CFF_compute_ping_navigation(fData_temp, ...
                    disp_config.MET_datagramSource, ...
                    disp_config.MET_ellips, ...
                    disp_config.MET_tmproj);
                
            end
            
        end
        
        %% Processing bottom detect
        if ismember(CFF_get_datagramSource(fData_temp),{'WC' 'AP' 'X8'})
            fprintf('...Georeferencing bottom detect...\n');
            fData_temp = CFF_georeference_WC_bottom_detect(fData_temp);
        end
        
        %% Finish-up
        
        % Time-tag that fData
        fData_temp.ID = str2double(datestr(now,'yyyymmddHHMMSSFFF'));
        
        % If data have already been processed, load the binary file into
        % fData
        % NOTE: if data have already been processed, the fData and the
        % binary files should already exist and should already been
        % attached, without need to re-memmap them... So verify if there is
        % actual need for this part... XXX1. For now putting it as comment
        % wc_dir = CFF_converted_data_folder(fData_temp.ALLfilename{1});
        % WaterColumnProcessed_file = fullfile(wc_dir,'X_SBP_WaterColumnProcessed.dat');
        % if isfile(WaterColumnProcessed_file)
        %   [nSamples,nBeams,nPings] = size(fData_temp.([datagramSource '_SBP_SampleAmplitudes']).Data.val);
        %   fData_temp.X_SBP_WaterColumnProcessed = memmapfile(WaterColumnProcessed_file, 'Format',{'int8' [nSamples nBeams nPings] 'val'},'repeat',1,'writable',true);
        % end
        
        % why pause here? XXX2
        pause(1e-3);

        % add this file's data to the full fData
        fData{numel(fData)+1} = fData_temp;
        
        % disp
        fprintf('...Done. Duration: ~%.2f seconds.\n',toc);
        
    catch err
        fprintf('%s: ERROR loading %s\n',datestr(now,'HH:MM:SS'),'dEBUGreplacethis');
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
% timer_end = now;
% duration_sec = (timer_end-timer_start)*24*60*60;
% duration_min = (timer_end-timer_start)*24*60;
% fprintf('Done. Total duration: ~%.2f seconds (~%.2f minutes).\n\n',duration_sec,duration_min);
