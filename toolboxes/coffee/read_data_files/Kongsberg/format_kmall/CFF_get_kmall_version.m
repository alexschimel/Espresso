function kmall_version = CFF_get_kmall_version(EMdgmIIP)

idx = strfind(EMdgmIIP.install_txt,'KMALL:Rev ') + 10;
kmall_version = EMdgmIIP.install_txt(idx);

end