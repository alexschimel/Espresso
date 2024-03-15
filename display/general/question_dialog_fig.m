function answer = question_dialog_fig(main_figure,tt_str,str_quest,varargin)
%QUESTION_DIALOG_FIG  One-line description
%
%   See also ESPRESSO.

%   Copyright 2017-2021 Alexandre Schimel, Yoann Ladroit, NIWA
%   Licensed under MIT. Details on https://github.com/alexschimel/Espresso/

p = inputParser;

addRequired(p,'main_figure',@(h) isempty(h)|isa(h,'matlab.ui.Figure'));
addRequired(p,'tt_str',@ischar);
addRequired(p,'str_quest',@ischar);
addParameter(p,'opt',{'Yes' 'No'},@iscell);
addParameter(p,'timeout',[],@isnumeric);

parse(p,main_figure,tt_str,str_quest,varargin{:});

opt=p.Results.opt;

answer=opt{1};

if ~isempty(main_figure)
    curr_disp=getappdata(main_figure,'Curr_disp');
    if ~isempty(curr_disp)
        font=curr_disp.Font;
        cmap=curr_disp.Cmap;
    else
        font=[];
        cmap=[];
    end
else
    font=[];
    cmap=[];
end

s_str=numel(str_quest);
nb_lines=ceil(s_str*8/400);

str_b_w=nanmax(ceil(s_str*8/nb_lines),250);

bt_w=nanmax([nansum(cellfun(@numel,opt))*8,50]);

box_w=nanmax(str_b_w+10,numel(opt)*(bt_w+10)+10);

main_figure_center = [main_figure.Position(1) + main_figure.Position(3)/2, main_figure.Position(2) + main_figure.Position(4)/2];

QuestFig = figure('units','pixels',...
    'Position',[main_figure_center(1) main_figure_center(2) box_w 100+(nb_lines-1)*10],...
    'WindowStyle','modal',...
    'Visible','on',...
    'resize','off');

uicontrol('Parent',QuestFig,...
    'Style','text',...
    'Position',[(box_w-str_b_w)/2 50 str_b_w 40+(nb_lines-1)*10],...
    'String',str_quest);

for i=numel(opt):-1:1
    noHandle=uicontrol('Parent',QuestFig,...
        'Position',[(box_w-2*bt_w-10)/2+(bt_w+10)*(i-1) 20 bt_w 25],...
        'String',opt{i},...
        'Callback',@decision_callback,...
        'KeyPressFcn',@doControlKeyPress , 'Value',0);
end


drawnow;
fig_timer=timer;
fig_timer.UserData.timeout = p.Results.timeout;
fig_timer.UserData.tt_str = tt_str;
fig_timer.UserData.t0 = now;
fig_timer.TimerFcn = {@update_fig_name,QuestFig};
fig_timer.StopFcn = @(src,evt) delete(src);
fig_timer.Period = 1;
fig_timer.ExecutionMode= 'fixedSpacing';


if ishghandle(QuestFig)
    % Go into uiwait if the figure handle is still valid.
    % This is mostly the case during regular use.
    c = matlab.ui.internal.dialog.DialogUtils.disableAllWindowsSafely();
    
    if isempty(p.Results.timeout)
        uiwait(QuestFig);
    else
        fig_timer.start;
        uiwait(QuestFig,p.Results.timeout);
        stop(fig_timer);
        delete(fig_timer)
    end
    delete(c);
end

if ishghandle(QuestFig)
    answer=get(QuestFig,'UserData');
else
    answer='';
end
delete(QuestFig);
drawnow; % Update the view to remove the closed figure (g1031998)

end

function update_fig_name(src,evt,fig)
t=abs((now-src.UserData.t0)*60*60*24);
if t<src.UserData.timeout
    str_name=sprintf('%s (%.0fs)',src.UserData.tt_str,abs(t-src.UserData.timeout));
    fig.Name=str_name;
end
end

function decision_callback(obj, evd) %#ok
set(gcbf,'UserData',get(obj,'String'));
uiresume(gcbf);
end

function doControlKeyPress(obj, evd)
switch(evd.Key)
    case {'return'}
        set(gcbf,'UserData',get(obj,'String'));
        uiresume(gcbf);
    case 'escape'
        delete(gcbf)
end
end
