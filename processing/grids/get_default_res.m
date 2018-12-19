%% this_function_name.m
%
% _This section contains a very short description of the function, for the
% user to know this function is part of the software and what it does for
% it. Example below to replace. Delete these lines XXX._
%
% Template of ESP3 function header. XXX
%
%% Help
%
% *USE*
%
% _This section contains a more detailed description of what the function
% does and how to use it, for the interested user to have an overall
% understanding of its function. Example below to replace. Delete these
% lines XXX._
%
% This is a text file containing the basic comment template to add at the
% start of any new ESP3 function to serve as function help. XXX
%
% *INPUT VARIABLES*
%
% _This section contains bullet points of input variables with description
% and information. Put input variable and other valid entries or defaults
% between | symbols so it shows as monospace. Information section to
% contain, in order: requirement (i.e. Required/Optional/Paramter), valid
% type (e.g. Num, Positive num, char, 1xN cell array, etc.) and default
% value if there is one (e.g. Default: '10'). Example below to replace.
% Delete these lines XXX._
%
% * |input_variable_1|: Description (Information). XXX
% * |input_variable_2|: Description (Information). XXX
% * |input_variable_3|: Description (Information). XXX
%
% *OUTPUT VARIABLES*
%
% _This section contains bullet points of output variables with description
% and information. See input variables for template. Example below to
% replace. Delete these lines XXX._
%
% * |output_variable_1|: Description (Information). XXX
% * |output_variable_2|: Description (Information). XXX
%
% *DEVELOPMENT NOTES*
%
% _This section describes what features are temporary, needed future
% developments and paper references. Example below to replace. Delete these
% lines XXX._
%
% * research point 1. XXX
% * research point 2. XXX
%
% *NEW FEATURES*
%
% _This section contains dates and descriptions of major updates. Example
% below to replace. Delete these lines XXX._
%
% * YYYY-MM-DD: second version. Describes the update. XXX
% * YYYY-MM-DD: first version. XXX
%
% *EXAMPLE*
%
% _This section contains examples of valid function calls. Note that
% example lines start with 3 white spaces so that the publish function
% shows them correctly as matlab code. Example below to replace. Delete
% these lines XXX._
%
%   example_use_1; % comment on what this does. XXX
%   example_use_2: % comment on what this line does. XXX
%
% *AUTHOR, AFFILIATION & COPYRIGHT*
%
% _This last section contains at least author name and affiliation. Delete
% these lines XXX._
%
% Yoann Ladroit, Alexandre Schimel, NIWA. XXX

%% Function
function grid = get_default_res(grid,fData_tot)

E_lim = grid.E_lim ;
N_lim = grid.N_lim;

for iF = 1:numel(fData_tot)
    fData = fData_tot{iF};
    grid.fData_ID(iF) = fData.ID;
    
    if ~isfield(fData,'X_1E_gridEasting')
        continue;
    end
    
    E = fData.X_1E_gridEasting;
    N = fData.X_N1_gridNorthing;
    L = fData.X_NEH_gridLevel;
    
    if size(L,3)>1
        data = pow2db_perso(nanmean(10.^(L/10),3));
    else
        data = L;
    end
    
    idx_keep_E = E>E_lim(1)&E<E_lim(2);
    idx_keep_N = N>N_lim(1)&N<N_lim(2);
    
    data(~idx_keep_N,:) = [];
    data(:,~idx_keep_E) = [];
    
    idx_nan = isnan(data);
    data(idx_nan) = [];
    if isempty(data)
        continue;
    end
    grid.res = nanmax(fData.X_1_gridHorizontalResolution,grid.res);
end

numElemGridE = ceil((E_lim(2)-E_lim(1))./grid.res)+1;
numElemGridN = ceil((N_lim(2)-N_lim(1))./grid.res)+1;

grid.name = 'New Grid';
if grid.res>0
    grid.grid_level = zeros(numElemGridN,numElemGridE,'single');
else
    grid.grid_level = single([]);
end


end

function db = pow2db_perso(pow)

pow(pow<0) = nan;
db = 10*log10(pow);

end