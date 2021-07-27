function fData_tot = filter_bottomdetect(fData_tot, idx_fData)
%FILTER_BOTTOMDETECT  One-line description
%
%   See also ESPRESSO.

%   Authors: Alex Schimel (NIWA, alexandre.schimel@niwa.co.nz) and Yoann
%   Ladroit (NIWA, yoann.ladroit@niwa.co.nz)
%   2017-2021; Last revision: 27-07-2021

% hardcoded parameters for filtering
botfilter.method = 'filter';
botfilter.pingBeamWindowSize = [3 3];
botfilter.maxHorizDist = inf;
botfilter.flagParams.type = 'all';
botfilter.flagParams.variable = 'slope';
botfilter.flagParams.threshold = 30;
botfilter.interpolate = 'yes';

% init
u = 0;
timer_start = now;

for itt = idx_fData(:)'
    
    % disp
    u = u+1;
    fprintf('Filtering bottom in file "%s" (%i/%i)...\n',fData_tot{itt}.ALLfilename{1},u,numel(idx_fData));
    fprintf('...Started at %s...',datestr(now));
    
    tic

    % filtering bottom
    fData_tot{itt} = CFF_filter_WC_bottom_detect(fData_tot{itt},...
        'method',botfilter.method,...
        'pingBeamWindowSize',botfilter.pingBeamWindowSize,...
        'maxHorizDist',botfilter.maxHorizDist,...
        'flagParams',botfilter.flagParams,...
        'interpolate',botfilter.interpolate);
    
    % disp
    fprintf(' done. Elapsed time: %f seconds.\n',toc);
    
end

% finalize
timer_end = now;
fprintf('Total time for filtering bottom: %f seconds (~%.2f minutes).\n\n',(timer_end-timer_start)*24*60*60,(timer_end-timer_start)*24*60);

end