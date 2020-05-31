function inter_samples_distance = CFF_inter_sample_distance(fData)
%INTER_SAMPLES_DISTANCE Distance in meters between two data samples
%   inter_samples_distance = INTER_SAMPLES_DISTANCE(fData) returns the
%   distance in meters between two data samples in fData, using the sound
%   speed and sample frequency as recorded in data. Note that sampling
%   frequency may have been modified to account for the decimation in
%   samples

dtg = CFF_get_datagramSource(fData);

sound_speed = fData.(sprintf('%s_1P_SoundSpeed',dtg)); % m/s

sampling_freq  = fData.(sprintf('%s_1P_SamplingFrequencyHz',dtg)); % Hz

inter_samples_distance = sound_speed./(sampling_freq.*2); % in m
