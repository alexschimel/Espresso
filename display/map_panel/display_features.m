function   display_features(main_figure,IDs)
%disp_config=getappdata(main_figure,'disp_config');

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
        id_rem = ~ismember(id_disp,id_features);
        features_h(id_rem)=[];
  end
  
   if~isempty(features_h)
         id_disp=get(features_h,'UserData');             
   else
       id_disp={};
   end
        %id_features(ismember(id_features,id_disp))=[];
        idx_add=id_features(contains(id_features,IDs));
        
        for id=1:numel(idx_add)
            if ~ismember(idx_add{id},id_disp)
                idf=find(strcmp(id_features,idx_add{id}));              
                [h_p,h_t]=features(idf).draw_feature(ah);
            end
        end

end