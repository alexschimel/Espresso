%% Function
function mem = CFF_memory_available(varargin)

if ispc
    
    mem_struct = memory;
    mem = mem_struct.MemAvailableAllArrays;
    
elseif ismac
    
    % get memory information from terminal
    [~,txt] = system('top -l 1 | grep PhysMem: | awk ''{print $6}''');
    if strcmp(txt(end-1),'M')
        mem = str2num(txt(1:end-2)).*1024^2;
    elseif strcmp(txt(end),'G')
        mem = str2num(txt(1:end-2)).*1024^3;
    else
        mem = str2num(txt(1:end-1));
    end
    
end