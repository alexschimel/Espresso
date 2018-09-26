function data = get_wc_data(fData,fieldN,iPing,dr,db)

switch fieldN
    case 'WCAP_SBP_SampleAmplitudes'
        fact = 1/40;
        nan_val = -2^15;
    case 'WCAP_SBP_SamplePhase'
        fact = 1/30;
        nan_val = 0;
    case 'WC_SBP_SampleAmplitudes'
        fact = 1/2;
        nan_val = -2^7/2;
    otherwise
        fact = 1;
        nan_val = [];
end

if ~isempty(iPing)
    data = single(fData.(fieldN).Data.val(1:dr:end,1:db:end,iPing))*fact;
else
    data = single(fData.(fieldN).Data.val(1:dr:end,1:db:end,:))*fact;
end

if ~isempty(nan_val)
    data(data==nan_val) = nan;
end



























