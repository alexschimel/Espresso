%% CFF_update_value_and_weight.m
%
% adds the value and weight (v,w) to an existing value and
% weight (vi,wi) to output an updated value/weight (vi,wi). The core
% function behind adding a point to a grid
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
% TODO: write research notes
%
% *NEW FEATURES*
%
% * 2017-10-06: first version. Built for CFF_weightgrid_2D and
% CFF_weightgrid_3D (Alex Schimel) 
%
% *EXAMPLE*
%
% TODO: write examples
%
% *AUTHOR, AFFILIATION & COPYRIGHT*
%
% Alexandre Schimel, NIWA.

%% Function
function [vi,wi] = CFF_update_value_and_weight(v,w,vi,wi)
vi = (vi.*wi + v.*w)./(wi+w);
wi = wi+w;