function data = CFF_WC_radiometric_corrections_CORE(data, fData, pings, radiomcorr_output)
%CFF_WC_RADIOMETRIC_CORRECTIONS_CORE  One-line description
%
%   See also ESPRESSO.

%   Authors: Alex Schimel (NIWA, alexandre.schimel@niwa.co.nz) and Yoann
%   Ladroit (NIWA, yoann.ladroit@niwa.co.nz)
%   2017-2021; Last revision: 27-07-2021

% XXX1 Need to code radiometric corrections for KMALL

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
    % ... TO DO XXX1
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

% Assuming 30log R if nothing has been specified
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

% Still need to correct for C, but probably need to do all constant terms
% then. XXX1
