function [gpu_comp,g]=get_gpu_comp_stat()
    g=[];
    gpu_comp=0;
try
    gpu_comp=license('checkout','Distrib_Computing_Toolbox');
    if gpu_comp
        g = gpuDevice;
        if str2double(g.ComputeCapability)>=3&&g.SupportsDouble&&g.DriverVersion>7&&g.DeviceSupported>0&&g.ToolkitVersion>=9.1
            gpu_comp=g.DeviceSupported;
        else
            gpu_comp=0;
        end
    end   
catch err
    if contains((err.message),'CUDA')||contains((err.message),'graphics driver')
        fprintf('Your graphic card might support CUDA, but it looks like your graphic driver needs to be updated to the latest version from the NVidia Website.\nIf you do not have a CUDA enabled NVidia graphic card, please ignore this long message and let us know about it...\n')
    end
end

end
