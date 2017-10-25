function [h,F] = CFF_watercolumn_display_v2(fData, varargin)
% [h,F] = CFF_watercolumn_display_v2(fData, varargin)
%
% DESCRIPTION
%
% Displays Multibeam watercolumn data in various ways.
%
% REQUIRED INPUT ARGUMENTS
%
% - 'fData': the multibeam data structure
%
% OPTIONAL INPUT ARGUMENTS
%
% - 'data': string indicating which data in fData to grab: 'original'
% (default) or 'L1'. Can be overwritten by inputting "otherData". 
%
% - 'displayType': string indicating type of display: 'flat' (default),
% 'wedge', 'projected' or 'gridded' (this last one need the data to have
% been gridded.) 
%
% - 'movieFile': string indicating filename for movie creation. By default
% an empty string to mean no movie is to be made.
%
% - 'otherData': array of numbers to be displayed instead of the original
% or L1 data. Used in case of tests for new types of corrections.
%
% - 'pings': vector of numbers indicating which pings to be displayed. If
% more than one, the result will be an animation.
%
% - 'bottomDetectDisplay': string indicating whether to display the bottom
% detect in the data or not: 'no' (default) or 'yes'.  
%
% - 'waterColumnTargets': array of points to be displayed ontop of
% watercolumn data. Must be a table with columns Easting, Northing, Height,
% ping, beam, range. 
%
% OUTPUT VARIABLES
%
% - 'h': figure handle
%
% - 'F': movie frames
%
% RESEARCH NOTES
%
% - display contents of the input parser?
%
% NEW FEATURES
%
% - 2016-12-01: now grabbing 'X_BP_bottomSample' field for bottom in flat
% display instead of original field, after changes on how bottom is
% processed. Also, adding bottom detect display option to gridded data.
% - 2015-09-29: updating description after changing varargin management to
% inputparser
% - 2014-04-25: first version
%
% EXAMPLES
%
% % The following are ALL equivalent: display original data, all pings, flat, no bottom detect, no movie
% CFF_watercolumn_display(fData); 
% CFF_watercolumn_display(fData,'original');
% CFF_watercolumn_display(fData,'data','original'); 
% CFF_watercolumn_display(fData,'pings',NaN);
% CFF_watercolumn_display(fData,'data','original','pings',NaN);
% CFF_watercolumn_display(fData,'data','original','pings',NaN,'displayType','flat');
%
% % All 3 display types with bottom detect ON
% CFF_watercolumn_display(fData,'data','L1','displayType','flat','bottomDetectDisplay','yes');
% CFF_watercolumn_display(fData,'data','L1','displayType','wedge','bottomDetectDisplay','yes');
% CFF_watercolumn_display(fData,'data','L1','displayType','projected','bottomDetectDisplay','yes');
%
% % Movie creation in flat mode
% CFF_watercolumn_display(fData,'data','L1','displayType','flat','bottomDetectDisplay','yes','movieFile','testmovie');
%
% % USe of 'otherData'
% otherM = fData.WC_SBP_SampleAmplitudes + 50;
% CFF_watercolumn_display(fData,'otherData',otherM);
%
% % Old varargin management should still work.
% [h,F] = CFF_watercolumn_display(fData, 'original','flat','testmovie')
%
% % Finally, testing water column targets
% CFF_watercolumn_display(fData,'data','L1','displayType','flat','bottomDetectDisplay','yes','waterColumnTargets',kelp);
% CFF_watercolumn_display(fData,'data','L1','displayType','wedge','bottomDetectDisplay','yes','waterColumnTargets',kelp);
% CFF_watercolumn_display(fData,'data','L1','displayType','projected','bottomDetectDisplay','yes','waterColumnTargets',kelp);
%
%%%
% Alex Schimel, Deakin University
%%%


%% INPUT PARSER

p = inputParser;

% 'fData', the multibeam data structure (required)
% addRequired(p,'fData',@isstruct);
% remove it from parsing because it takes too much space

% 'data' is an optional string indicating which data in
% fData to grab: 'original' (default) or 'L1'. Can be overwritten by
% inputting "otherData". 
arg = 'data';
defaultArg = 'original';
checkArg = @(x) any(validatestring(x,{'original','masked original','L1','masked L1','test'})); % valid arguments for optional check
addOptional(p,arg,defaultArg,checkArg);

% 'displayType' is an optional string indicating type of display: 'flat' (default), 'wedge' or 'projected'
arg = 'displayType';
defaultArg = 'flat';
checkArg = @(x) any(validatestring(x,{'flat', 'wedge','projected','gridded'})); % valid arguments for optional check
addOptional(p,arg,defaultArg,checkArg);

% 'movieFile' is an optional string indicating filename for
% movie creation. By default an empty string to mean no movie is to be
% made.
arg = 'movieFile';
defaultArg = '';
checkArg = @(x) ischar(x); % valid arguments for optional check
addOptional(p,arg,defaultArg,checkArg);

% 'otherData' is an optional array of numbers to be displayed instead of
% the original or L1 data. Used in case of tests for new types of
% corrections
arg = 'otherData';
defaultArg = [];
checkArg = @(x) isnumeric(x) && all(size(x)==size(fData.WC_SBP_SampleAmplitudes)); % valid arguments for optional check
addOptional(p,arg,defaultArg,checkArg);

% 'pings' is an optional vector of numbers indicating which pings to be
% displayed. If more than one, the result will be an animation. You cannot
% use 'pings' if you use 'absoluteTime' or 'relativeTime'. This does not
% apply to gridded data.
arg = 'pings';
defaultArg = [];
checkArg = @(x) isnumeric(x); % valid arguments for optional check
addOptional(p,arg,defaultArg,checkArg);

% 'absoluteTime' is an optional vector of 2 cells containing datestrings
% for the start and end time to be displayed. You cannot use 'absoluteTime'
% if you use 'pings' or 'relativeTime'. This does not apply to gridded
% data.
% example: 'absoluteTime',{'18-Feb-2017 19:46:30 ','18-Feb-2017 19:47:00'}
arg = 'absoluteTime';
defaultArg = [];
checkArg = @(x) iscell(x)&&numel(x)==2; % valid arguments for optional check
addOptional(p,arg,defaultArg,checkArg);

% 'relativeTime' is an optional vector of 2 cells containing time in
% seconds since the start of the file for the start and end time to be
% displayed. You cannot use 'relativeTime' if you use 'absoluteTime' or
% 'pings'. This does not apply to gridded data.
arg = 'relativeTime';
defaultArg = [];
checkArg = @(x) isnumeric(x)&&numel(x)==2; % valid arguments for optional check
addOptional(p,arg,defaultArg,checkArg);

% 'bottomDetectDisplay' is a string indicating
% wether to display the bottom detect in the data or not: 'no' (default) or 'yes'. 
arg = 'bottomDetectDisplay';
defaultArg = 'no';
checkArg = @(x) any(validatestring(x,{'no', 'yes'})); % valid arguments for optional check
addOptional(p,arg,defaultArg,checkArg);

% 'waterColumnTargets' is an optional array of points to be displayed ontop
% of watercolumn data. Must be a table with Easting, Northing, Height,
% ping, beam, range.
arg = 'waterColumnTargets';
defaultArg = [];
checkArg = @(x) isnumeric(x); % valid arguments for optional check
addOptional(p,arg,defaultArg,checkArg);

% now parse actual inputs
% parse(p,fData, varargin{:});
parse(p,varargin{:});

% get input parser contents
data = p.Results.data;
displayType = p.Results.displayType;
movieFile = p.Results.movieFile;
otherData = p.Results.otherData;
pings = p.Results.pings;
absoluteTime = p.Results.absoluteTime;
relativeTime = p.Results.relativeTime;
bottomDetectDisplay = p.Results.bottomDetectDisplay;
waterColumnTargets = p.Results.waterColumnTargets;

% clear p
clear p

%% initalize figure
h = gcf;

% set figure to full screen if movie requested
if ~isempty(movieFile)
    set(h,'Position',get(0,'ScreenSize'))
end

%% main data info
[pathstr, name, ext] = fileparts(fData.MET_MATfilename{1});
fileName = [name ext];
pingCounter = fData.WC_1P_PingCounter;
[nSamples,nBeams,nPings] = size(fData.WC_SBP_SampleAmplitudes.Data.val); 


%% prepare strings for data to analyze
% this is done to avoid having to load all data at the start, and avoid
% having the switch inside each loop, which would make the code take
% forever. Using eval is not pretty but we have no choice
switch data
    case 'original'
        dataString = 'fData.WC_SBP_SampleAmplitudes.Data.val(:,:,ip)./2';
    case 'masked original'
        dataString = 'fData.X_SBP_Mask.Data.val(:,:,ip) .* fData.WC_SBP_SampleAmplitudes.Data.val(:,:,ip)./2';
    case 'L1'
        dataString = 'fData.X_SBP_L1.Data.val(:,:,ip)';
    case 'masked L1'
        dataString = 'fData.X_SBP_Mask.Data.val(:,:,ip) .* fData.X_SBP_L1.Data.val(:,:,ip)';
end
if ~isempty(otherData)
    % overwrite with other data
    dataString = 'otherData(:,:,ip)';
end
% Note, if data to display is the gridded data, this will be simply
% extracted in the gridded display section


%% pings to display
if isempty(pings) && isempty(absoluteTime) && isempty(relativeTime)
     dispPings = 1:nPings;
elseif ~isempty(pings) && isempty(absoluteTime) && isempty(relativeTime)
    % pings in input
    dispPings = pings;
elseif isempty(pings) && ~isempty(absoluteTime) && isempty(relativeTime)
    % find pings corresponding to desired absoluteTime interval
    if isfield(fData,'X_1P_pingSDN')
        firstPing = find(fData.X_1P_pingSDN>=datenum(absoluteTime{1}),1,'first');
        lastPing  = find(fData.X_1P_pingSDN<=datenum(absoluteTime{2}),1,'last');
        dispPings = firstPing:lastPing;
    else
        error('Error: You must process ping data (CFF_process_ping_v2) before being able to use the option ''absoluteTime''.');
    end
elseif isempty(pings) && isempty(absoluteTime) && ~isempty(relativeTime)
    % find pings corresponding to desired relativeTime interval
    if isfield(fData,'X_1P_pingSDN')
        firstPing = find(fData.X_1P_pingSDN >= fData.X_1P_pingSDN(1) + relativeTime(1)./(60.*60.*24),1,'first');
        lastPing  = find(fData.X_1P_pingSDN <= fData.X_1P_pingSDN(1) + relativeTime(2)./(60.*60.*24),1,'last');
        dispPings = firstPing:lastPing;
    else
        error('Error: You must process ping data (CFF_process_ping_v2) before being able to use the option ''relativeTime''.');
    end
else
    error('Error: You cannot have more than one of the options ''pings'', ''relativeTime'' and ''absoluteTime'' in input.');
end


%% display data switch
switch displayType
    
    case 'flat'
        
        % bottom detect
        if strcmp(bottomDetectDisplay,'yes')
            b = fData.X_BP_bottomSample;
        end
        
        % data bounds
        minM = nan(size(dispPings));
        maxM = nan(size(dispPings));
        for ip = dispPings
            minM(ip==dispPings) = eval(sprintf('min(reshape(%s,1,[]))',dataString)); 
            maxM(ip==dispPings) = eval(sprintf('max(reshape(%s,1,[]))',dataString));
        end
        minM = min(minM);
        maxM = max(maxM);
        
        % plot
        for ip = dispPings
            cla
            eval(sprintf('imagesc(%s);',dataString));
            colorbar
            hold on
            if strcmp(bottomDetectDisplay,'yes')
                plot(b(:,ip),'k.')
            end
            if ~isempty(waterColumnTargets)
                ind = find( waterColumnTargets(:,4) == ip);
                if ~isempty(ind)
                    temp = waterColumnTargets(ind,5:6);
                    plot(temp(:,1),temp(:,2),'ko')
                end
            end
            caxis([minM maxM])
            grid on
            if isfield(fData,'X_1P_pingSDN')
                title( sprintf( 'File: %s\nPing %i/%i (#%i)\n%s', ...
                    fileName,...
                    ip,nPings,pingCounter(ip),...
                    datestr(fData.X_1P_pingSDN(1,ip),'dd-mmm-yyyy HH:MM:SS:FFF') ...
                    ), 'FontWeight','normal','Interpreter','none');
            else
                title( sprintf( 'File: %s\nPing %i/%i (#%i)\n', ...
                    fileName,...
                    ip,nPings,pingCounter(ip) ...
                    ), 'FontWeight','normal','Interpreter','none');
            end
            xlabel('beam #')
            ylabel('sample #')
            drawnow
            if ~isempty(movieFile)
                F(ip) = getframe(gcf);
            end
        end
        
    case 'wedge'
        
        % bottom detect
        if strcmp(bottomDetectDisplay,'yes')
            bX = fData.X_BP_bottomAcrossDist;
            bY = fData.X_BP_bottomUpDist;
        end
        
        % data bounds
        minX = nan(size(dispPings));
        minY = nan(size(dispPings));
        minM = nan(size(dispPings));
        maxM = nan(size(dispPings));
        maxX = nan(size(dispPings));
        maxY = nan(size(dispPings));
        for ip = dispPings
            % get coordinates and data for ping
            X = fData.X_SBP_sampleAcrossDist.Data.val(:,:,ip);
            Y = fData.X_SBP_sampleUpDist.Data.val(:,:,ip);
            eval(sprintf('M = %s;',dataString));
            % find min and max for this ping
            ind = ~isnan(M);
            minX(ip==dispPings) = min(X(ind));
            minY(ip==dispPings) = min(Y(ind));
            minM(ip==dispPings) = min(M(ind));
            maxX(ip==dispPings) = max(X(ind));
            maxY(ip==dispPings) = max(Y(ind));
            maxM(ip==dispPings) = max(M(ind));
        end
        minX = min(minX);
        minY = min(minY);
        minM = min(minM);
        maxX = max(maxX);
        maxY = max(maxY);
        maxM = max(maxM);

        % plot
        for ip = dispPings
            cla
            eval(sprintf('pcolor(fData.X_SBP_sampleAcrossDist.Data.val(:,:,ip),fData.X_SBP_sampleUpDist.Data.val(:,:,ip),%s);',dataString));

            shading interp
            hold on
            if strcmp(bottomDetectDisplay,'yes')
                plot(bX(:,ip),bY(:,ip),'k.')
            end
            if ~isempty(waterColumnTargets)
                ind = find( waterColumnTargets(:,4) == ip);
                if ~isempty(ind)
                    temp = waterColumnTargets(ind,5:6);
                    clear up across
                    for jj = 1:size(temp,1)
                        up(jj) = fData.X_SBP_sampleUpDist(ip,temp(jj,1),temp(jj,2));
                        across(jj) = fData.X_SBP_sampleAcrossDist(ip,temp(jj,1),temp(jj,2));
                    end
                    plot(across,up,'ko')
                end
            end
            title( sprintf( 'File: %s\nPing %i/%i (#%i)\n%s', ...
                fileName,...
                ip,nPings,pingCounter(ip),...
                datestr(fData.X_1P_pingSDN(1,ip),'dd-mmm-yyyy HH:MM:SS:FFF') ...
                ), 'FontWeight','normal','Interpreter','none');
            if ip==dispPings(1)
                colorbar
                axis equal
                axis tight
                axis([minX maxX minY maxY])
                caxis([minM maxM])
                grid on
                xlabel('across distance (starboard) (m)')
                ylabel('height above sonar (m)')
            end
            drawnow
            if ~isempty(movieFile)
                F(ip) = getframe(gcf);
            end
        end
        
    case 'projected'
        
        % bottom detect
        if strcmp(bottomDetectDisplay,'yes')
            bE = fData.X_BP_bottomEasting;
            bN = fData.X_BP_bottomNorthing;
            bH = fData.X_BP_bottomHeight;
        end
        
        % data bounds
        minE = nan(size(dispPings));
        minN = nan(size(dispPings));
        minH = nan(size(dispPings));
        minM = nan(size(dispPings));
        maxE = nan(size(dispPings));
        maxN = nan(size(dispPings));
        maxH = nan(size(dispPings));
        maxM = nan(size(dispPings));
        for ip = dispPings
            % get coordinates and data for ping
            E = fData.X_SBP_sampleEasting.Data.val(:,:,ip);
            N = fData.X_SBP_sampleNorthing.Data.val(:,:,ip);
            H = fData.X_SBP_sampleHeight.Data.val(:,:,ip);
            eval(sprintf('M = %s;',dataString));
            % find min and max for this ping
            ind = ~isnan(M);
            minE(ip==dispPings) = min(E(ind));
            minN(ip==dispPings) = min(N(ind));
            minH(ip==dispPings) = min(H(ind));
            minM(ip==dispPings) = min(M(ind));
            maxE(ip==dispPings) = max(E(ind));
            maxN(ip==dispPings) = max(N(ind));
            maxH(ip==dispPings) = max(H(ind));
            maxM(ip==dispPings) = max(M(ind));
        end
        minE = min(minE);
        minN = min(minN);
        minH = min(minH);
        minM = min(minM);
        maxE = max(maxE);
        maxN = max(maxN);
        maxH = max(maxH);
        maxM = max(maxM);
        
        % plot
        for ip = dispPings
            cla
            x = reshape(fData.X_SBP_sampleEasting.Data.val(:,:,ip),1,[]);
            y = reshape(fData.X_SBP_sampleNorthing.Data.val(:,:,ip),1,[]);
            z = reshape(fData.X_SBP_sampleHeight.Data.val(:,:,ip),1,[]);
            eval(sprintf('c = reshape(%s,1,[]);',dataString));
            scatter3(x,y,z,2,c,'.')
            colorbar
            hold on
            if strcmp(bottomDetectDisplay,'yes')
                plot3(bE(:,ip),bN(:,ip),bH(:,ip),'k.')
            end
            if ~isempty(waterColumnTargets)
                plot3(waterColumnTargets(:,1),waterColumnTargets(:,2),waterColumnTargets(:,3),'ko')
            end
            axis equal
            axis([minE maxE minN maxN minH maxH])
            caxis([minM maxM])
            grid on
            title( sprintf( 'File: %s\nPing %i/%i (#%i)\n%s', ...
                fileName,...
                ip,nPings,pingCounter(ip),...
                datestr(fData.X_1P_pingSDN(1,ip),'dd-mmm-yyyy HH:MM:SS:FFF') ...
                ), 'FontWeight','normal','Interpreter','none');
            xlabel('Easting (m)')
            ylabel('Northing (m)')
            zlabel('Height above datum (m)')
            CFF_nice_easting_northing
            drawnow
            if ~isempty(movieFile)
                F(ip) = getframe(gcf);
            end
        end
        
    case 'gridded'
        
        % grab data
        E = fData.X_1E_gridEasting;
        N = fData.X_N1_gridNorthing;
        H = fData.X_11H_gridHeight;
        M = fData.X_NEH_gridLevel;
        
        if strcmp(bottomDetectDisplay,'yes')
            % bottom detect
            bottom = fData.X_NE_gridBottom;
        end
        
        % data bounds
        nE = length(E);
        nN = length(N);
        % maxE = max(E(:));
        % minE = min(E(:));
        % maxN = max(N(:));
        % minN = min(N(:));
        % maxH = max(H(:));
        % minH = min(H(:));
        maxM = nanmax(M(:));
        minM = nanmin(M(:));
        
        for kk = 1:length(H)
            
            cla
            h1 = imagesc(E,N,M(:,:,kk));
            set(h1,'alphadata',~isnan(M(:,:,kk)));
            
            if strcmp(bottomDetectDisplay,'yes')
                % bottom display part
                if kk<length(H)
                    ind = find( bottom>H(kk) & bottom<H(kk+1) );
                    if ~isempty(ind)
                        [iN,iE] = ind2sub([nN,nE],ind);f
                        hold on
                        plot(E(iE),N(iN),'k*');
                    end
                end
            end
            
            axis equal
            grid on;
            set(gca,'Ydir','normal')
            caxis([minM maxM])
            colorbar
            CFF_nice_easting_northing
            title(sprintf('File: %s. Slice %i/%i - Height above datum: %.2f m',fileName,kk,length(H),H(kk)),'FontWeight','normal','Interpreter','none')
            xlabel('Easting (m)')
            ylabel('Northing (m)')
            drawnow
            if ~isempty(movieFile)
                F(kk) = getframe(gcf);
            end
        end
        
end

% write movie
if ~isempty(movieFile)
    writerObj = VideoWriter(movieFile,'MPEG-4');
    set(writerObj,'Quality',100)
    open(writerObj)
    writeVideo(writerObj,F);
    close(writerObj);
end


% OLD CODE
%
% figure; plot(SeedsAcrossDist,SeedsDownDist,'.')
% axis equal
% hold on
% for jj = 1:size(M,1)
%     pause(0.1)
%     plot([SeedsAcrossDist(M(jj,1)),SeedsAcrossDist(M(jj,2))],[SeedsDownDist(M(jj,1)),SeedsDownDist(M(jj,2))], 'ro-')
%     drawnow
% end
%
% %figure
% clf
% surf(DownDist,AcrossDist,DATACorr);
% hold on
% shading interp;
% view(90,-90);
% axis equal;
% set(gca,'layer','top')
% axis([-10 0 -20 20])
% set(gca,'Color',[0.8 0.8 0.8],'XLimMode','manual','YLimMode','manual')
% set(gca,'ZDir','reverse')
% hold on
% plot(BottomY(BottomY~=0),BottomX(BottomY~=0),'k.-')
%
% for jj = 1:size(M,1)
%     plot([SeedsDownDist(M(jj,1)),SeedsDownDist(M(jj,2))],[SeedsAcrossDist(M(jj,1)),SeedsAcrossDist(M(jj,2))],'k.-')
% end
%
