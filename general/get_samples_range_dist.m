function [sampleRange,sampleAcrossDist,sampleUpDist]=get_samples_range_dist(idx_samples,start_sample_range,dr,beam_point_angle)

start_sample_range= permute(start_sample_range,[3,1,2]);
dr= permute(dr,[3,1,2]); 

beam_point_angle= permute(beam_point_angle,[3,1,2]);

sampleRange = bsxfun(@times,bsxfun(@plus,idx_samples,start_sample_range),dr);

sampleUpDist     = bsxfun(@times,-sampleRange,cos(beam_point_angle));
sampleAcrossDist = bsxfun(@times,-sampleRange,sin(beam_point_angle));

end