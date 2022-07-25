function mem = CFF_memory_available(varargin)
%CFF_MEMORY_AVAILABLE  Memory available guaranteed to hold data, in bytes
%
%   See also GET_GPU_COMP_STAT

%   Authors: Alex Schimel (NGU, alexandre.schimel@ngu.no) and Yoann Ladroit
%   (NIWA, yoann.ladroit@niwa.co.nz) 
%   2017-2022; Last revision: 22-07-2022

if ispc
    % on pc, just use the MATLAB function 'memory'
    mem_struct = memory;
    mem = mem_struct.MemAvailableAllArrays;
    % Total memory available to hold data. The amount of memory available
    % is guaranteed to be at least as large as this value. This field's
    % value is the smaller of these two values: 1) The total available
    % MATLAB virtual address space. 2) The total available system memory.
    
elseif ismac    
    % on mac, get memory information from terminal
    [~,txt] = system('top -l 1 | grep PhysMem: | awk ''{print $6}''');
    if strcmp(txt(end-1),'M')
        mem = str2num(txt(1:end-2)).*1024^2;
    elseif strcmp(txt(end),'G')
        mem = str2num(txt(1:end-2)).*1024^3;
    else
        mem = str2num(txt(1:end-1));
    end
    
end