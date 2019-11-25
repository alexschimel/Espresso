%% Function
function interSamplesDistance = CFF_inter_sample_distance(fData)

% Source datagram
datagramSource = CFF_get_datagramSource(fData);

% inter-sample distance
soundSpeed           = fData.(sprintf('%s_1P_SoundSpeed',datagramSource)); %m/s
samplingFrequencyHz  = fData.(sprintf('%s_1P_SamplingFrequencyHz',datagramSource)); %Hz


interSamplesDistance = soundSpeed./(samplingFrequencyHz.*2); % in m
