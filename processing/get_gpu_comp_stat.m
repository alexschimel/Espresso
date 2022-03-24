function [gpu_comp,g] = get_gpu_comp_stat()
%GET_GPU_COMP_STAT  Test GPU presence and suitability for parallel compute
%
%   See also ESPRESSO.

%   Authors: Alex Schimel (NIWA, alexandre.schimel@niwa.co.nz) and Yoann
%   Ladroit (NIWA, yoann.ladroit@niwa.co.nz)
%   2017-2021; Last revision: 21-07-2021

% initialize negative results
gpu_comp = 0;
g = [];

% check if there is a licence for parallel computing
gpu_lic = license('checkout','Distrib_Computing_Toolbox');

if gpu_lic
    
    try
        g = gpuDevice; % get the default GPU device
    catch err
        % cant detect a GPU. Could be a CUDA driver error
        if contains((err.message),'CUDA')||contains((err.message),'graphics driver')
            fprintf('Your graphic card might support CUDA, but it looks like your graphic driver needs to be updated to the latest version from the NVidia Website.\nIf you do not have a CUDA enabled NVidia graphic card, please ignore this long message and let us know about it...\n')
        end
        return
    end
    
    % test GPU compatibility for the work ahead
    if str2double(g.ComputeCapability) >= 3 && ... % Computational capability of the CUDA device. Must meet required specification.
            g.SupportsDouble && ...                % Indicates if this device can support double precision operations.
            g.DriverVersion > 10 && ...            % The CUDA device driver version currently in use. Must meet required specification.
            g.DeviceSupported > 0 && ...           % Indicates if toolbox can use this device. Not all devices are supported; for example, if their ComputeCapability is insufficient, the toolbox cannot use them.
            g.ToolkitVersion >= 10.0               % Version of the CUDA toolkit used by the current release of MATLAB: R2017b is 8.0, R2018b is 9.1, R2019a is 10.0 etc.
        
        % all good, proceed
        gpu_comp = g.DeviceSupported;
    else
        % not good.
        gpu_comp = 0;
    end
    
end