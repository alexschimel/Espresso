function[maxNSamples_groups,ping_group_start,ping_group_end]=CFF_group_pings_per_samples(numberOfSamples,pingCounters,EM_PingCounters)


maxNSamples_1P=nan(1,numel(pingCounters));
for ii=1:numel(pingCounters)
    ix=EM_PingCounters==pingCounters(ii);
    maxNSamples_1P(ii)=max(cellfun(@(x) max(x),numberOfSamples(ix)));
end

nb_min_s=50;
nb_min_win=100;
%div_factor=nanmax(nanmin(maxNSamples_1P)/4,nb_min_s);
div_factor=mode(ceil(maxNSamples_1P/nb_min_s)*nb_min_s);

group_by_nb_s=ceil(filter2(ones(1,nb_min_win),(maxNSamples_1P/div_factor),'same')./...
    filter2(ones(1,nb_min_win),ones(size(pingCounters)),'same'));
idx_change=find(diff(group_by_nb_s)~=0);


idx_new_group=[1 idx_change];

ping_group_start=pingCounters(idx_new_group);
ping_group_end=pingCounters([idx_new_group(2:end)-1 numel(pingCounters)]);
maxNSamples_groups=nan(1,numel(idx_new_group));
for uig=1:numel(idx_new_group)
    ix=ismember(EM_PingCounters,ping_group_start(uig):ping_group_end(uig));
    maxNSamples_groups(uig)=max(cellfun(@(x) max(x),numberOfSamples(ix)));
end

ping_group_start=ping_group_start-pingCounters(1)+1;
ping_group_end=ping_group_end-pingCounters(1)+1;

% 
% figure();
%plot(pingCounters,ceil(maxNSamples_1P/div_factor));hold on;plot(pingCounters,group_by_nb_s);hold on;plot(pingCounters,maxNSamples_1P/div_factor);
% for uil=1:numel(idx_change)
%     xline(pingCounters(idx_change(uil)));
% end
