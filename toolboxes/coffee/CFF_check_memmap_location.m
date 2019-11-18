function [fData_temp,dirchange_flag]=CFF_check_memmap_location(fData_temp,fields,folder_for_converted_data)
dirchange_flag=0;
for ifi=1:numel(fields)
    
    if isfield(fData_temp,fields{ifi})
        if ~iscell(fData_temp.(fields{ifi}))
            fData_temp.(fields{ifi})={fData_temp.(fields{ifi})};
        end
        for ic=1:numel(fData_temp.(fields{ifi}))
            [filepath_in_fData,name,ext] = fileparts(fData_temp.(fields{ifi}){ic}.Filename);
            if ~strcmp(filepath_in_fData,folder_for_converted_data)
                fData_temp.(fields{ifi}){ic}.Filename = fullfile(folder_for_converted_data,[name ext]);
                dirchange_flag=1;
            end
        end
    end
    
end

end