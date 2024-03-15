function check_fmt_box(src,~,min_val,max_val,deflt_val,precision)
%CHECK_FMT_BOX  One-line description
%
%   See also ESPRESSO.

%   Copyright 2017-2021 Alexandre Schimel, Yoann Ladroit, NIWA
%   Licensed under MIT. Details on https://github.com/alexschimel/Espresso/

E = str2double(get(src,'string'));

if ~isnan(E) && isnumeric(E)
    if E >= min_val && E <=max_val
        set(src,'string',num2str(E,precision));
    elseif E < min_val
        set(src,'string',num2str(min_val,precision));
    elseif E > max_val
        set(src,'string',num2str(max_val,precision));
    end
else
    set(src,'string',num2str(deflt_val,precision));
end


end