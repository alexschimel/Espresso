function fData_tot = process_watercolumn(fData_tot, idx_fData, procpar)

% init
u = 0;
timer_start = now;

for itt = idx_fData(:)'
    
    try
       
        % disp
        u = u+1;
        fprintf('Processing data in file "%s" (%i/%i)...\n',fData_tot{itt}.ALLfilename{1},u,numel(idx_fData));
        textprogressbar(sprintf('...Started at %s. Progress:',datestr(now)));
        textprogressbar(0);
        
        tic
        
        % original data filename and format info
        wc_dir = CFF_converted_data_folder(fData_tot{itt}.ALLfilename{1});
        
        dg_source = CFF_get_datagramSource(fData_tot{itt});
        
        [nSamples, nBeams, nPings] = cellfun(@(x) size(x.Data.val),fData_tot{itt}.(sprintf('%s_SBP_SampleAmplitudes',dg_source)));
        
        wcdata_class  = fData_tot{itt}.(sprintf('%s_1_SampleAmplitudes_Class',CFF_get_datagramSource(fData_tot{itt}))); % int8 or int16
        wcdata_factor = fData_tot{itt}.(sprintf('%s_1_SampleAmplitudes_Factor',CFF_get_datagramSource(fData_tot{itt})));
        wcdata_nanval = fData_tot{itt}.(sprintf('%s_1_SampleAmplitudes_Nanval',CFF_get_datagramSource(fData_tot{itt})));
        
        % processed data filename
        
        ping_gr_start = fData_tot{itt}.(sprintf('%s_n_start',dg_source));
        ping_gr_end   = fData_tot{itt}.(sprintf('%s_n_end',dg_source));
        
        fData_tot{itt} = CFF_init_memmapfiles(fData_tot{itt},...
            'wc_dir',wc_dir,...
            'field','X_SBP_WaterColumnProcessed',...
            'Class',wcdata_class,...
            'Factor',wcdata_factor,...
            'Nanval',wcdata_nanval,...
            'MaxSamples',nSamples,...
            'MaxBeams',nanmax(nBeams),...
            'ping_group_start',ping_gr_start,...
            'ping_group_end',ping_gr_end);
        
        saving_method = 'low_precision'; % 'low_precision' or 'high_precision'
        
        switch saving_method
            case 'low_precision'
                % processed data will be saved in the same format as original
                % raw data, aka in its possibly quite low resolution, but it
                % saves space on the disk
                wcdataproc_class   = wcdata_class;
                wcdataproc_factor  = wcdata_factor;
                wcdataproc_nanval  = wcdata_nanval;
            case 'high_precision'
                % processed data will be saved in "single" format to retain the
                % precision of computations, but it will take a bit more space
                % on the disk
                wcdataproc_class   = 'single';
                wcdataproc_factor  = 1;
                wcdataproc_nanval  = NaN;
        end
        
        for ig = 1:numel(nSamples)
            % processed data format
            
            % block processing setup
            mem_struct = memory;
            blockLength = ceil(mem_struct.MemAvailableAllArrays/(nSamples(ig)*nBeams(ig)*8)/20);
            nBlocks = ceil(nPings(ig)./blockLength);
            blocks = [ 1+(0:nBlocks-1)'.*blockLength , (1:nBlocks)'.*blockLength ];
            blocks(end,2) = nPings(ig);
            iPings = ping_gr_start(ig):ping_gr_end(ig);
            % processing per block of pings in file
            for iB = 1:nBlocks
                
                % list of pings in this block
                blockPings_f  = iPings(blocks(iB,1):blocks(iB,2));
                blockPings  = (blocks(iB,1):blocks(iB,2));
                
                % grab original data in dB
                data = CFF_get_WC_data(fData_tot{itt},sprintf('%s_SBP_SampleAmplitudes',CFF_get_datagramSource(fData_tot{itt})),'iPing',blockPings_f,'iRange',1:nSamples(ig),'output_format','true');
                
                % radiometric corrections
                % add a radio button to possibly turn this off too? TO DO XXX
                [data, warning_text] = CFF_WC_radiometric_corrections_CORE(data,fData_tot{itt});
                
                % filtering sidelobe artefact
                if procpar.sidelobefilter_flag
                    [data, correction] = CFF_filter_WC_sidelobe_artifact_CORE(data, fData_tot{itt}, blockPings_f);
                    % uncomment this for weighted gridding based on sidelobe
                    % correction
                    % fData_tot{itt}.X_S1P_sidelobeArtifactCorrection(:,:,blockPings) = correction;
                end
                
                % masking data
                if procpar.masking_flag
                    data = CFF_mask_WC_data_CORE(data, fData_tot{itt}, blockPings_f, procpar.mask_angle, procpar.mask_closerange, procpar.mask_bottomrange, [], procpar.mask_ping);
                end
                if wcdataproc_factor ~= 1
                    data = data./wcdataproc_factor;
                end
                
                if ~isnan(wcdataproc_nanval)
                    data(isnan(data)) = wcdataproc_nanval;
                end
                
                % convert result back to raw format and store through memmap
                if strcmp(class(data),wcdataproc_class)
                    fData_tot{itt}.X_SBP_WaterColumnProcessed{ig}.Data.val(:,:,blockPings) = data;
                else
                    fData_tot{itt}.X_SBP_WaterColumnProcessed{ig}.Data.val(:,:,blockPings) = cast(data,wcdataproc_class);
                end
                
                % disp block processing progress
                textprogressbar(round(iB.*100./nBlocks)-1);
                
            end
            
            
        end
        
        % save the updated fData on the drive
        fData = fData_tot{itt};
        folder_for_converted_data = CFF_converted_data_folder(fData.ALLfilename{1});
        mat_fdata_file = fullfile(folder_for_converted_data,'fData.mat');
        save(mat_fdata_file,'-struct','fData','-v7.3');
        clear fData;
        
        % disp
        textprogressbar(100)
        textprogressbar(sprintf(' done. Elapsed time: %f seconds.\n',toc));
        
        % throw warning
        if ~isempty(warning_text)
            warning(warning_text);
        end
        
    catch err
        [~,f_temp,e_temp] = fileparts(err.stack(1).file);
        err_str = sprintf('Error in file %s, line %d',[f_temp e_temp],err.stack(1).line);
        fprintf('%s: ERROR processing file %s \n%s\n',datestr(now,'HH:MM:SS'),fData_tot{itt}.ALLfilename{1},err_str);
        fprintf('%s\n\n',err.message);
    end
    
end

% finalize
timer_end = now;
fprintf('Total time for processing: %f seconds (~%.2f minutes).\n\n',(timer_end-timer_start)*24*60*60,(timer_end-timer_start)*24*60);

end

