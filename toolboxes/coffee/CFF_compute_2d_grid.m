function [gridN,gridE,gridNan]=CFF_compute_2d_grid(fData,varargin)

% init
p = inputParser;

addParameter(p,'grid_horz_res',1,@(x) isnumeric(x)&&x>0);

addParameter(p,'grdlim_east',[],@isnumeric);
addParameter(p,'grdlim_north',[],@isnumeric);

% parse
parse(p,varargin{:})
E=fData.X_BP_bottomEasting;
N=fData.X_BP_bottomENorthing;
Pings=uniques(fData.X_1P_PingCounter);

nPings=numel(Pings);

% block processing setup
mem_struct = memory;
blockLength = ceil(mem_struct.MemAvailableAllArrays/(nSamples*nBeams*8)/20);
nBlocks = ceil(nPings./blockLength);
blocks = [ 1+(0:nBlocks-1)'.*blockLength , (1:nBlocks)'.*blockLength ];
blocks(end,2) = nPings;


% initialize vectors
minBlockE = nan(1,nBlocks);
minBlockN = nan(1,nBlocks);
maxBlockE = nan(1,nBlocks);
maxBlockN = nan(1,nBlocks);

for iB = 1:nBlocks
    
    % list of pings in this block
    blockPings = blocks(iB,1):blocks(iB,2);
    
    blockN=N(:,blockPings);
    blockE=E(:,blockPings);
    
    %id_keep=blockH<d_max;
    
    % these subset of all samples should be enough to find the bounds for the entire block
    minBlockE(iB) = min(blockE(:));
    maxBlockE(iB) = max(blockE(:));
    minBlockN(iB) = min(blockN(:));
    maxBlockN(iB) = max(blockN(:));
    
end

gridE=min(minBlockE):p.Results.grid_horz_res:max(maxBlockE);
gridN=min(minBlockE):p.Results.grid_horz_res:max(maxBlockE);

E_idx=ceil((E(:)-gridE(1))/p.Results.grid_horz_res);
N_idx=ceil((N(:)-gridN(1))/p.Results.grid_horz_res);


subs    = single([N_idx' E_idx']); 
sz      = single([N_N N_E]);      

gridNan = accumarray(subs,ones(numel(E)),sz,@(x) sum(x)>0,false);



