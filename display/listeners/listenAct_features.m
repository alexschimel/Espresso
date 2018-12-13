function listenAct_features(~,~,main_figure)

disp_config=getappdata(main_figure,'disp_config');
map_tab_comp = getappdata(main_figure,'Map_tab');
features_h=findobj(map_tab_comp.map_axes    ,{'tag','feature'});

if isempty(features_h)
    return;
end

idx_act=ismember({features_h(:).UserData},disp_config.Act_features);
col=cell(1,numel(idx_act));
col(idx_act)={'r'};
col(~idx_act)={[0.1 0.1 0.1]};

for ii=1:numel(idx_act)
    if  strcmpi(features_h(ii).Type,'Line')
        features_h(ii).Color=col{ii};
        features_h(ii).MarkerFaceColor=col{ii};
    else
    features_h(ii).EdgeColor=col{ii};
    features_h(ii).FaceColor=col{ii};
    end
end

end