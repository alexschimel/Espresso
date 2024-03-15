function create_menu(main_figure)
%CREATE_MENU  Create menu on Espresso main window
%
%   Create menu on Espresso main window
%
%   See also ESPRESSO.

%   Copyright 2024 Alexandre Schimel, Yoann Ladroit, NIWA
%   Licensed under MIT. Details on https://github.com/alexschimel/Espresso/

uimenu(main_figure,'Label','About','Callback',{@callback_about,main_figure});

end


%% Callback when pressing the "About" menu
function callback_about(~,~,main_figure)

% about text
[ver, coffeeVer, aknowledgments] = espresso_version();
aboutText = {};
aboutText{end+1,1} = sprintf('Espresso v%s\n',ver);
aboutText{end+1,1} = sprintf('(powered by CoFFee v%s)\n\n',coffeeVer);
aboutText{end+1,1} = sprintf('If you use this software, please acknowledge:\n');
aboutText{end+1,1} = sprintf('%s.\n\n',aknowledgments);
aboutText{end+1,1} = sprintf('License:\n');

% license text
licenseFile = espresso_license_file();
licenseText = readlines(licenseFile);

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