function loaded_files=get_loaded_files(main_figure)
fData=getappdata(main_figure,'fData');
loaded_files=cell(1,numel(fData));
for nF=1:numel(fData)
    [p_temp,f_temp,~]=fileparts(fData{nF}.ALLfilename{1});
    loaded_files{nF}=fullfile(p_temp,f_temp);
end