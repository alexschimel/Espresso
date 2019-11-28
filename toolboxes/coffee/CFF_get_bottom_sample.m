function X_BP_bottomSample=CFF_get_bottom_sample(fData)

datagramSource=CFF_get_datagramSource(fData);

if isfield(fData,sprintf('X_BP_bottomSample_%s',datagramSource))
    X_BP_bottomSample = fData.(sprintf('X_BP_bottomSample_%s',datagramSource)); %in sample number
else
    X_BP_bottomSample = fData.(sprintf('%s_BP_DetectedRangeInSamples',datagramSource)); %in sample number
    X_BP_bottomSample(X_BP_bottomSample==0) = NaN;
end