function kmall_version = CFF_get_kmall_version(EMdgmIIP)
%CFF_GET_KMALL_VERSION  Get the KMALL format version (single letter)
%
%   See also ESPRESSO.

%   Authors: Alex Schimel (NIWA, alexandre.schimel@niwa.co.nz) and Yoann
%   Ladroit (NIWA, yoann.ladroit@niwa.co.nz)
%   2017-2021; Last revision: 27-07-2021

idx = strfind(EMdgmIIP.install_txt,'KMALL:Rev ') + 10;
kmall_version = EMdgmIIP.install_txt(idx);

end