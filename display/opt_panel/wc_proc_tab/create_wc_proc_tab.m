function create_wc_proc_tab(main_figure,parent_tab_group)
%CREATE_WC_PROC_TAB  Creates wc_proc tab in Espresso Control panel
%
%    Also has callback functions for when interacting with the tab's
%    contents.
%
%    *DVPT NOTES*
%     * XXX2: check that if asking for "process", redo the "process" from
%     scratch
%
%   See also INITIALIZE_DISPLAY, ESPRESSO.

%   Copyright 2017-2021 Alexandre Schimel, Yoann Ladroit, NIWA
%   Licensed under MIT. Details on https://github.com/alexschimel/Espresso/


%% create tab variable
switch parent_tab_group.Type
    case 'uitabgroup'
        wc_proc_tab_comp.wc_proc_tab = uitab(parent_tab_group,'Title','Data processing','Tag','wc_proc_tab','BackGroundColor','w');
    case 'figure'
        wc_proc_tab_comp.wc_proc_tab = parent_tab_group;
end


%% processing section

dh = 0.13;
h = (1-(1:7)*dh-dh/2);

backgrColor = 'white'; % set to 'blue' for debugging locations

% "Data Processing" panel
proc_gr = uibuttongroup(wc_proc_tab_comp.wc_proc_tab,'Units','Norm','Position',[0.02 0.51 0.96 0.47],'BackgroundColor','white','Title','');
wc_proc_tab_comp.proc_bool = uicontrol(wc_proc_tab_comp.wc_proc_tab,'Style','checkbox','String','Data Processing',...
    'BackgroundColor',backgrColor,...
    'HorizontalAlignment','left',...
    'units','normalized',...
    'Fontsize',8,...
    'pos',[0.02 0.51+0.47-0.03 0.235 0.05],...
    'Value',1,...
    'tooltipstring','Applies data processing (as parameterized in this section) when the "Process" button is pressed');

% "Filter bottom" checkbox
wc_proc_tab_comp.bot_filtering = uicontrol(proc_gr,'Style','checkbox','String','Filter bottom detection',...
    'BackgroundColor',backgrColor,...
    'HorizontalAlignment','left',...
    'units','normalized',...
    'Fontsize',8,...
    'pos',[0.01 h(1) 0.5 dh],...
    'Value',1,...
    'tooltipstring','Applies light median filter to the bottom detect in each ping');

% "Grid bathy & BS" checkbox and field
wc_proc_tab_comp.bs_grid_bool = uicontrol(proc_gr,'style','checkbox','String','Grid bathy & BS. Res (m):',...
    'BackgroundColor',backgrColor,...
    'units','normalized',...
    'Fontsize',8,...
    'position',[0.35 h(1) 0.4 dh],...
    'Value',1,...
    'tooltipstring','Horizontal gridding resolution for bathymetry and backscatter data');
wc_proc_tab_comp.bs_grid_res = uicontrol(proc_gr,'style','edit','String','5',...
    'BackgroundColor',backgrColor,...
    'units','normalized',...
    'Fontsize',8,...
    'position',[0.705 h(1) 0.1 dh],...
    'Callback',{@check_fmt_box,0.1,500,5,'%.2f'},...
    'tooltipstring','Min: 0.1. Max: 500.');

% "mask selected data" checkbox
wc_proc_tab_comp.masking = uicontrol(proc_gr,'style','checkbox','String','Mask selected data',...
    'BackgroundColor',backgrColor,...
    'units','normalized',...
    'Fontsize',8,...
    'position',[0.01 h(2) 0.5 dh],...
    'Value',1,...
    'tooltipstring','Removes data as per parameters in this section');

% mask 1 - outer beams selection
t1 = uicontrol(proc_gr,'style','text','String',['Outer Beams (' char(hex2dec('00B0')) '): ' char(hex2dec('00B1'))],...
    'BackgroundColor',backgrColor,...
    'units','normalized',...
    'Fontsize',8,...
    'HorizontalAlignment','left',...
    'fontangle','italic',...
    'position',[0.05 h(3) 0.3 dh],...
    'tooltipstring','Removes data from outer beams beyond angle indicated');
jh = findjobj(t1); jh.setVerticalAlignment(javax.swing.JLabel.CENTER); % center text
wc_proc_tab_comp.angle_mask = uicontrol(proc_gr,'style','edit','String','Inf',...
    'BackgroundColor',backgrColor,...
    'units','normalized',...
    'Fontsize',8,...
    'position',[0.3 h(3) 0.1 dh],...
    'Callback',{@check_fmt_box,5,Inf,90,'%.0f'},...
    'tooltipstring','Min: 5. Max: Inf.');

% mask 2 - close range selection
t2 = uicontrol(proc_gr,'style','text','String','Close Range (m):',...
    'BackgroundColor',backgrColor,...
    'units','normalized',...
    'Fontsize',8,...
    'HorizontalAlignment','left',...
    'fontangle','italic',...
    'position',[0.05 h(4) 0.3 dh],...
    'HorizontalAlignment','left',...
    'tooltipstring','Removes data closest to sonar within range indicated');
jh = findjobj(t2); jh.setVerticalAlignment(javax.swing.JLabel.CENTER); % center text
wc_proc_tab_comp.r_min = uicontrol(proc_gr,'style','edit','String','1',...
    'BackgroundColor',backgrColor,...
    'units','normalized',...
    'Fontsize',8,...
    'position',[0.3 h(4) 0.1 dh],...
    'Callback',{@check_fmt_box,0,Inf,1,'%.1f'},...
    'tooltipstring','Min: 0. Max: Inf.');

% mask 3 - above bottom selection
t3 = uicontrol(proc_gr,'style','text','String','Above Bottom (m):',...
    'BackgroundColor',backgrColor,...
    'units','normalized',...
    'Fontsize',8,...
    'HorizontalAlignment','left',...
    'fontangle','italic',...
    'position',[0.5 h(3) 0.3 dh],...
    'tooltipstring','Removes bottom echo footprint and data below it');
jh = findjobj(t3); jh.setVerticalAlignment(javax.swing.JLabel.CENTER); % center text
wc_proc_tab_comp.r_bot = uicontrol(proc_gr,'style','edit','String','0',...
    'BackgroundColor',backgrColor,...
    'units','normalized',...
    'Fontsize',8,...
    'position',[0.75 h(3) 0.1 dh],...
    'Callback',{@check_fmt_box,-Inf,Inf,1,'%.1f'},...
    'tooltipstring','0: removes bottom echo footprint and data below it. Negative: removes below bottom echo footprint (min: -Inf). Positive: remove more than bottom echo footprint (max: +Inf)');

% mask 4 - bad pings selection
t4 = uicontrol(proc_gr,'style','text','String','Bad pings (%):',...
    'BackgroundColor',backgrColor,...
    'units','normalized',...
    'Fontsize',8,...
    'fontangle','italic',...
    'HorizontalAlignment','left',...
    'position',[0.5 h(4) 0.3 dh],...
    'tooltipstring','Removes pings presenting bad bottom detect in excess of indicated percentage');
jh = findjobj(t4); jh.setVerticalAlignment(javax.swing.JLabel.CENTER); % center text
wc_proc_tab_comp.mask_badpings = uicontrol(proc_gr,'style','edit','String','100',...
    'BackgroundColor',backgrColor,...
    'units','normalized',...
    'Fontsize',8,...
    'position',[0.75 h(4) 0.1 dh],...
    'Callback',{@check_fmt_box,0,100,100,'%.1f'},...
    'tooltipstring','Low value: aggressively removing pings if has few bad bottom detect (Min: 0). High value: only removing pings if most bottom detects failed (Max: 100).');

% mask 5 - beyond min. slant range
wc_proc_tab_comp.mask_minslantrange = uicontrol(proc_gr,'style','checkbox','String','Mask beyond min. slant range',...
    'BackgroundColor',backgrColor,...
    'units','normalized',...
    'Fontsize',8,...
    'fontangle','italic',...
    'position',[0.05 h(5) 0.5 dh],...
    'Value',0,...
    'tooltipstring','Removes data beyond range of closest bottom detect return');

% "Radiometric correction" checkbox and drop-down menu
wc_proc_tab_comp.radiomcorr = uicontrol(proc_gr,'style','checkbox','String','Radiometric correction. Output:',...
    'BackgroundColor',backgrColor,...
    'units','normalized',...
    'Fontsize',8,...
    'position',[0.01 h(6) 0.5 dh],...
    'Value',1,...
    'tooltipstring','Applies radiometric (dB level) correction');
wc_proc_tab_comp.radiomcorr_output = uicontrol(proc_gr,'style','popup','String',{'Sv' 'Sa' 'TS'},...
    'Units','normalized',...
    'Fontsize',8,...
    'position',[0.45 h(6) 0.1 dh],...
    'Value',1,...
    'tooltipstring','Level output');

% "filter sidelobe artifact" checkbox
wc_proc_tab_comp.sidelobe = uicontrol(proc_gr,'style','checkbox','String','Filter sidelobe artefacts',...
    'BackgroundColor',backgrColor,...
    'units','normalized',...
    'Fontsize',8,...
    'position',[0.01 h(7) 0.40 dh],...
    'Value',1,...
    'tooltipstring','Applies sidelobe artifact filtering algorithm');



%% gridding section

dh = 0.18;
h  = (1-(1:10)*dh-dh/2);

% top "gridding" checkbox
grid_gr = uibuttongroup(wc_proc_tab_comp.wc_proc_tab,'Units','Norm','Position',[0.02 0.11 0.96 0.38],'BackgroundColor','white','Title','');
wc_proc_tab_comp.grid_bool = uicontrol(wc_proc_tab_comp.wc_proc_tab,'Style','checkbox','String','Water-column Gridding',...
    'BackgroundColor',backgrColor,...
    'HorizontalAlignment','left',...
    'units','normalized',...
    'Fontsize',8,...
    'pos',[0.02 0.11+0.38-0.03 0.315 0.05],...
    'Value',1,...
    'tooltipstring','Applies gridding to water-column data (as parameterized in this section) when the "Process" button is pressed');

% Horizontal resolution
uicontrol(grid_gr,'style','text','String','Horiz. res. (m):',...
    'BackgroundColor',backgrColor,...
    'units','normalized',...
    'position',[0.05 h(1) 0.25 dh],...
    'tooltipstring','Horizontal gridding resolution for water-column data');
wc_proc_tab_comp.grid_val = uicontrol(grid_gr,'style','edit',...
    'BackgroundColor',backgrColor,...
    'units','normalized',...
    'position',[0.4 h(1) 0.1 dh],...
    'String','0.25',...
    'Callback',{@check_fmt_box,0.1,100,1,'%.2f'},...
    'tooltipstring','Min: 0.1. Max: 100.');

% gridding vertical reference
uicontrol(grid_gr,'style','text','String','Reference: ','tooltipstring','reference for gridding',....
    'BackgroundColor',backgrColor,...
    'units','normalized',...
    'position',[0.5 h(1) 0.25 dh],...
    'tooltipstring','Gridding vertical reference');
wc_proc_tab_comp.grdlim_var = uicontrol(grid_gr,'style','popup','String',{'Sonar' 'Bottom'},...
    'Units','normalized',...
    'position',[0.75 h(1) 0.2 dh],...
    'Value',1,...
    'tooltipstring','Sonar: data are in depth below sonar. Bottom: data are in height above bottom');

% sub-sampling
uicontrol(grid_gr,'style','text','String','Sub-sampling: ','tooltipstring','in samples/beams',...
    'BackgroundColor',backgrColor,...
    'units','normalized',...
    'position',[0.05 h(2) 0.25 dh],...
    'tooltipstring','Decimation factor in samples and beams (use 1 for no decimation)');
wc_proc_tab_comp.dr = uicontrol(grid_gr,'style','edit','String','2',...
    'BackgroundColor',backgrColor,...
    'units','normalized',...
    'position',[0.3 h(2) 0.1 dh],...
    'Callback',{@check_fmt_box,1,10,4,'%.0f'},...
    'tooltipstring','in samples');
wc_proc_tab_comp.db = uicontrol(grid_gr,'style','edit','String','2',...
    'BackgroundColor',backgrColor,...
    'units','normalized',...
    'position',[0.4 h(2) 0.1 dh],...
    'Callback',{@check_fmt_box,1,10,2,'%.0f'},...
    'tooltipstring','in beams');

% data to be gridded
uicontrol(grid_gr,'style','text','String','Data to grid:',...
    'BackgroundColor',backgrColor,...
    'units','normalized',...
    'position',[0.55 h(2) 0.2 dh],...
    'tooltipstring','Source of water-column data to be gridded');
wc_proc_tab_comp.data_type = uicontrol(grid_gr,'style','popup','String',{'Processed' 'Original'},'tooltipstring','data to grid',...
    'Units','normalized',...
    'position',[0.75 h(2) 0.2 dh],...
    'Value',1,...
    'tooltipstring','Original: data without processing applied (except radiometric corrections). Processed: data after processing applied');

% 2D gridding radiobutton and parameters
h = h-dh/2;
wc_proc_tab_comp.grid_2d = uicontrol(grid_gr,'style','radiobutton','String','2D',...
    'BackgroundColor',backgrColor,...
    'units','normalized',...
    'position',[0.05 h(3) 0.1 dh],...
    'tooltipstring','2-D gridding - specify vertical extents of data to be gridded as a distance from vertical reference (depth below sonar, or height above bottom)');
uicontrol(grid_gr,'style','text','String','Grid only:',...
    'BackgroundColor',backgrColor,...
    'units','normalized',...
    'position',[0.15 h(3) 0.25 dh],...
    'tooltipstring','(2-D gridding only)');
wc_proc_tab_comp.grdlim_mode = uicontrol(grid_gr,'style','popup','String',{'between' 'outside of'},...
    'Units','normalized',...
    'position',[0.40 h(3) 0.2 dh],...
    'Value',1,...
    'tooltipstring','Grid data between vertical extents indicated, or all data except between vertical extents indicated (2-D gridding only)');
wc_proc_tab_comp.grdlim_mindist = uicontrol(grid_gr,'style','edit',...
    'BackgroundColor',backgrColor,...
    'units','normalized',...
    'position',[0.61 h(3) 0.1 dh],...
    'String','0',...
    'Callback',{@change_grdlim_mindist_cback,main_figure});
uicontrol(grid_gr,'style','text','String','&',...
    'BackgroundColor',backgrColor,...
    'units','normalized',...
    'position',[0.71 h(3) 0.05 dh]);
wc_proc_tab_comp.grdlim_maxdist = uicontrol(grid_gr,'style','edit',...
    'BackgroundColor',backgrColor,...
    'units','normalized',...
    'position',[0.76 h(3) 0.1 dh],...
    'String','inf',...
    'Callback',{@change_grdlim_maxdist_cback,main_figure});
uicontrol(grid_gr,'style','text','String','m',...
    'BackgroundColor',backgrColor,...
    'units','normalized',...
    'position',[0.86 h(3) 0.1 dh]);

% 3D gridding radio button and parameters
h = h-dh/2;
wc_proc_tab_comp.grid_3d = uicontrol(grid_gr,'style','radiobutton','String','3D',...
    'BackgroundColor',backgrColor,...
    'units','normalized',...
    'position',[0.05 h(4) 0.1 dh],...
    'tooltipstring','3-D gridding - all water-column data to be gridded at vertical resolution indicated, referenced to height reference indicated');
uicontrol(grid_gr,'style','text','String','Vert. res. (m):',...
    'BackgroundColor',backgrColor,...
    'units','normalized',...
    'position',[0.15 h(4) 0.25 dh],...
    'tooltipstring','(3-D gridding only)');
wc_proc_tab_comp.vert_grid_val = uicontrol(grid_gr,'style','edit',...
    'BackgroundColor',backgrColor,...
    'units','normalized',...
    'position',[0.4 h(4) 0.1 dh],...
    'String','1',...
    'Callback',{@check_fmt_box,0.1,100,1,'%.2f'},...
    'tooltipstring','(3-D gridding only)');

%% process button
uicontrol(wc_proc_tab_comp.wc_proc_tab,'Style','pushbutton','String','Process lines','Tooltipstring','(Filter bottom, mask data, filter sidelobes and grid)',...
    'units','normalized',...
    'pos',[0.25 0.01 0.5 0.08],...
    'callback',{@callback_press_process_button,main_figure},...
    'tooltipstring','Applies data processing and/or gridding (if selected) as per parameters indicated');

setappdata(main_figure,'wc_proc_tab',wc_proc_tab_comp);


end


%% Callbacks when changing min gridding limit distances
function change_grdlim_mindist_cback(~,~,main_figure)

default_mindist = 0;

wc_proc_tab_comp = getappdata(main_figure,'wc_proc_tab');

% check that modified value in the box is ok
check_fmt_box(wc_proc_tab_comp.grdlim_mindist,[],-inf,inf,0,'%.1f');

% grab the current values from both boxes
grdlim_mindist = str2double(wc_proc_tab_comp.grdlim_mindist.String);
grdlim_maxdist = str2double(wc_proc_tab_comp.grdlim_maxdist.String);

% if the min is more than max, don't accept change and reset default value
if grdlim_mindist > grdlim_maxdist
    wc_proc_tab_comp.grdlim_mindist.String = default_mindist;
end

end

%% Callbacks when changing max gridding limit distances
function change_grdlim_maxdist_cback(~,~,main_figure)

default_maxdist = inf;

wc_proc_tab_comp = getappdata(main_figure,'wc_proc_tab');

% check that modified value in the box is ok
check_fmt_box(wc_proc_tab_comp.grdlim_maxdist,[],-inf,inf,default_maxdist,'%.1f');

% grab the current values from both boxes
grdlim_mindist = str2double(wc_proc_tab_comp.grdlim_mindist.String);
grdlim_maxdist = str2double(wc_proc_tab_comp.grdlim_maxdist.String);

% if the min is more than max, don't accept change and reset default value
if grdlim_mindist > grdlim_maxdist
    wc_proc_tab_comp.grdlim_maxdist.String = default_maxdist;
end

end


