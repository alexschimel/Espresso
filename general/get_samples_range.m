function sampleRange = get_samples_range(idx_samples,start_sample_range,dr)

start_sample_range = permute(start_sample_range,[3,1,2]);
dr = permute(dr,[3,1,2]); 

sampleRange = bsxfun(@times,bsxfun(@plus,idx_samples,start_sample_range),dr);

end