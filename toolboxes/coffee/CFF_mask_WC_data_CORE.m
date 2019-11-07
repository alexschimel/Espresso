%% CFF_mask_WC_data_CORE.m
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
function data = CFF_mask_WC_data_CORE(data, fData, blockPings, varargin)

% input parsing
try remove_angle = varargin{1};
catch
    remove_angle = inf; % default
end
try remove_closerange = varargin{2};
catch
    remove_closerange = 0; % default
end
try remove_bottomrange = varargin{3};
catch
    remove_bottomrange = inf; % default
end
try mypolygon = varargin{4}; 
catch
    mypolygon = []; % default
end

% data size
[nSamples, nBeams, ~] = size(fData.(sprintf('%s_SBP_SampleAmplitudes',fData.MET_datagramSource)).Data.val);
nPings = numel(blockPings);

% source datagram
datagramSource = fData.MET_datagramSource;

% calculate inter-sample distance
soundSpeed          = fData.(sprintf('%s_1P_SoundSpeed',datagramSource)); %m/s
samplingFrequencyHz = fData.(sprintf('%s_1P_SamplingFrequencyHz',datagramSource)); %Hz
dr_samples = soundSpeed./(samplingFrequencyHz.*2);
dr_samples = dr_samples(blockPings);

% MASK 1: OUTER BEAMS REMOVAL
if ~isinf(remove_angle)
    
    % extract needed data
    angles = fData.(sprintf('%s_BP_BeamPointingAngle',datagramSource))(:,blockPings);
    
    % build mask: 1: to conserve, 0: to remove
    X_BP_OuterBeamsMask = angles>=-abs(remove_angle) & angles<=abs(remove_angle);
    
    X_1BP_OuterBeamsMask = permute(X_BP_OuterBeamsMask ,[3,1,2]);
    
else
    
    % conserve all data
    X_1BP_OuterBeamsMask = true(1,nBeams,nPings);
    
end

% MASK 2: CLOSE RANGE REMOVAL
if remove_closerange>0
    
    % extract needed data
    ranges = CFF_get_samples_range( (1:nSamples)', fData.(sprintf('%s_BP_StartRangeSampleNumber',datagramSource))(:,blockPings), dr_samples);
    
    % build mask: 1: to conserve, 0: to remove
    X_SBP_CloseRangeMask = ranges>=remove_closerange;
    
else
    
    % conserve all data
    X_SBP_CloseRangeMask = true(nSamples,nBeams,nPings);
    
end

% MASK 3: BOTTOM RANGE REMOVAL
if ~isinf(remove_bottomrange)
    
    % beam pointing angle
    theta = deg2rad(fData.(sprintf('%s_BP_BeamPointingAngle',datagramSource))(:,blockPings));
    
    % beamwidth (nominal and with steering)
    psi = deg2rad(fData.Ru_1D_ReceiveBeamwidth(1)./10);
    psi = psi./cos(abs(theta)).^2/2;
    
    % transition between normal and grazing incidence
    %         theta_lim = psi/2;
    %         idx_normal = abs(theta) < theta_lim;
    %         idx_grazing = ~idx_normal;
    %
    % length of bottom echo? XXX
    %    M = zeros(size(theta),'single');
    %         M(idx_normal)  = ( 1./cos(theta(idx_normal)+psi(idx_normal)/2)   - 1./cos(theta(idx_normal)) ) .* fData.X_BP_bottomRange(idx_normal,blockPings);
    %         M(idx_grazing) = 2*( sin(theta(idx_grazing)+psi(idx_grazing)/2) - sin(theta(idx_grazing)-psi(idx_grazing)/2) ) .* fData.X_BP_bottomRange(idx_grazing,blockPings);
    M =2* (sin(abs(theta)+psi/2) - sin(abs(theta)-psi/2) ) .* fData.X_BP_bottomRange(:,blockPings);
    % calculate max sample beyond which mask is to be applied
    X_BP_maxRange  = fData.X_BP_bottomRange(:,blockPings) + remove_bottomrange - abs(M);
    X_BP_maxSample = bsxfun(@rdivide,X_BP_maxRange,dr_samples);
    X_BP_maxSample = round(X_BP_maxSample);
    X_BP_maxSample(X_BP_maxSample>nSamples|isnan(X_BP_maxSample)) = nSamples;
    
    % build list of indices for each beam & ping
    [PP,BB] = meshgrid((1:nPings),(1:nBeams));
    maxSubs = [X_BP_maxSample(:),BB(:),PP(:)];
    
    % build mask: 1: to conserve, 0: to remove
    X_SBP_BottomRangeMask = false(nSamples,nBeams,nPings);
    for ii = 1:size(maxSubs,1)
        X_SBP_BottomRangeMask(1:maxSubs(ii,1),maxSubs(ii,2),maxSubs(ii,3)) = true;
    end
    
else
    
    % conserve all data
    X_SBP_BottomRangeMask = true(nSamples,nBeams,nPings);
    
end

% MASK 4: OUTSIDE POLYGON REMOVAL
if ~isempty(mypolygon)
    
    % build mask: 1: to conserve, 0: to remove
    X_SBP_PolygonMask = inpolygon( fData.X_SBP_sampleEasting.Data.val(:,:,blockPings), ...
        fData.X_SBP_sampleNorthing.Data.val(:,:,blockPings), ...
        mypolygon(:,1), ...
        mypolygon(:,2));
    
else
    
    % conserve all data
    X_SBP_PolygonMask = true(nSamples,nBeams,nPings);
    
end

% MULTIPLYING ALL MASKS
mask = bsxfun(@and,X_1BP_OuterBeamsMask,(X_SBP_CloseRangeMask & X_SBP_BottomRangeMask & X_SBP_PolygonMask));

% apply mask
data(~mask) = NaN;





