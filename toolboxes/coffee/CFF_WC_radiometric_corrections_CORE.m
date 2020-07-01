%% CFF_WC_radiometric_corrections_CORE.m
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
function data = CFF_WC_radiometric_corrections_CORE(data, fData, pings, radiomcorr_output)


%% Transmit Power level reduction
% This is the "mammal protection" setting, which is recorded in Runtime
% Parameters datagram
TPRM = fData.Ru_1D_TransmitPowerReMaximum;
if numel(unique(TPRM)) == 1
    % This value does not change in the file
    TPRM = TPRM(1).*ones(size(data));
else
    % dB offset changed within the file. 
    % Would need to check when runtime parameters are being issued. Whether
    % they are triggered with any change for example. Will likely need to
    % extract and compare the time of Ru and WC datagrams to find which db
    % offset applies to which pings.
    % ... TO DO XXX
    % for now we will just take the first value and apply to everything
    % so that processing can continue...
    warning('Transmit Power level reduction not constant within the file. Radiometric correction inappropriate');
    TPRM = TPRM(1).*ones(size(data));
end


%% TVG applied in reception
%
% From Kongsberg datagrams manual:
% "The TVG function applied to the data is X logR + 2 Alpha R + OFS + C.
% The parameters X and C is documented in this datagram. OFS is gain offset
% to compensate for TX Source Level, Receiver sensitivity etc."
dg_source = CFF_get_datagramSource(fData);

X = fData.(sprintf('%s_1P_TVGFunctionApplied',dg_source))(pings);
C = fData.(sprintf('%s_1P_TVGOffset',dg_source))(pings);

%assuming 30 log10 f nothing has been specified
X(isnan(X)) = 30;
C(isnan(C)) = 0;

% Appropriate X in TVG would have been (not taking into account constant
% factors: 
% * For backscatter per unit volume (Sv): 20*log(R)
% * For backscatter per unit surface (Sa/BS): 30*log(R)
% * For target strength (TS): 40*log(R).
%
% So we will apply to data +Xcorr*log(R), with Xcorr:
switch radiomcorr_output
    case 'Sv'
        Xcorr = 20-X;
    case 'Sa'
        Xcorr = 30-X;
    case 'TS'
        Xcorr = 40-X;
end
Xcorr = permute(Xcorr,[3,1,2]);

% get sample range
nSamples = size(data,1);
interSamplesDistance = CFF_inter_sample_distance(fData);
interSamplesDistance = interSamplesDistance(pings);
datagramSource = fData.MET_datagramSource;
ranges = CFF_get_samples_range( (1:nSamples)', fData.(sprintf('%s_BP_StartRangeSampleNumber',datagramSource))(:,pings), interSamplesDistance);

% apply to data
data = data + Xcorr.*log10(ranges) + TPRM;

% TO DO XXX
% Still need to correct for C, but probably need to do all constant terms
% then.
