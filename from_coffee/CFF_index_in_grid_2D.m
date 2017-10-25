%% CFF_index_in_grid_2D.m
%
% finds where in a grid (xi,yi) does one point (x,y) falls
% in, using the first values and step of the grid, rather than the grid
% itself. Returns the index of the grid.
%
%% Help
%
% *USE*
%
% TODO: write longer description of function
%
% *INPUT VARIABLES*
%
% * |input_variable_1|: TODO: write description and info on variable
%
% *OUTPUT VARIABLES*
%
% * |output_variable_1|: TODO: write description and info on variable
%
% *RESEARCH NOTES*
%
% that function should also works with several points, returning several
% indices. 
%
% *NEW FEATURES*
%
% * 2017-10-06: first version. Built for CFF_weightgrid_2D (Alex Schimel)
%
% *EXAMPLE*
%
% TODO: write examples
%
% *AUTHOR, AFFILIATION & COPYRIGHT*
%
% Alexandre Schimel, NIWA.

%% Function
function [i_xi,i_yi] = CFF_index_in_grid_2D(x,y,xi_firstval,yi_firstval,xi_step,yi_step)

i_xi = round(((x-xi_firstval)./xi_step)+1);
i_yi = round(((y-yi_firstval)./yi_step)+1);