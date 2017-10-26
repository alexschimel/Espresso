function check_fmt_box(src,evt,min_val,max_val,deflt_val,precision)

E = str2double(get(src,'string'));

if ~isnan(E)&&isnumeric(E)
    if E >= max_val && E <=min_val
        set(hObject_S,'value',E)
    elseif E < min_val
        set(src,'string',num2str(min_val,precision))
    elseif E > max_val
        set(src,'string',num2str(max_val,precision))
    end
else
    set(src,'string',num2str(deflt_val,precision));
end


end