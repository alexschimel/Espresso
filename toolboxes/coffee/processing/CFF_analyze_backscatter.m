function fDataGroup = CFF_analyze_backscatter(fDataGroup,varargin)


% input parser
p = inputParser;
addRequired(p,'fDataGroup',@(x) all(CFF_is_fData_version_current(x)));
addParameter(p,'comms',CFF_Comms());
parse(p,fDataGroup,varargin{:});
comms = p.Results.comms;
clear p;
if ischar(comms)
    comms = CFF_Comms(comms);
end

% start message
comms.start('Analyzing backscatter in line(s)');

% number of lines
nLines = numel(fDataGroup);

% start progress
comms.progress(0,nLines);

% process per file
for ii = 1:nLines
    
    % get fData for this line
    fData = fDataGroup{ii};
    
    % display for this line
    lineName = CFF_file_name(char(CFF_onerawfileonly(fData.ALLfilename)),1);
    comms.step(sprintf('%i/%i: line %s',ii,nLines,lineName));
    
    %% step 1. find bad soundings
    % criteria 1: identifying bad beams from detection info
    [DetectInfo, ~] = CFF_decode_X8_DetectionInfo(fData.X8_BP_DetectionInformation);
    badSoundings = DetectInfo>1;
    
    %% step 2. find bad pings
    
    nBeams = size(DetectInfo,1);
    
    % criteria 1: a ping with a percentage of bad soundings that exceeds a
    % threshold is a bad ping
    thr = 0.1;
    badPings1 = (sum(badSoundings)./nBeams) > thr;
    
    % criteria 2: a ping which average backscatter level is abnormally low
    % is a bad ping
    avgBS = median(fData.X8_BP_ReflectivityBS);
    nPings = max(size(avgBS));
    
    iKeep = zeros(1,nPings);
    lowth = nan(1,nPings);
    
    trailNum = 20;
    iKeep(1:trailNum) = 1;
    
    iKeep(1:trailNum) = 1;
    
    for jj = trailNum+1:nPings
        idx = find(iKeep,trailNum,'last');
        dat = avgBS(idx);
        lowth(jj) = median(dat) - 2.*range(dat);
        if (avgBS(jj)<lowth(jj)) || badPings1(jj)
            iKeep(jj) = 0;
        else
            iKeep(jj) = 1;
        end
    end
    badPings = ~iKeep;
    
    % display to check
    DEBUG = 0;
    if DEBUG
        figure;
        tiledlayout(2,1);
        ax1 = nexttile;
        imagesc(fData.X8_BP_ReflectivityBS);
        colormap gray; caxis([-400 0]);grid on
        hold on
        if any(badPings)
            plot(find(badPings),400,'r*')
        end
        ax2 = nexttile;
        plot(avgBS,'.-'); hold on
        plot(lowth,'r')
        plot(find(~iKeep),avgBS(~iKeep),'r*')
        grid on
        linkaxes(findall(gcf,'type','axes'),'x');
    end
    
    %% step 3. identify bad sections
    % criteria 1: a section of pings with a percentage of bad pings that
    % exceeds a threshold is a bad section
    
    % Using a sliding window size in num of pings, and threshold number of
    % bad pings within a window above which to classify window as to be
    % resurveyed
    win = 100;
    nThr = 1;
    badSections = conv2(badPings,ones(1,win),'same')>=nThr;
    
    %% step 4. save results
    fData.X_BP_goodData = ~badSoundings;
    fData.X_1P_badPing = badPings;
    fData.X_1P_toResurvey = badSections;
    fDataGroup{ii} = fData;
    
    % successful end of this iteration
    comms.info('Done');
    
    % communicate progress
    comms.progress(ii,nLines);
    
end

% end message
comms.finish('Done');

end