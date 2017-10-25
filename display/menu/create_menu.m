function create_menu(main_figure)

m_files = uimenu(main_figure,'Label','File(s)','Tag','menufile');
uimenu(m_files,'Label','Load files','Callback',{@load_files_cback,main_figure});
