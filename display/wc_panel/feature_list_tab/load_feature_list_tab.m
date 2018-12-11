
function load_feature_list_tab(main_figure,parent_tab_group)

%disp_config = getappdata(main_figure,'disp_config');

switch parent_tab_group.Type
    case 'uitabgroup'
        feature_list_tab_comp.feature_list_tab = uitab(parent_tab_group,'Title','Feature List','Tag','feature_list_tab','BackGroundColor','w');
        tab_menu = uicontextmenu(ancestor(feature_list_tab_comp.feature_list_tab,'figure'));
        uimenu(tab_menu,'Label','Undock to External Window','Callback',{@undock_tab_callback,main_figure,'feature_list','new_fig'});
        feature_list_tab_comp.feature_list_tab.UIContextMenu = tab_menu;
    case 'figure'
        feature_list_tab_comp.feature_list_tab = parent_tab_group;
end
% pos = getpixelposition(feature_list_tab_comp.wc_tab);


columnname = {'ID','Tag','Type','Shape','Depth Min','Depth Max','Unique_ID'};
columnformat = {'numeric','char',init_feature_type,{'Point','Polygon'},'numeric','numeric','char'};

feature_list_tab_comp.table = uitable('Parent', feature_list_tab_comp.feature_list_tab,...
    'Data', [],...
    'ColumnName', columnname,...
    'ColumnFormat', columnformat,...
    'ColumnEditable', [false true true false true true false],...
    'Units','Normalized','Position',[0 0 1 1],...
    'RowName',[]);

pos_t = getpixelposition(feature_list_tab_comp.table);

set(feature_list_tab_comp.table,'ColumnWidth',...
    num2cell(pos_t(3)*[1/10 2/10 2/10 2/10 1.5/10 1.5/10 0]));

set(feature_list_tab_comp.table,'CellEditCallback',{@edit_features_callback,main_figure});
set(feature_list_tab_comp.table,'CellSelectionCallback',{@activate_features_callback,main_figure});
set(feature_list_tab_comp.feature_list_tab,'SizeChangedFcn',{@resize_table,feature_list_tab_comp.table});
set(feature_list_tab_comp.table,'KeyPressFcn','');


rc_menu = uicontextmenu(ancestor(parent_tab_group,'figure'));
feature_list_tab_comp.table.UIContextMenu =rc_menu;
str_delete='<HTML><center><FONT color="REd"><b>Delete Features(s)</b></Font> ';

uimenu(rc_menu,'Label',str_delete,'Callback',{@delete_features_callback,main_figure,{}});

setappdata(main_figure,'feature_list_tab',feature_list_tab_comp);
features = getappdata(main_figure,'features');

if isempty(features)
    return;
end

update_feature_list_tab(main_figure);

end

function edit_features_callback(src,evt,main_figure)
features=getappdata(main_figure,'features');
if isempty(features)
    return;
end

if isempty(evt.Indices)
    selected_features={};
else
    selected_features=src.Data(evt.Indices(:,1),end);
    idx_data=evt.Indices(:,2);
end
nData=evt.NewData;
idx_feature=contains({features(:).Unique_ID},selected_features);

switch src.ColumnName{idx_data}
    case 'Type'
        features(idx_feature).Type=nData;
    case 'Tag'
        features(idx_feature).Tag=nData;
    case 'Depth Min'
        if isnan(nData)
            nData=evt.PreviousData;
            src.Data(evt.Indices(:,1),evt.Indices(:,1))=evt.PreviousData;
        end
        features(idx_feature).Depth_min=nData;
    case 'Depth Max'
        if isnan(nData)
            nData=evt.PreviousData;
            src.Data(evt.Indices(:,1),evt.Indices(:,1))=evt.PreviousData;
        end
        features(idx_feature).Depth_max=nData;
end
setappdata(main_figure,'features',features);

display_features(main_figure,selected_features);

end



function activate_features_callback(src,evt,main_figure)

if isempty(evt.Indices)
    selected_features={};
else
    selected_features=src.Data(evt.Indices(:,1),end);
end

disp_config = getappdata(main_figure,'disp_config');

disp_config.Act_features=selected_features;

end

