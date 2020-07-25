function fData = CFF_set_bottom_sample(fData,bot)

datagramSource = CFF_get_datagramSource(fData);
fData.(sprintf('X_BP_bottomSample_%s',datagramSource)) = bot; %in sample number
