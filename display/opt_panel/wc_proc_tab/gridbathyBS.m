function fData_tot = gridbathyBS(fData_tot, idx_fData, procpar)
%GRIDBATHYBS  One-line description
%
%   See also ESPRESSO.

%   Authors: Alex Schimel (NIWA, alexandre.schimel@niwa.co.nz) and Yoann
%   Ladroit (NIWA, yoann.ladroit@niwa.co.nz)
%   2017-2021; Last revision: 27-07-2021

% init
u = 0;
timer_start = now;

for itt = idx_fData(:)'
    
    % disp
    u = u+1;
    fprintf('Gridding BS and Bathy in file "%s" (%i/%i)...\n',fData_tot{itt}.ALLfilename{1},u,numel(idx_fData));
    fprintf('...Started at %s...',datestr(now));
    
    tic
    
    % grid bathy and BS
    fData_tot{itt} = CFF_grid_2D_fields_data(fData_tot{itt},...
        'grid_horz_res',procpar.gridbathyBS_res);
    
    % disp
    fprintf(' done. Elapsed time: %f seconds.\n',toc);

end

% finalize
timer_end = now;
fprintf('Total time for gridding bathy and BS: %f seconds (~%.2f minutes).\n\n',(timer_end-timer_start)*24*60*60,(timer_end-timer_start)*24*60);

end