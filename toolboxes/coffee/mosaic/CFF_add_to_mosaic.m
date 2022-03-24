function mosaic = CFF_add_to_mosaic(mosaic,x,y,v,varargin)
%CFF_ADD_TO_MOSAIC Update mosaic with new data
%
%   MOSAIC = CFF_ADD_TO_MOSAIC(MOSAIC,X,Y,V) adds data with value V at 
%   coordinates X and Y to an existing MOSAIC, and outputs the updated
%   MOSAIC. MOSAIC is a mosaic structure such as initialized with
%   CFF_INIT_MOSAIC_V2 or resulting from a prior use of CFF_ADD_TO_MOSAIC.
%   X,Y, and V can be all vectors, or all 2D arrays, in which case they
%   need to have matching size. Or V can be a matrix and X and Y its vector
%   coordinates with X as a row vector and Y a column vector.
%
%   CFF_ADD_TO_MOSAIC(...,W) also uses the weights W corresponding to the
%   values V. W must be same size as V, or a single value that applies to
%   all data. By default, W = 1. The MOSAIC field MOSAIC.mode governs how
%   weight is used to update the mosaic. With 'blend', the new and existing
%   data get (possibly weighted) averaged. Actual weights can be used to
%   privilege some data, but by default, the weight of a cell is the number
%   of data points that contributed to a cell value, so the iterative
%   weighted averaging is equivalent to a normal averaging. With 'stitch',
%   we retain for each cell whichever data has largest weight. Actual
%   weights can be used to privilege some data, but by default, the new
%   data takes precedence over the old. 
%
%   Note that the averaging in 'blend' mode is performed on input values V
%   "as is". If V is backscatter data and you don't want to avearge in dB,
%   you need to transform the values before using this function, and apply
%   the reverse transformation when the mosaicking is complete. See
%   CFF_MOSAIC_LINES.
%
%   Note: you need to run CFF_FINALIZE_MOSAIC when you have finished
%   mosaicking.
%
%   See also CFF_MOSAIC_LINES, CFF_INIT_MOSAIC_V2, CFF_FINALIZE_MOSAIC

%   Authors: Alex Schimel (NGU, alexandre.schimel@ngu.no)
%   2017-2022; Last revision: 23-03-2022

% input parser
p = inputParser;
addRequired(p,'mosaic',@(x) isstruct(x));
addRequired(p,'x',@(u) isnumeric(u));
addRequired(p,'y',@(u) isnumeric(u));
addRequired(p,'v',@(u) isnumeric(u));
addOptional(p,'w',1, @(u) isnumeric(u));
parse(p,mosaic,x,y,v,varargin{:});
mosaic = p.Results.mosaic;
x = p.Results.x;
y = p.Results.y;
v = p.Results.v;
w = p.Results.w;
clear p;

% input additional checks and data preparation
if ~isempty(setxor(fieldnames(mosaic),fieldnames(CFF_init_mosaic_v2([0,1,0,1]))))
    error("'mosaic' must be a mosaic struct as produced by CFF_INIT_MOSAIC_V2.");
end
sv = size(v);
sx = size(x);
if ~all(sx==sv)
    if all(sx==[1,sv(2)])
        % meshgrid x
        x = repmat(x,sv(1),1);
    else
        error("'x' must be same size as v or v(1,:).");
    end
end
sy = size(y);
if ~all(sy==sv)
    if all(sy==[sv(1),1])
        % meshgrid y
        y = repmat(y,1,sv(2));
    else
        error("'y' must be same size as v or v(:,1).");
    end
end
if numel(w)==1
    w = w.*ones(sv);
else
    sw = size(w);
    if ~all(sw==sv)
        error("'w' must be same size as v.");
    end
    
end

% vectorize everything
x = x(:);
y = y(:);
v = v(:);
w = w(:);

% remove all data outside of mosaic boundaries, any data with a nan value,
% and data with zero weight
iKeep = x>=mosaic.x_lim(1) & x<=mosaic.x_lim(2) ...
    & y>=mosaic.y_lim(1) & y<=mosaic.y_lim(2) ...
    & ~isnan(x) & ~isnan(y) & ~isnan(v) & ~isnan(w) & w~=0;
x = x(iKeep);
y = y(iKeep);
v = v(iKeep);
w = w(iKeep);

% if ROI was a polygon, we can remove all data outside it
if ~isempty(mosaic.x_pol)
    iKeep = inpolygon(x,y,mosaic.x_pol,mosaic.y_pol);
    x = x(iKeep);
    y = y(iKeep);
    v = v(iKeep);
    w = w(iKeep);
end

% pass grid level in natural before gridding.
% v = 10.^(v./10);
% would also need to be applied to the mosaic


%% mosaic preparation

% indices of new data in the mosaic
iR_y_in_mos = round((y-mosaic.y_lim(1))/mosaic.res+1);
iC_x_in_mos = round((x-mosaic.x_lim(1))/mosaic.res+1);

% indices of block (extract of mosaic where new data will contribute) in
% mosaic  
iR_block = min(iR_y_in_mos):max(iR_y_in_mos);
iC_block = min(iC_x_in_mos):max(iC_x_in_mos);

% indices of new data in block
iR_y_in_blc = iR_y_in_mos - min(iR_y_in_mos) + 1;
iC_x_in_blc = iC_x_in_mos - min(iC_x_in_mos) + 1;

% we start by gridding the new data values in an array the size of the
% block using accumarray. The gridding of weights depend on the mode
subs = [iR_y_in_blc iC_x_in_blc]; % indices of new data in block
sz   = [numel(iR_block) numel(iC_block)]; % size of output array
new_v_blc = accumarray(subs,v,sz,@sum,0);

% get the current values and weights in the block
cur_v_blc = mosaic.value(iR_block,iC_block);
cur_w_blc = mosaic.weight(iR_block,iC_block);

% next we merge the new block data into the current mosaic
switch mosaic.mode
    
    case 'blend'
        % In this mode, the old and new data are blended together. An
        % updated mosaic cell contains the weighted average of old and new
        % data (by default, weight = 1 for each data point).
        
        % the new data weights are the sum of contributing weights
        new_w_blc = accumarray(subs,w,sz,@sum,0);
        
        % updated weight is the sum of current and new block weight
        upd_w_blc = cur_w_blc + new_w_blc;
        
        % updated value is the weighted average of current and new block
        % data
        upd_v_blc = ((cur_v_blc.*cur_w_blc)+(new_v_blc.*new_w_blc))./upd_w_blc;
        
        % we get nans where updated weight is still zero, so we need to
        % reset those updated values to zero
        upd_v_blc(upd_w_blc==0) = 0;
        
        % update mosaic with block values
        mosaic.value(iR_block,iC_block)  = upd_v_blc;
        mosaic.weight(iR_block,iC_block) = upd_w_blc;
        
    case 'stitch'
        % In this mode, there is no averaging. An updated mosaic cell
        % contains either the old or the new data, whichever minimizes the
        % criteria. Typically used with "distance to nadir" as the
        % criteria, which effectively "stitches" lines data together with
        % stitches occuring at equidistance from the vessel tracks.
        
        % the new data weights are the minimum of contributing weights
        new_w_blc = accumarray(subs,w,sz,@min,0);
        
        % get indice of data to retain (1=new, 2=current)
        [~,ind] = max([new_w_blc(:),cur_w_blc(:)],[],2,'omitnan');
        ind = reshape(ind,size(cur_w_blc));
        
        % updated data is old data where ind=1 and new data where ind=2
        mosaic.value(iR_block,iC_block)  = new_v_blc.*(ind==1) + cur_v_blc.*(ind==2);
        mosaic.weight(iR_block,iC_block) = new_w_blc.*(ind==1) + cur_w_blc.*(ind==2);
        
end

end
