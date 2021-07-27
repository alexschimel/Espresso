function listenAct_features(~,~,main_figure)
%LISTENACT_FEATURES  Callback function when Act_features is modified
%
%   See also ESPRESSO.

%   Authors: Yoann Ladroit (NIWA, yoann.ladroit@niwa.co.nz) and Alex
%   Schimel (NIWA, alexandre.schimel@niwa.co.nz)
%   2017-2021; Last revision: 27-07-2021

% get disp_config for active features
disp_config = getappdata(main_figure,'disp_config');

% get both map and stacked view axes
stacked_wc_tab_comp  = getappdata(main_figure,'stacked_wc_tab');
wc_tab_comp  = getappdata(main_figure,'wc_tab');
map_tab_comp = getappdata(main_figure,'Map_tab');
ah_tot = [map_tab_comp.map_axes stacked_wc_tab_comp.wc_axes wc_tab_comp.wc_axes];

for iax = 1:numel(ah_tot)
    
    ax = ah_tot(iax);
    
    % get features on axes and their labels
    features_h      = findobj(ax,{'tag','feature'});
    features_text_h = findobj(ax,{'tag','feature_text'});
    
    if isempty(features_h)
        return;
    end
    
    % colours: first for inactive, second for active
    col = {[0.1 0.1 0.1],'r'};
    
    for ii = 1:numel(features_h)
        
        % feature
        isAct = ismember(features_h(ii).UserData,disp_config.Act_features);
        switch features_h(ii).Type
            case 'line'
                features_h(ii).Color = col{isAct+1};
                features_h(ii).MarkerFaceColor = col{isAct+1};
            case 'polygon'
                features_h(ii).EdgeColor = col{isAct+1};
                features_h(ii).FaceColor = col{isAct+1};
        end
        
        % text
        isAct = ismember(features_text_h(ii).UserData,disp_config.Act_features);
        features_text_h(ii).Color = col{isAct+1};
        
    end
end

end