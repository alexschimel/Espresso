function fData_tot = grid_watercolumn(fData_tot, idx_fData, procpar)
%GRID_WATERCOLUMN  One-line description
%
%   See also ESPRESSO.

%   Copyright 2017-2021 Alexandre Schimel, Yoann Ladroit, NIWA
%   Licensed under MIT. Details on https://github.com/alexschimel/Espresso/

% init counter
u = 0;

% general timer
timer_start = now;

for itt = idx_fData(:)'
    
    try
        
        % disp
        u = u+1;
        fprintf('Gridding file "%s" (%i/%i)...\n',fData_tot{itt}.ALLfilename{1},u,numel(idx_fData));
        fprintf('...Started at %s...',datestr(now));
        
        tic
        
        % gridding
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
        fData = fData_tot{itt};
        folder_for_converted_data = CFF_converted_data_folder(fData.ALLfilename{1});
        mat_fdata_file = fullfile(folder_for_converted_data,'fData.mat');
        save(mat_fdata_file,'-struct','fData','-v7.3');
        clear fData;
        
        % disp
        fprintf(' done. Elapsed time: %f seconds.\n',toc);
        
    catch err
        [~,f_temp,e_temp] = fileparts(err.stack(1).file);
        err_str = sprintf('Error in file %s, line %d',[f_temp e_temp],err.stack(1).line);
        fprintf('%s: ERROR gridding file %s \n%s\n',datestr(now,'HH:MM:SS'),fData_tot{itt}.ALLfilename{1},err_str);
        fprintf('%s\n\n',err.message);
    end
    
end

% finalize
timer_end = now;
fprintf('Total time for gridding: %f seconds (~%.2f minutes).\n\n',(timer_end-timer_start)*24*60*60,(timer_end-timer_start)*24*60);

end