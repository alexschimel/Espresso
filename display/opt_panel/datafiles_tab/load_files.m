function [fData, disp_config] = load_files(fData, files_to_load, disp_config)
%LOAD_FILES  Load converted data (fData) into Espresso
%
%   !!!OBSOLETE!!! The task of loading (in create_datafiles_tab.m) is now
%   split between a CoFFee function doing the geoprocessing
%   (CFF_GEOPROCESS_FILES) and another that updates the paths
%   (CFF_FIX_FDATA_PATHS), and the remaining tasks (time-tagging, and
%   updating disp_config) are now into the callback when calling for
%   loading. Keeping this function here, but commented, for archive.

%   Authors: Yoann Ladroit (NIWA, yoann.ladroit@niwa.co.nz) and Alex
%   Schimel (NIWA, alexandre.schimel@niwa.co.nz)
%   2017-2021; Last revision: 11-11-2021

% %% Prep
% 
% % temp. add it as parameter
% abortOnError = ~isdeployed;
% 
% % start message
% comms = CFF_Comms('multilines');
% comms.start('Loading file(s)');
% 
% % single filename in input
% if ischar(files_to_load)
%     files_to_load = {files_to_load};
% end
% 
% % number of files
% nFiles = numel(files_to_load);
% 
% % start progress
% comms.progress(0,nFiles);
% 
% 
% %% Load files
% for iF = 1:nFiles
%     
%     % try-catch sequence to allow continuing to next file if one fails
%     try
%         
%         % get the file (or pair of files) to load
%         file_to_load = files_to_load{iF};
%         
%         % display for this file
%         if ischar(file_to_load)
%             filename = CFF_file_name(file_to_load,1);
%             comms.step(sprintf('%i/%i: file %s',iF,nFiles,filename));
%         else
%             % paired files
%             filename_1 = CFF_file_name(file_to_load{1},1);
%             filename_2_ext = CFF_file_extension(file_to_load{2});
%             comms.step(sprintf('%i/%i: pair of files %s and %s',iF,nFiles,filename_1,filename_2_ext));
%         end
%         
%         % load converted data
%         fDataFolder = CFF_converted_data_folder(file_to_load);
%         fData_temp = load(fullfile(fDataFolder,'fData.mat'));
%         
%         % fix fData paths if necessary
%         fData_temp = CFF_fix_fData_paths(fData_temp, file_to_load);
%         
%         %% Interpolating navigation data from ancillary sensors to ping time
%         
%         if strcmp(disp_config.MET_tmproj,'')
%             % Project has no projection yet, let's use the one for that file.
%             
%             % First, test if file has already been projected...
%             if isfield(fData_temp,'MET_tmproj')
%                 % File has already been projected, no need to do it again. Use
%                 % that info for project
%                 
%                 comms.info('This file''s navigation data has already been processed');
%                 
%                 % save needed metadata in disp_config
%                 disp_config.MET_datagramSource = CFF_get_datagramSource(fData_temp);
%                 disp_config.MET_ellips         = fData_temp.MET_ellips;
%                 disp_config.MET_tmproj         = fData_temp.MET_tmproj;
%                 
%             else
%                 % first time processing this file, use the default ellipsoid
%                 % and projection that are relevant to the data
%                 
%                 % Interpolating navigation data from ancillary sensors to ping
%                 % time
%                 comms.info('Interpolate navigation data from ancillary sensors to ping time');
%                 fData_temp = CFF_compute_ping_navigation(fData_temp);
%                 
%                 % save needed metadata in disp_config
%                 disp_config.MET_datagramSource = CFF_get_datagramSource(fData_temp);
%                 disp_config.MET_ellips         = fData_temp.MET_ellips;
%                 disp_config.MET_tmproj         = fData_temp.MET_tmproj;
%                 
%             end
%             
%             comms.info(sprintf('Projection for this session defined from navigation data in this first loaded file (ellipsoid: %s, UTM zone: %s)', disp_config.MET_ellips, disp_config.MET_tmproj));
%             
%         else
%             % Project already has a projection so use this one. Note that this
%             % means we may force the use of a UTM projection for navigation
%             % data that is outside that zone. It should still work.
%             
%             if isfield(fData_temp,'MET_tmproj')
%                 % if this file already has a projection
%                 
%                 if strcmp(fData_temp.MET_tmproj,disp_config.MET_tmproj)
%                     % file has already been projected at the same projection as
%                     % project, no need to do it again.
%                     
%                     comms.info('This file''s navigation data has already been processed');
%                     
%                 else
%                     % file has already been projected but at a different
%                     % projection than project. We're going to reprocess the
%                     % navigation, but any gridding needs to be removed first.
%                     % Throw a warning if we do that.
%                     if isfield(fData_temp,'X_NEH_gridLevel')
%                         fData_temp = rmfield(fData_temp,{'X_1_gridHorizontalResolution','X_1E_gridEasting','X_N1_gridNorthing','X_NEH_gridDensity','X_NEH_gridLevel'});
%                         comms.info('This file contains gridded data in a projection that is different than that of the project. These gridded data were removed')
%                     end
%                     
%                     % Interpolating navigation data from ancillary sensors to
%                     % ping time
%                     comms.info('Interpolate navigation data from ancillary sensors to ping time');
%                     fData_temp = CFF_compute_ping_navigation(fData_temp, ...
%                         disp_config.MET_datagramSource, ...
%                         disp_config.MET_ellips, ...
%                         disp_config.MET_tmproj);
%                     
%                 end
%                 
%             else
%                 % File has not been projected yet, just do it now using
%                 % project's info
%                 
%                 % Interpolating navigation data from ancillary sensors to ping
%                 % time
%                 comms.info('Interpolate navigation data from ancillary sensors to ping time');
%                 fData_temp = CFF_compute_ping_navigation(fData_temp, ...
%                     disp_config.MET_datagramSource, ...
%                     disp_config.MET_ellips, ...
%                     disp_config.MET_tmproj);
%                 
%             end
%             
%         end
%         
%         
%         %% Processing bottom detect
%         datagramSource = CFF_get_datagramSource(fData_temp);
%         if ismember(datagramSource,{'WC' 'AP' 'X8'})
%             comms.info('Geo-reference bottom detect');
%             fData_temp = CFF_georeference_WC_bottom_detect(fData_temp);
%         end
%         
%         
%         %% Finish-up
%         
%         % Time-tag that fData
%         fData_temp.ID = str2double(datestr(now,'yyyymmddHHMMSSFFF'));
%         pause(1e-3); % pause to ensure unique time-tags
%         
%         % If data have already been processed, load the binary file into
%         % fData
%         % NOTE: if data have already been processed, the fData and the
%         % binary files should already exist and should already been
%         % attached, without need to re-memmap them... So verify if there is
%         % actual need for this part... XXX1. For now putting it as comment
%         % wc_dir = CFF_converted_data_folder(fData_temp.ALLfilename{1});
%         % WaterColumnProcessed_file = fullfile(wc_dir,'X_SBP_WaterColumnProcessed.dat');
%         % if isfile(WaterColumnProcessed_file)
%         %   [nSamples,nBeams,nPings] = size(fData_temp.([datagramSource '_SBP_SampleAmplitudes']).Data.val);
%         %   fData_temp.X_SBP_WaterColumnProcessed = memmapfile(WaterColumnProcessed_file, 'Format',{'int8' [nSamples nBeams nPings] 'val'},'repeat',1,'writable',true);
%         % end
%         
%         % add this file's data to the full fData
%         fData{numel(fData)+1} = fData_temp;
%         
%         % successful end of this iteration
%         comms.info('Done');
%         
%     catch err
%         if abortOnError
%             % just rethrow error to terminate execution
%             rethrow(err);
%         else
%             % log the error and continue
%             errorFile = CFF_file_name(err.stack(1).file,1);
%             errorLine = err.stack(1).line;
%             errrorFullMsg = sprintf('%s (error in %s, line %i)',err.message,errorFile,errorLine);
%             comms.error(errrorFullMsg);
%         end
%     end
%     
%     % communicate progress
%     comms.progress(iF,nFiles);
%     
% end
% 
% 
% %% end message
% comms.finish('Done');
