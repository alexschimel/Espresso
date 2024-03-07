function create_menu(main_figure)
%CREATE_MENU  Create menu on Espresso main window
%
%   Obsolete
%
%   See also ESPRESSO.

%   Authors: Yoann Ladroit (NIWA, yoann.ladroit@niwa.co.nz) and Alex
%   Schimel (NIWA, alexandre.schimel@niwa.co.nz)
%   2017-2024

uimenu(main_figure,'Label','About','Callback',{@callback_about,main_figure});

end


%% Callback when pressing the "About" menu
function callback_about(~,~,main_figure)

% about text
aboutText = {};
aboutText{end+1,1} = sprintf('Espresso v%s\n\n',espresso_version());
aboutText{end+1,1} = sprintf('If you use this software, please acknowledge all authors listed in copyright.\n\n');
aboutText{end+1,1} = sprintf('License:\n');

% license text
licenseFilename = 'LICENSE';
licenseText = readlines(licenseFilename);

% text parameters
fontSizeInPoints = 10;
marginsInPixels = 20;
licenseLeftIndentInPixels = 20;

% initialize dialog to cover main figure
mainFigPos = getpixelposition(main_figure);
aboutFig = figure('Name','About','NumberTitle','off', ...
    'Position',mainFigPos,'WindowStyle','modal','Visible','off');
set_icon_espresso(aboutFig);
if ~isdeployed
    set(aboutFig,'Visible','on');
end

% UI control for license
licenseUIC = uicontrol(aboutFig, 'Style', 'text', ...
    'Position', [0, 0, mainFigPos(3), mainFigPos(4)], ...
    'String', licenseText, ...
    'HorizontalAlignment', 'left', ...
    'FontSize', fontSizeInPoints,...
    'Fontname','FixedWidth');
licenseUIC.Position(1) = marginsInPixels + licenseLeftIndentInPixels;
licenseUIC.Position(2) = marginsInPixels; % align to bottom of figure
licenseUIC.Position(4) = licenseUIC.Extent(4); % height to match inner text

% UI control for about section
aboutUIC = uicontrol(aboutFig, 'Style', 'text', 'Position', [0, 0, mainFigPos(3), mainFigPos(4)], ...
    'String', aboutText, ...
    'HorizontalAlignment', 'left', ...
    'FontSize', fontSizeInPoints);
aboutUIC.Position(1) = marginsInPixels;
aboutUIC.Position(2) = marginsInPixels + licenseUIC.Position(4); % align to top of license
aboutUIC.Position(4) = aboutUIC.Extent(4); % height to match inner text

% adjust window width and height to contents
aboutFig.Position(3) = max([aboutUIC.Extent(3),licenseUIC.Extent(3)+licenseLeftIndentInPixels]) ...
    + 2.*marginsInPixels;
aboutFig.Position(4) = aboutUIC.Extent(4) + licenseUIC.Extent(4) ...
    + 2.*marginsInPixels;

% center window
aboutFig.Position(1:2) = mainFigPos(1:2) + round(mainFigPos(3:4)./2) - round(aboutFig.Position(3:4)./2);

% make visible
set(aboutFig,'Visible','on');

end