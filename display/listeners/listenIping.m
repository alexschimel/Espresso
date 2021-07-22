function listenIping(src,evt,main_figure)
%LISTENIPING  Callback function when current ping is modified
%
%   See also ESPRESSO.

%   Authors: Alex Schimel (NIWA, alexandre.schimel@niwa.co.nz) and Yoann
%   Ladroit (NIWA, yoann.ladroit@niwa.co.nz)
%   2017-2021; Last revision: 21-07-2021

fData_tot = getappdata(main_figure,'fData');

if isempty(fData_tot)
    return;
end

if ~isdeployed()
    disp('ListenIPing');
end

% update all lines on main map without changing zoom
update_poly = strcmpi(src.Name,'StackPingWidth')||strcmpi(src.Name,'StackAngularWidth');
up_wc = update_map_tab(main_figure,0,0,0,[],update_poly);

if up_wc>0
    % update wc and stacked views
    update_wc_tab(main_figure);
    update_stacked_wc_tab(main_figure,update_poly);
    display_features(main_figure,{},{'wc_tab' 'stacked_wc_tab'});
end

end