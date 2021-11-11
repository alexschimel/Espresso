function inter_samples_distance = CFF_inter_sample_distance(fData)
%CFF_INTER_SAMPLE_DISTANCE  Distance (in m) between two data samples
%
%   X = CFF_INTER_SAMPLE_DISTANCE(fData) returns the distance in meters
%   between two data samples from fData, using the sound speed and sample
%   frequency as recorded in data. Note that sampling frequency may have
%   been modified to account for the decimation in samples.
%
%   See also CFF_CONVERT_ALLDATA_TO_FDATA

%   Authors: Alex Schimel (NIWA, alexandre.schimel@niwa.co.nz) and Yoann
%   Ladroit (NIWA, yoann.ladroit@niwa.co.nz)
%   2017-2021; Last revision: 11-11-2021

% get sound speed and sampling frequency
datagramSource = CFF_get_datagramSource(fData);
switch datagramSource
    case {'WC','AP'}
        sound_speed    = fData.(sprintf('%s_1P_SoundSpeed',datagramSource)); % m/s
        sampling_freq  = fData.(sprintf('%s_1P_SamplingFrequencyHz',datagramSource)); % Hz
    case 'X8'
        sound_speed    = fData.X8_1P_SoundSpeedAtTransducer; % m/s
        sampling_freq  = fData.X8_1P_SamplingFrequencyInHz; % Hz
end

% calculate
inter_samples_distance = sound_speed./(sampling_freq.*2); % in m

