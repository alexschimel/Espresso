function create_mosaic(~,~,main_figure,mos_type)
%CREATE_MOSAIC  One-line description
%
%   See also ESPRESSO.

%   Authors: Yoann Ladroit (NIWA, yoann.ladroit@niwa.co.nz) and Alex
%   Schimel (NIWA, alexandre.schimel@niwa.co.nz)
%   2017-2021; Last revision: 27-07-2021

select_rect_area(main_figure,@compute_and_add_mosaic,mos_type);




