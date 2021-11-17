function R = CFF_3Drotmat(rotAngle,varargin)
% Rotation matrix for a given angle about a given axis.
% By default angle in radians, but can be specified in degrees with
% argument 'unit'.
% A set of angles can be specified to output a set of rotation matrices. In
% that case, the angle input must be a vector (row or column). The rotation
% matrices in output will be 3x3xN matrices with N being the number of
% angles requested in input.
%
% NOTE: HOW TO USE A ROTATION MATRIX
%
% Vector rotation: In a coordinate system (x,y,z), a 3D column vector v =
% [x;y;z] rotated about an axis will result in a new 3D column vector v'
% with coordinates [x';y';z'] = R*v;
%
% Axes rotation: Considering a new coordinate system (x',y',z') created
% from an earlier coordinate system (x,y,z) by rotation about an axis, a
% vector v with coordinates [x;y;z] in the older system will have
% coordinates R'*v in the new system.
%
% In all cases, the rotation follows the standard counter-clockwise rule,
% e.g. a positive rotation about the x axis is a rotation from y towards z
% (for y: from z towards x. For z; from x towards y).

% parsing inputs
p = inputParser;
addRequired(p,'rotAngle',@mustBeVector);
addOptional(p,'rotAxis','x',@(x) ismember(x,{'x','y','z'}));
addOptional(p,'angleUnit','rad',@(x) ismember(x,{'r','rad','radians','d','deg','degrees'}));
parse(p,rotAngle,varargin{:});
ff = fields(p.Results);
for ii = 1:numel(ff)
    eval(sprintf('%s = p.Results.%s;',ff{ii},ff{ii}));
end
clear p

% turn degrees to radians if necessary
switch angleUnit
    case {'d','deg','degrees'}
        rotAngle = deg2rad(rotAngle);
end

% make rotAngle a 3rd-dimension vector
rotAngle = permute(reshape(rotAngle,1,[]),[1,3,2]);
n = numel(rotAngle);

% rotation matrix elements as 3rd-dimension vectors
O = zeros(1,1,n);
I = ones(1,1,n);
C = cos(rotAngle);
S = sin(rotAngle);

% create rotation matrices
switch rotAxis
    case 'x'
        R = [[ I, O   O ];...
            [  O, C, -S ];...
            [  O, S,  C ]];
        
    case 'y'
        R = [[ C, O, S ];...
            [  O, I, O ];...
            [ -S, O, C ]];
                 
    case 'z'
        R = [[ C, -S, O ];...
            [  S,  C, O ];...
            [  O,  O, I ]];     
end