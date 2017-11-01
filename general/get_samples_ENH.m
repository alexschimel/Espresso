
function [E,N,H]=get_samples_ENH(sonarE,sonarN,sonarH,heading,sampleAcrossDist,sampleUpDist)

sonarH = permute(sonarH,[3,1,2]);
sonarE = permute(sonarE,[3,1,2]); 
sonarN = permute(sonarN,[3,1,2]); 
heading = permute(heading,[3,1,2]);

E  = bsxfun(@plus,sonarE,bsxfun(@times,sampleAcrossDist,cos(heading)));
N = bsxfun(@plus,sonarN,bsxfun(@times,sampleAcrossDist,sin(heading)));
H  = bsxfun(@plus,sonarH,sampleUpDist);

end
