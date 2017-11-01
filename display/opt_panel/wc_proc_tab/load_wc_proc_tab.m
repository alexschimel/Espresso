function load_wc_proc_tab(main_figure,parent_tab_group)

switch parent_tab_group.Type
    case 'uitabgroup'
        wc_proc_tab_comp.wc_proc_tab=uitab(parent_tab_group,'Title','WC Proc.','Tag','wc_proc_tab','BackGroundColor','w');
    case 'figure'
        wc_proc_tab_comp.wc_proc_tab=parent_tab_group;
end
disp_config=getappdata(main_figure,'disp_config');

uicontrol(wc_proc_tab_comp.wc_proc_tab,'style','text',...
    'BackgroundColor','White','units','normalized','position',[0.05 0.9 0.4 0.05],'String','WC Process','fontweight','bold');
wc_proc_tab_comp.bot_filter=uicontrol(wc_proc_tab_comp.wc_proc_tab,'style','checkbox',...
    'BackgroundColor','White','units','normalized','position',[0.05 0.85 0.3 0.05],'String','Bottom Filtering','Value',1);
wc_proc_tab_comp.masking=uicontrol(wc_proc_tab_comp.wc_proc_tab,'style','checkbox',...
    'BackgroundColor','White','units','normalized','position',[0.05 0.8 0.3 0.05],'String','WC Masking','Value',1);

text_angle=uicontrol(wc_proc_tab_comp.wc_proc_tab,'style','text',...
    'BackgroundColor','White','units','normalized','position',[0.15 0.75 0.3 0.05],'String',['Anglular (' char(hex2dec('00B0')) ')']);
wc_proc_tab_comp.angle_mask=uicontrol(wc_proc_tab_comp.wc_proc_tab,'style','edit',...
    'BackgroundColor','White','units','normalized','position',[0.45 0.75 0.1 0.05],'String','Inf','Callback',{@check_fmt_box,5,Inf,90,'%.0f'});

text_rmin=uicontrol(wc_proc_tab_comp.wc_proc_tab,'style','text',...
    'BackgroundColor','White','units','normalized','position',[0.15 0.7 0.3 0.05],'String','R min (m)','HorizontalAlignment','left');
wc_proc_tab_comp.r_min=uicontrol(wc_proc_tab_comp.wc_proc_tab,'style','edit',...
    'BackgroundColor','White','units','normalized','position',[0.45 0.7 0.1 0.05],'String','1','Callback',{@check_fmt_box,0,Inf,1,'%.0f'});

text_bot=uicontrol(wc_proc_tab_comp.wc_proc_tab,'style','text',...
    'BackgroundColor','White','units','normalized','position',[0.15 0.65 0.3 0.05],'String','Above Bottom (m)');
wc_proc_tab_comp.r_bot=uicontrol(wc_proc_tab_comp.wc_proc_tab,'style','edit',...
    'BackgroundColor','White','units','normalized','position',[0.45 0.65 0.1 0.05],'String','1','Callback',{@check_fmt_box,-Inf,Inf,1,'%.0f'});

set([text_angle text_rmin text_bot],'HorizontalAlignment','left','fontangle','italic');

wc_proc_tab_comp.sidelobe=uicontrol(wc_proc_tab_comp.wc_proc_tab,'style','checkbox',...
    'BackgroundColor','White','units','normalized','position',[0.05 0.6 0.4 0.05],'String','Sidelobe removal','Value',1);

uicontrol(wc_proc_tab_comp.wc_proc_tab,'Style','pushbutton','units','normalized',...
    'pos',[0.2 0.51 0.25 0.08],...
    'String','Process WC',...
    'callback',{@compute_masks_cback,main_figure});


uicontrol(wc_proc_tab_comp.wc_proc_tab,'style','text',...
    'BackgroundColor','White','units','normalized','position',[0.05 0.35 0.3 0.05],'String','Grid resolution (m)');
uicontrol(wc_proc_tab_comp.wc_proc_tab,'style','text',...
    'BackgroundColor','White','units','normalized','position',[0.35 0.45 0.1 0.05],'String','Horz');
uicontrol(wc_proc_tab_comp.wc_proc_tab,'style','text',...
    'BackgroundColor','White','units','normalized','position',[0.45 0.45 0.1 0.05],'String','Vert');


wc_proc_tab_comp.grid_val=uicontrol(wc_proc_tab_comp.wc_proc_tab,'style','edit',...
    'BackgroundColor','White','units','normalized','position',[0.35 0.35 0.1 0.05],'String','0.25','Callback',{@check_fmt_box,0.1,100,1,'%.2f'});
wc_proc_tab_comp.vert_grid_val=uicontrol(wc_proc_tab_comp.wc_proc_tab,'style','edit',...
    'BackgroundColor','White','units','normalized','position',[0.45 0.35 0.1 0.05],'String','1','Callback',{@check_fmt_box,0.1,100,1,'%.2f'});

wc_proc_tab_comp.dim_grid=uicontrol(wc_proc_tab_comp.wc_proc_tab,'style','popup','Units','normalized','position',[0.6 0.35 0.15 0.05],...
    'String',{'2D' '3D'},'Value',1);

uicontrol(wc_proc_tab_comp.wc_proc_tab,'Style','pushbutton','units','normalized',...
    'pos',[0.2 0.26 0.25 0.08],...
    'String','Grid',...
    'callback',{@re_grid_cback,main_figure});

set([wc_proc_tab_comp.masking wc_proc_tab_comp.bot_filter wc_proc_tab_comp.sidelobe],'callback',{@update_str_disp_cback,main_figure})


cax=disp_config.get_cax();
uicontrol(wc_proc_tab_comp.wc_proc_tab,'style','text',...
    'BackgroundColor','White','units','normalized','position',[0.05 0.1 0.3 0.05],'String','CLim Map (dB)');
wc_proc_tab_comp.clim_min=uicontrol(wc_proc_tab_comp.wc_proc_tab,'style','edit',...
    'BackgroundColor','White','units','normalized','position',[0.35 0.1 0.1 0.05],'String',num2str(cax(1)),'Callback',{@change_cax_cback,main_figure});
wc_proc_tab_comp.clim_max=uicontrol(wc_proc_tab_comp.wc_proc_tab,'style','edit',...
    'BackgroundColor','White','units','normalized','position',[0.45 0.1 0.1 0.05],'String',num2str(cax(2)),'Callback',{@change_cax_cback,main_figure});




cax=disp_config.Cax_wc;
uicontrol(wc_proc_tab_comp.wc_proc_tab,'style','text',...
    'BackgroundColor','White','units','normalized','position',[0.05 0.15 0.3 0.05],'String','CLim WC (dB)');

wc_proc_tab_comp.clim_min_wc=uicontrol(wc_proc_tab_comp.wc_proc_tab,'style','edit',...
    'BackgroundColor','White','units','normalized','position',[0.35 0.15 0.1 0.05],'String',num2str(cax(1)),'Callback',{@change_wc_cax_cback,main_figure});
wc_proc_tab_comp.clim_max_wc=uicontrol(wc_proc_tab_comp.wc_proc_tab,'style','edit',...
    'BackgroundColor','White','units','normalized','position',[0.45 0.15 0.1 0.05],'String',num2str(cax(2)),'Callback',{@change_wc_cax_cback,main_figure});


% 
% uicontrol(wc_proc_tab_comp.wc_proc_tab,'Style','pushbutton','units','normalized',...
%     'pos',[0.2 0.01 0.25 0.08],...
%     'String','Process WC',...
%     'callback',{@process_wc_cback,main_figure});



wc_proc_tab_comp.str_disp='original';
setappdata(main_figure,'wc_proc_tab',wc_proc_tab_comp);
update_str_disp_cback([],[],main_figure)
end


function change_wc_cax_cback(src,evt,main_figure)
wc_proc_tab_comp=getappdata(main_figure,'wc_proc_tab');
disp_config=getappdata(main_figure,'disp_config');

cax=disp_config.Cax_wc;
check_fmt_box(wc_proc_tab_comp.clim_min_wc,[],-200,100,cax(1),'%.0f');
check_fmt_box(wc_proc_tab_comp.clim_max_wc,[],-200,100,cax(2),'%.0f');

cax_min=str2double(wc_proc_tab_comp.clim_min_wc.String);
cax_max=str2double(wc_proc_tab_comp.clim_max_wc.String);

if cax_min<cax_max
    disp_config.Cax_wc=[cax_min cax_max];
    
else
    wc_proc_tab_comp.clim_min_wc.String=num2str(cax(1));
    wc_proc_tab_comp.clim_max_wc.String=num2str(cax(2));
    disp_config.Cax_wc=cax;
end

end


function change_cax_cback(src,evt,main_figure)
wc_proc_tab_comp=getappdata(main_figure,'wc_proc_tab');
disp_config=getappdata(main_figure,'disp_config');

cax=disp_config.get_cax();
check_fmt_box(wc_proc_tab_comp.clim_min,[],-200,100,cax(1),'%.0f');
check_fmt_box(wc_proc_tab_comp.clim_max,[],-200,100,cax(2),'%.0f');

cax_min=str2double(wc_proc_tab_comp.clim_min.String);
cax_max=str2double(wc_proc_tab_comp.clim_max.String);

if cax_min<cax_max
    disp_config.set_cax([cax_min cax_max]);
else
    wc_proc_tab_comp.clim_min.String=num2str(cax(1));
    wc_proc_tab_comp.clim_max.String=num2str(cax(2));
    disp_config.set_cax(cax);
end


end

function re_grid_cback(~,~,main_figure)
fData_tot=getappdata(main_figure,'fData');
if isempty(fData_tot)
    return;
end
fdata_tab_comp=getappdata(main_figure,'fdata_tab');

idx_zoom=find(cell2mat(fdata_tab_comp.table.Data(:,end-1)));

if isempty(idx_zoom)
    disp('No lines selected');
    return;
end

wc_proc_tab_comp=getappdata(main_figure,'wc_proc_tab');

res=str2double(get(wc_proc_tab_comp.grid_val,'String'));
vert_res=str2double(get(wc_proc_tab_comp.vert_grid_val,'String'));
tic
for i=idx_zoom(:)'
        if ~isfield(fData_tot{i},'X_SBP_L1')||~isfield(fData_tot{i},'X_SBP_Mask')
            fprintf('\nMasks for file %s has never been processed.\n',fData_tot{i}.MET_MATfilename{1})
        else
            disp('Gridding Water Column...');
            fData_tot{i} = CFF_grid_watercolumn_v2_temp(fData_tot{i},wc_proc_tab_comp.str_disp,res,vert_res,wc_proc_tab_comp.dim_grid.String{wc_proc_tab_comp.dim_grid.Value});
        end
end
disp('Done');
toc
setappdata(main_figure,'fData',fData_tot);

disp_config=getappdata(main_figure,'disp_config');

disp_config.Fdata_idx=idx_zoom(end);

update_map_tab(main_figure,1,0);

end

function update_str_disp_cback(~,~,main_figure)
wc_proc_tab_comp=getappdata(main_figure,'wc_proc_tab');

str_disp='original';

if wc_proc_tab_comp.masking.Value>0
    str_disp_m='masked ';
else
    str_disp_m='';
end

if wc_proc_tab_comp.sidelobe.Value>0
    str_disp='L1';
end

wc_proc_tab_comp.str_disp=[str_disp_m str_disp];

setappdata(main_figure,'wc_proc_tab',wc_proc_tab_comp);

end
% 
% function process_wc_cback(~,~,main_figure)
% fData_tot=getappdata(main_figure,'fData');
% if isempty(fData_tot)
%     return;
% end
% fdata_tab_comp=getappdata(main_figure,'fdata_tab');
% 
% idx_zoom=find(cell2mat(fdata_tab_comp.table.Data(:,end-1)));
% 
% if isempty(idx_zoom)
%     disp('No lines selected');
%     return;
% end
% 
% for i=idx_zoom(:)'
%     if ~isfield(fData_tot{i},'X_SBP_sampleEasting')
%         fprintf('\nProcessing file %s\n',fData_tot{i}.MET_MATfilename{1})
%         disp('Processing Watercolumn...');
%         fData_tot{i} = CFF_process_watercolumn_v2(fData_tot{i});
%         disp('Detecting Bottom...');
%         fData_tot{i} = CFF_process_WC_bottom_detect_v2(fData_tot{i});
%     else
%         fprintf('\nWater Column for file %s already processed.\n',fData_tot{i}.MET_MATfilename{1})
%     end
% end
% disp('Done');
% 
% setappdata(main_figure,'fData',fData_tot);
% 
% disp_config=getappdata(main_figure,'disp_config');
% 
% disp_config.Fdata_idx=idx_zoom(end);
% 
% update_wc_tab(main_figure);
% 
% end


function compute_masks_cback(~,~,main_figure)
fData_tot=getappdata(main_figure,'fData');
if isempty(fData_tot)
    return;
end
fdata_tab_comp=getappdata(main_figure,'fdata_tab');

idx_zoom=find(cell2mat(fdata_tab_comp.table.Data(:,end-1)));

if isempty(idx_zoom)
    disp('No lines selected');
    return;
end

wc_proc_tab_comp=getappdata(main_figure,'wc_proc_tab');

flagParams.type = 'all';%''
flagParams.variable = 'slope';
flagParams.threshold = 30;


angle_mask=str2double(get(wc_proc_tab_comp.angle_mask,'String'));
r_min=str2double(get(wc_proc_tab_comp.r_min,'String'));
r_bot=str2double(get(wc_proc_tab_comp.r_bot,'String'));

for i=idx_zoom(:)'
    

        disp('Filtering Bottom Detect...');
        fData_tot{i} = CFF_filter_WC_bottom_detect_v2(fData_tot{i},...
            'method','flag','pingBeamWindowSize',[3 3],'maxHorizDist',inf,'flagParams',flagParams,'interpolate','yes');
        
        disp('Creating Mask...');
        fData_tot{i} = CFF_mask_WC_data_v2(fData_tot{i},angle_mask,r_min,-r_bot);
        
        disp('Filtering Sidelobe Artifacts...');
        fData_tot{i} = CFF_filter_WC_sidelobe_artifact_v2(fData_tot{i},2);
    
end
disp('Done');

setappdata(main_figure,'fData',fData_tot);

disp_config=getappdata(main_figure,'disp_config');

disp_config.Fdata_idx=idx_zoom(end);
update_wc_tab(main_figure);


end
