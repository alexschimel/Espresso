function fData_tot = process_watercolumn(fData_tot, idx_fData, procpar)

% initialize processing per file
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
        
        % original data critical info
        wc_dir = CFF_converted_data_folder(fData_tot{itt}.ALLfilename{1});
        dg_source = CFF_get_datagramSource(fData_tot{itt});
        
        % Because water-column data takes so much space, the original data are
        % often limited in precision (e.g. 0.1dB for Kongsberg systems). Processing
        % these data will result in precision that is higher than this, which makes
        % little sense. So inform here whether processed data is to be stored at
        % the precision resulting from the calculations, or at the precision of the
        % original data.
        
        saving_precision = 'original'; % 'original' or 'improved'
        
        % original data storage precision
        wcdata_class  = fData_tot{itt}.(sprintf('%s_1_SampleAmplitudes_Class',dg_source)); % int8 or int16
        wcdata_factor = fData_tot{itt}.(sprintf('%s_1_SampleAmplitudes_Factor',dg_source));
        wcdata_nanval = fData_tot{itt}.(sprintf('%s_1_SampleAmplitudes_Nanval',dg_source));
        
        % processed data storage precision
        switch saving_precision
            case 'improved'
                % processed data will be saved in "single" format to retain the
                % precision of computations, but it will take a bit more space
                % on the disk
                wcdataproc_class   = 'single';
                wcdataproc_factor  = 1;
                wcdataproc_nanval  = NaN;
            case 'original'
                % processed data will be saved in the same format as original
                % raw data, aka in its possibly quite low resolution, but it
                % saves space on the disk
                wcdataproc_class   = wcdata_class;
                wcdataproc_factor  = wcdata_factor;
                wcdataproc_nanval  = wcdata_nanval;
        end
        
        % number, dimensions, and pings of memmap files data
        nMemMapFiles = length(fData_tot{itt}.(sprintf('%s_SBP_SampleAmplitudes',dg_source)));
        [nSamples, nBeams, nPings] = cellfun(@(x) size(x.Data.val),fData_tot{itt}.(sprintf('%s_SBP_SampleAmplitudes',dg_source)));
        ping_gr_start = fData_tot{itt}.(sprintf('%s_n_start',dg_source));
        ping_gr_end   = fData_tot{itt}.(sprintf('%s_n_end',dg_source));
        
        % initialize memmap files for processed data
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
        
        for ig = 1:nMemMapFiles
            
            % pings in this memmap file
            iPings = ping_gr_start(ig):ping_gr_end(ig);
            
            % block processing setup
            mem_struct = memory;
            blockLength = ceil(mem_struct.MemAvailableAllArrays/(nSamples(ig)*nBeams(ig)*8)/20);
            nBlocks = ceil(nPings(ig)./blockLength);
            blocks = [ 1+(0:nBlocks-1)'.*blockLength , (1:nBlocks)'.*blockLength ];
            blocks(end,2) = nPings(ig);
            
            % processing per block of pings in memmap file
            for iB = 1:nBlocks
                
                % list of pings in this block
                blockPings  = (blocks(iB,1):blocks(iB,2));
                
                % corresponding pings in file
                blockPings_f  = iPings(blocks(iB,1):blocks(iB,2));
                
                % grab original data in dB
                data = CFF_get_WC_data(fData_tot{itt},sprintf('%s_SBP_SampleAmplitudes',CFF_get_datagramSource(fData_tot{itt})),'iPing',blockPings_f,'iRange',1:nSamples(ig),'output_format','true');
                
                % radiometric corrections
                if procpar.radiomcorr_flag
                    data = CFF_WC_radiometric_corrections_CORE(data,fData_tot{itt}, blockPings_f, procpar.radiomcorr_output);
                end
                
                % filtering sidelobe artefact
                if procpar.sidelobefilter_flag
                    [data, correction] = CFF_filter_WC_sidelobe_artifact_CORE(data, fData_tot{itt}, blockPings_f);
                    % uncomment this for weighted gridding based on sidelobe correction
                    % fData_tot{itt}.X_S1P_sidelobeArtifactCorrection(:,:,blockPings) = correction;
                end
                
                % masking data
                if procpar.masking_flag
                    data = CFF_mask_WC_data_CORE(data, fData_tot{itt}, blockPings_f, procpar.mask_angle, procpar.mask_closerange, procpar.mask_bottomrange, [], procpar.mask_ping);
                end
                
                % convert result back to raw format and store through memmap
                if wcdataproc_factor ~= 1
                    data = data./wcdataproc_factor;
                end
                
                if ~isnan(wcdataproc_nanval)
                    data(isnan(data)) = wcdataproc_nanval;
                end
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

