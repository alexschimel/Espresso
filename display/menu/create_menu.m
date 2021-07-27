function create_menu(main_figure)
%CREATE_MENU  Create menu on Espresso main window
%
%   Obsolete
%
%   See also ESPRESSO.

%   Authors: Yoann Ladroit (NIWA, yoann.ladroit@niwa.co.nz) and Alex
%   Schimel (NIWA, alexandre.schimel@niwa.co.nz)
%   2017-2021; Last revision: 27-07-2021

m_files = uimenu(main_figure,'Label','File(s)','Tag','menufile');

%uimenu(m_files,'Label','Load files','Callback',{@load_files_cback,main_figure});
