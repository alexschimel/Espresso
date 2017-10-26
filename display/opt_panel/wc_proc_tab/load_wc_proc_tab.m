function load_wc_proc_tab(main_figure,parent_tab_group)

switch parent_tab_group.Type
    case 'uitabgroup'
        wc_proc_tab_comp.wc_proc_tab=uitab(parent_tab_group,'Title','WC Proc.','Tag','wc_proc_tab','BackGroundColor','w');
    case 'figure'
        wc_proc_tab_comp.wc_proc_tab=parent_tab_group;
end

uicontrol(wc_proc_tab_comp.wc_proc_tab,'style','text',...
    'BackgroundColor','White','units','normalized','position',[0.05 0.9 0.4 0.05],'String','WC Process','fontweight','bold');
wc_proc_tab_comp.bot_filter=uicontrol(wc_proc_tab_comp.wc_proc_tab,'style','checkbox',...
    'BackgroundColor','White','units','normalized','position',[0.05 0.85 0.3 0.05],'String','Bottom Filtering','Value',1);
wc_proc_tab_comp.masking=uicontrol(wc_proc_tab_comp.wc_proc_tab,'style','checkbox',...
    'BackgroundColor','White','units','normalized','position',[0.05 0.8 0.3 0.05],'String','WC Masking','Value',1);

uicontrol(wc_proc_tab_comp.wc_proc_tab,'style','text',...
    'BackgroundColor','White','units','normalized','position',[0.15 0.75 0.3 0.05],'String',['Anglular (' char(hex2dec('00B0')) ')'],'HorizontalAlignment','left','fontangle','italic');
wc_proc_tab_comp.angle_mask=uicontrol(wc_proc_tab_comp.wc_proc_tab,'style','edit',...
    'BackgroundColor','White','units','normalized','position',[0.45 0.75 0.1 0.05],'String','Inf','Callback',{@check_fmt_box,5,Inf,90,'%.0f'});

uicontrol(wc_proc_tab_comp.wc_proc_tab,'style','text',...
    'BackgroundColor','White','units','normalized','position',[0.15 0.7 0.3 0.05],'String','R min (m)','HorizontalAlignment','left','fontangle','italic');
wc_proc_tab_comp.r_min=uicontrol(wc_proc_tab_comp.wc_proc_tab,'style','edit',...
    'BackgroundColor','White','units','normalized','position',[0.45 0.7 0.1 0.05],'String','5','Callback',{@check_fmt_box,0,Inf,5,'%.0f'},'fontangle','italic');

uicontrol(wc_proc_tab_comp.wc_proc_tab,'style','text',...
    'BackgroundColor','White','units','normalized','position',[0.15 0.65 0.3 0.05],'String','Above Bottom (m)','HorizontalAlignment','left');
wc_proc_tab_comp.r_bot=uicontrol(wc_proc_tab_comp.wc_proc_tab,'style','edit',...
    'BackgroundColor','White','units','normalized','position',[0.45 0.65 0.1 0.05],'String','5','Callback',{@check_fmt_box,0,Inf,5,'%.0f'});


wc_proc_tab_comp.sidelobe=uicontrol(wc_proc_tab_comp.wc_proc_tab,'style','checkbox',...
    'BackgroundColor','White','units','normalized','position',[0.05 0.6 0.4 0.05],'String','Sidelobe removal','Value',1);

uicontrol(wc_proc_tab_comp.wc_proc_tab,'style','text',...
    'BackgroundColor','White','units','normalized','position',[0.05 0.5 0.3 0.05],'String','Grid resolution (m)');

wc_proc_tab_comp.grid_val=uicontrol(wc_proc_tab_comp.wc_proc_tab,'style','edit',...
    'BackgroundColor','White','units','normalized','position',[0.35 0.5 0.1 0.05],'String','0.25','Callback',{@check_fmt_box,0.1,100,1,'%.2f'});



uicontrol(wc_proc_tab_comp.wc_proc_tab,'Style','pushbutton','units','normalized',...
    'pos',[0.7 0.01 0.2 0.08],...
    'String','Process WC',...
    'callback',{@process_wc_cback,main_figure});

setappdata(main_figure,'wc_proc_tab',wc_proc_tab_comp);

end



function process_wc_cback(~,~,main_figure)
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

res=str2double(get(wc_proc_tab_comp.grid_val,'String'));

angle_mask=str2double(get(wc_proc_tab_comp.angle_mask,'String'));
r_min=str2double(get(wc_proc_tab_comp.r_min,'String'));
r_bot=str2double(get(wc_proc_tab_comp.r_bot,'String'));

wc_proc_tab_comp.r_min
wc_proc_tab_comp.r_min
wc_proc_tab_comp.r_min
for i=idx_zoom(:)'
    fprintf('\nProcessing file %s\n',fData_tot{i}.MET_MATfilename{1})
    disp('Processing Watercolumn...');
    fData_tot{i} = CFF_process_watercolumn_v2(fData_tot{i});
    str_disp='original';
    
    disp('Detecting Bottom...');
    fData_tot{i} = CFF_process_WC_bottom_detect_v2(fData_tot{i});
    
    if wc_proc_tab_comp.bot_filter.Value>0
        disp('Filtering Bottom Detect...');
        fData_tot{i} = CFF_filter_WC_bottom_detect_v2(fData_tot{i},'method','flag','pingBeamWindowSize',[3 3],'maxHorizDist',inf,'flagParams',flagParams,'interpolate','yes');
    end
    
    if wc_proc_tab_comp.masking.Value>0
        disp('Creating Mask...');
        fData_tot{i} = CFF_mask_WC_data_v2(fData_tot{i},angle_mask,r_min,r_bot);
        str_disp_m='masked ';
    else
        str_disp_m='';
    end
    
    if wc_proc_tab_comp.sidelobe.Value>0
        disp('Filtering Sidelobe Artifacts...');
        fData_tot{i} = CFF_filter_WC_sidelobe_artifact_v2(fData_tot{i},3);
        str_disp='L1'; 
    end
    
    disp('Gridding Water Column...');
    fData_tot{i} = CFF_grid_watercolumn_v2_temp(fData_tot{i},[str_disp_m str_disp],res);
    
    
end

setappdata(main_figure,'fData',fData_tot);

update_map_tab(main_figure,1)

end
