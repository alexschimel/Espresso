function data_sub = CFF_sub_sample_mat(data,method,dx_sub,dy_sub)

filter_block = [min(dx_sub,size(data,1)) min(dy_sub,size(data,2))];

switch method
    case 'mean'
        filter_fun = @(block_struct) mean(block_struct.data(:));
    case 'min'
        filter_fun = @(block_struct) min(block_struct.data(:));
    case 'max'
        filter_fun = @(block_struct) max(block_struct.data(:));
    case 'med'
        filter_fun = @(block_struct) median(block_struct.data(:));
    otherwise
        filter_fun = @(block_struct) mean(block_struct.data(:));
end

data_sub = blockproc(data,filter_block,filter_fun);

end