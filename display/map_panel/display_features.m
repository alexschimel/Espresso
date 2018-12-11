function   display_features(main_figure,IDs)

if ~iscell(IDs)
    IDs={};
end

disp_config=getappdata(main_figure,'disp_config');

map_tab_comp = getappdata(main_figure,'Map_tab');
features=getappdata(main_figure,'features');
if ~isempty(features)
    id_features={features(:).Unique_ID};
else
    id_features={};
end

ah=map_tab_comp.map_axes;

features_h=findobj(ah,{'tag','feature_tmp'});
delete(features_h);

features_h=findobj(ah,{'tag','feature','-or','tag','feature_text'});

  if~isempty(features_h)
        id_disp=get(features_h,'UserData');       
        id_rem = ~ismember(id_disp,id_features)|ismember(id_disp,IDs);
        delete(features_h(id_rem));
        features_h(id_rem)=[];      
  end
  
   if~isempty(features_h)
         id_disp=get(features_h,'UserData');             
   else
       id_disp={};
   end
        %id_features(ismember(id_features,id_disp))=[];
        idx_add=id_features(~contains(id_features,id_disp));
        idx_act=ismember(id_features,disp_config.Act_features);
        col=cell(1,numel(idx_act));
        col(idx_act)={'r'};
        col(~idx_act)={[0.1 0.1 0.1]};
        for id=1:numel(idx_add)
            if ~ismember(idx_add{id},id_disp)
                idf=find(strcmp(id_features,idx_add{id}));              
                [h_p,h_t]=features(idf).draw_feature(ah,col{id});
            end
        end

end