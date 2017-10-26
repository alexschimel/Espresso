
clear all
close all

addpath(genpath('D:\Docs\MATLAB\CoFFee\'));


%% convert all files still to be converted

datarootfolder = 'S:\schimela\Watercolumn data for Alex and Yoann';
folder = {'150', '152', '154', '160', '165'};
file = {};
% list files to convert
for nF = 1:length(folder)
    [ALLtmp,MATtmp] = CFF_filelist_for_conversion([datarootfolder filesep folder{nF} filesep],[datarootfolder filesep folder{nF} '_MAT' filesep]);
    file = [file;[ALLtmp,MATtmp]];
end
% list files already converted
for nF = 1:size(file,1)
    if exist(file{nF,2},'file')
        file{nF,3} = 1;
    else
        file{nF,3} = 0;
    end
end
% convert files not converted yet
for nF = 1:size(file,1)
    if ~file{nF,3}
        txt = sprintf('Converting file "%s" - started on: %s', file{nF,1}, datestr(now));
        disp(txt);
        CFF_convert_all_to_mat_v2(file{nF,1},file{nF,2});
    end
end


%% PARAMETERS

% choose file to process here:

% datarootfolder = 'D:\DATA\0033';
% folder = '150';
% ALLMATfile = {[datarootfolder filesep folder '_MAT' filesep '0032_20161211_014630_all.mat']};
% WCDMATfile = {[datarootfolder filesep folder '_MAT' filesep '0032_20161211_014630_wcd.mat']};
% 
% 152 - Line 7 - Wreck at 19:56:26 >> 19:56:48
datarootfolder = 'D:\DATA\0033';
folder = '152';
ALLMATfile = {[datarootfolder filesep folder '_MAT' filesep '0007_20161212_195553_all.mat']};
WCDMATfile = {[datarootfolder filesep folder '_MAT' filesep '0007_20161212_195553_wcd.mat']};
% 
% datarootfolder = 'D:\DATA\0033';
% folder = '165';
% ALLMATfile = {[datarootfolder filesep folder '0000_20170218_194405_all.mat']};
% WCDMATfile = {[datarootfolder filesep folder '0000_20170218_194405_wcd.mat']};

% Alex's super short file with giant kelp
datarootfolder = 'D:\DATA\0024';
ALLMATfile = {[datarootfolder filesep 'MAT' filesep '0001_20140213_052736_Yolla_all.mat']};
WCDMATfile = {[datarootfolder filesep 'MAT' filesep '0001_20140213_052736_Yolla_wcd.mat']};


datarootfolder = 'D:\DATA\0033';

% Seeps

fileBase = [ datarootfolder filesep '152_MAT' filesep '0011_20161212_200521']; 

clear event

event{1}.time = '20:06:47';%'20:09:32';
event{1}.description = 'seepage field with near-bottom biomass and strong seeps'; 
timeRangeInSec = 10;
timeDatenum = datenum([datestr(fData.X_1P_pingSDN(1),'dd-mmm-yyyy') ' ' event{1}.time]);
event{1}.timeRange = { datestr(timeDatenum - timeRangeInSec./(60.*60.*24)) , datestr(timeDatenum + timeRangeInSec./(60.*60.*24)) };

event{2}.time = '20:12:43';
event{2}.description = 'seepage field with near-bottom biomass and strong seeps'; 
timeRangeInSec = 10;
timeDatenum = datenum([datestr(fData.X_1P_pingSDN(1),'dd-mmm-yyyy') ' ' event{2}.time]);
event{2}.timeRange = { datestr(timeDatenum - timeRangeInSec./(60.*60.*24)) , datestr(timeDatenum + timeRangeInSec./(60.*60.*24)) };

event{3}.time = '20:14:16';
event{3}.description = 'seepage field with near-bottom biomass and strong seeps'; 
timeRangeInSec = 10;
timeDatenum = datenum([datestr(fData.X_1P_pingSDN(1),'dd-mmm-yyyy') ' ' event{3}.time]);
event{3}.timeRange = { datestr(timeDatenum - timeRangeInSec./(60.*60.*24)) , datestr(timeDatenum + timeRangeInSec./(60.*60.*24)) };

% fileBase = [ datarootfolder filesep '152_MAT' filesep '0014_20161212_203651']; description = 'solitary plume';                                          time = '20:47:28';
% fileBase = [ datarootfolder filesep '154_MAT' filesep '0016_20161213_235507']; description = 'diffuse solitary plume';                                  time = '23:55:23';
% fileBase = [ datarootfolder filesep '154_MAT' filesep '0030_20161214_010440']; description = 'strong solitary plumes';                                  time = '01:05:06';
% fileBase = [ datarootfolder filesep '154_MAT' filesep '0030_20161214_010440']; description = 'strong solitary plumes followed by wake';                 time = '01:07:52'; 
% fileBase = [ datarootfolder filesep '165_MAT' filesep '0000_20170218_194405']; description = 'strong solitary plume';                                   time = '19:46:43.8';
% fileBase = [ datarootfolder filesep '165_MAT' filesep '0012_20170218_212715']; description = 'strong solitary plume';                                   time = '21:29:54';
% fileBase = [ datarootfolder filesep '165_MAT' filesep '0016_20170218_220423']; description = 'diffuse plumes';                                          time = '22:06:14';
% fileBase = [ datarootfolder filesep '165_MAT' filesep '0016_20170218_220423']; description = 'diffuse plumes';                                          time = '22:15:34';
% fileBase = [ datarootfolder filesep '165_MAT' filesep '0016_20170218_220423']; description = 'strong solitary plume';                                   time = '22:06:31';
% fileBase = [ datarootfolder filesep '165_MAT' filesep '0016_20170218_220423']; description = 'wake';                                                    time = '22:05:20';
% fileBase = [ datarootfolder filesep '165_MAT' filesep '0020_20170218_224651']; description = 'diffuse plumes';                                          time = '22:50:13'; 
% fileBase = [ datarootfolder filesep '165_MAT' filesep '0020_20170218_224651']; description = 'diffuse plumes';                                          time = '22:50:40';
% fileBase = [ datarootfolder filesep '165_MAT' filesep '0020_20170218_224651']; description = 'diffuse plumes';                                          time = '22:53:20';



%% PROCESSING

WCDMATfile{1} = [fileBase '_wcd.mat'];
ALLMATfile{1} = [fileBase '_all.mat'];


%% Start Display
txt = sprintf('Processing file "%s" - started on: %s', WCDMATfile{1}, datestr(now));
disp(txt);

%% convert mat to fabc format
tic
disp('CFF_convert_mat_to_fabc_v2...');
dr = 5; % samples subsampling factor
db = 2; % beam subsampling factor
fData = CFF_convert_mat_to_fabc_v2({WCDMATfile{1};ALLMATfile{1}},dr,db);
toc

% test display
% CFF_watercolumn_display_v2(fData);


%% process ping data (time, position and heading)
tic
disp('CFF_process_ping_v2...');
fData = CFF_process_ping_v2(fData,'WC');
toc

% test display
figure; CFF_watercolumn_display_v2(fData,'displayType','flat','absoluteTime',event{1}.timeRange); 

%% pre-process water column data (get XYZ of samples)
tic
disp('CFF_process_watercolumn_v2...');
fData = CFF_process_watercolumn_v2(fData);
toc

% test display
% figure; CFF_watercolumn_display_v2(fData,'displayType','wedge','absoluteTime',event{1}.timeRange); 

%% pre-process bottom detect data (get XYZ of samples)
tic
disp('CFF_process_WC_bottom_detect...');
fData = CFF_process_WC_bottom_detect_v2(fData);
toc

% test display
figure; CFF_watercolumn_display_v2(fData,'displayType','wedge','bottomDetectDisplay','yes','absoluteTime',event{1}.timeRange); 
figure; CFF_watercolumn_display_v2(fData,'displayType','wedge','bottomDetectDisplay','yes','absoluteTime',{'12-Dec-2016 20:12:30','12-Dec-2016 20:14:30'}); 

% CFF_watercolumn_display_v2(fData,'displayType','projected','bottomDetectDisplay','yes');

%% smooth bottom detection
%     fData = CFF_filter_WC_bottom_detect(fData);
%     fData = CFF_filter_WC_bottom_detect(fData,'method','filter');
%     fData = CFF_filter_WC_bottom_detect(fData,'method','flag');
%     fData = CFF_filter_WC_bottom_detect(fData,'method','test');
flagParams.type = 'all';%''
flagParams.variable = 'slope';
flagParams.threshold = 30;
tic
disp('CFF_filter_WC_bottom_detect_v2...');
fData = CFF_filter_WC_bottom_detect_v2(fData,'method','flag','pingBeamWindowSize',[3 3],'maxHorizDist',inf,'flagParams',flagParams,'interpolate','yes');
toc

% test display
% CFF_watercolumn_display_v2(fData,'bottomDetectDisplay','yes');
% figure; CFF_watercolumn_display_v2(fData,'displayType','wedge','bottomDetectDisplay','yes','absoluteTime',event{1}.timeRange); 
% CFF_watercolumn_display_v2(fData,'displayType','projected','bottomDetectDisplay','yes');

%% create mask to remove data under the filtered bottom detect
tic
disp('CFF_mask_WC_data_v2...');
fData = CFF_mask_WC_data_v2(fData,inf,1,0);
% fData = CFF_mask_WC_data_v2(fData,50,1,2);
toc


% test display
% CFF_watercolumn_display_v2(fData,'data','masked original','bottomDetectDisplay','yes','absoluteTime',{'12-Dec-2016 19:56:26 ','12-Dec-2016 19:56:48'}); 
figure; CFF_watercolumn_display_v2(fData,'data','masked original','displayType','wedge','bottomDetectDisplay','yes','absoluteTime',event{1}.timeRange); 
% CFF_watercolumn_display_v2(fData,'data','masked original','displayType','projected','bottomDetectDisplay','yes');


%% remove sidelobe artefact
tic
disp('CFF_filter_WC_sidelobe_artifact_v2...');
fData = CFF_filter_WC_sidelobe_artifact_v2(fData,3);
toc

% test display
% CFF_watercolumn_display_v2(fData,'data','masked L1','bottomDetectDisplay','yes','absoluteTime',{'12-Dec-2016 19:56:26 ','12-Dec-2016 19:56:48'}); 
figure; CFF_watercolumn_display_v2(fData,'data','masked L1','displayType','wedge','bottomDetectDisplay','yes','absoluteTime',event{1}.timeRange); 
% CFF_watercolumn_display_v2(fData,'data','masked L1','displayType','projected','bottomDetectDisplay','yes');

%% grid water column
% old approach
tic
disp('CFF_grid_watercolumn_v2...');
res = 0.5;
fData = CFF_grid_watercolumn_v2_temp(fData,'masked L1',res);
toc

% test display
% CFF_watercolumn_display_v2(fData,'displayType','gridded');


% saving results
% tic
% disp('saving fData...');
% save fData fData '-v7.3';
% toc


%% DISPLAY

% grab data
E = fData.X_1E_gridEasting;
N = fData.X_N1_gridNorthing;
H = fData.X_11H_gridHeight;
L = fData.X_NEH_gridLevel;

% get mean
meanL = nanmean(L,3);

%% display
figure
h = imagesc(E,N,meanL);
set(h,'alphadata',~isnan(meanL));
axis equal
grid on;
set(gca,'Ydir','normal')
colorbar
CFF_nice_easting_northing
xlabel('Easting (m)')
ylabel('Northing (m)')
times1 = datestr(fData.X_1P_pingSDN,'dd-mmm-yyyy HH:MM:SS.FFF');
times2 = datestr(fData.X_1P_pingSDN,'HH:MM:SS.FFF');
hold on
df = 100;
plot(fData.X_1P_pingE(1),fData.X_1P_pingN(1),'go');
plot([fData.X_1P_pingE(1:df:end),fData.X_1P_pingE(end)],[fData.X_1P_pingN(1:df:end),fData.X_1P_pingN(end)],'k.-');
plot(fData.X_1P_pingE(end),fData.X_1P_pingN(end),'rs');
text(fData.X_1P_pingE(1),fData.X_1P_pingN(1),sprintf(' \\leftarrow %s (start)',times1(1,:)))
text(fData.X_1P_pingE(end),fData.X_1P_pingN(end),sprintf(' \\leftarrow %s (end)',times1(end,:)))
for ii = (df+1):df:length(fData.X_1P_pingN)-1
    text(fData.X_1P_pingE(ii),fData.X_1P_pingN(ii),sprintf(' \\leftarrow %s',times2(ii,:)))
end

