function delete_features_callback(~,~,main_figure,IDs)
disp_config=getappdata(main_figure,'disp_config');

features=getappdata(main_figure,'features');

if ~iscell(IDs)
    IDs={IDs};
end

if isempty(IDs)
    IDs=disp_config.Act_features;
end

if isempty(IDs)
    return;
end

if isempty(features)
    return;
end

features_id={features(:).Unique_ID};

idx_rem=ismember(features_id,IDs);

shp_files=dir(fullfile(whereisroot,'feature_files'));
idx_f_to_rem=contains({shp_files(:).name},features_id(idx_rem));

files_to_rem=cellfun(@(x) fullfile(whereisroot,'feature_files',x),{shp_files(idx_f_to_rem).name},'un',0);
cellfun(@delete,files_to_rem);

features(idx_rem)=[];
setappdata(main_figure,'features',features);
update_feature_list_tab(main_figure);
display_features(main_figure,{});
disp_config.Act_features={};

end