function check_fmt_box(src,~,min_val,max_val,deflt_val,precision)
%CHECK_FMT_BOX  One-line description
%
%   See also ESPRESSO.

%   Authors: Yoann Ladroit (NIWA, yoann.ladroit@niwa.co.nz) and Alex
%   Schimel (NIWA, alexandre.schimel@niwa.co.nz)
%   2017-2021; Last revision: 27-07-2021

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