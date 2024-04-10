function fData_tot = grid_watercolumn(fData_tot, idx_fData, procpar)
%GRID_WATERCOLUMN  grid water-column data
%
%   See also ESPRESSO.

%   Copyright 2017-2024 Alexandre Schimel, Yoann Ladroit, NIWA
%   Licensed under MIT. Details on https://github.com/alexschimel/Espresso/

% initiate comms
comms = CFF_Comms('multilines');
comms.start('Gridding water-column data');
iFD = 0;
nFData = numel(idx_fData);
comms.progress(iFD,nFData);

for itt = idx_fData(:)'
    
    % processing using a try-catch so that processing left overnight can
    % continue even if one file fails.
    try
        
        % start comms for this line
        iFD = iFD+1;
        filename = CFF_file_name(fData_tot{itt}.ALLfilename{1});
        comms.step(sprintf('%i/%i: fData line %s',iFD,nFData,filename));
        
        % gridding
        comms.info('Gridding data...');
        fData_tot{itt} = CFF_grid_WC_data(fData_tot{itt},...
            'grid_horz_res',procpar.grid_horz_res,...
            'grid_vert_res',procpar.grid_vert_res,...
            'grid_type',procpar.grid_type,...
            'dr_sub',procpar.dr_sub,...
            'db_sub',procpar.db_sub,...
            'grdlim_mode',procpar.grdlim_mode,...
            'grdlim_var',procpar.grdlim_var,...
            'grdlim_mindist',procpar.grdlim_mindist,...
            'grdlim_maxdist',procpar.grdlim_maxdist,...
            'data_type',procpar.data_type);
               
        % save the updated fData on the drive
        comms.info('Updating fData on the drive...');
        fData = fData_tot{itt};
        folder_for_converted_data = CFF_converted_data_folder(fData.ALLfilename{1});
        mat_fdata_file = fullfile(folder_for_converted_data,'fData.mat');
        save(mat_fdata_file,'-struct','fData','-v7.3');
        clear fData;
        
        % successful end of this iteration
        comms.info('Done.');
        
        % error catching
    catch err
        [~,f_temp,e_temp] = fileparts(err.stack(1).file);
        err_str = sprintf('Error in file %s, line %d',[f_temp e_temp],err.stack(1).line);
        fprintf('%s: ERROR gridding file %s \n%s\n',datestr(now,'HH:MM:SS'),fData_tot{itt}.ALLfilename{1},err_str);
        fprintf('%s\n\n',err.message);
    end
    
    % communicate progress
    comms.progress(iFD,nFData);
    
end

%% end message
comms.finish('Done.');


end