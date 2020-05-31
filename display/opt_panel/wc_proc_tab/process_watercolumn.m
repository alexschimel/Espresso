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
        
        % Water-column data takes A LOT of space. Because of this, the
        % original data are limited in precision so that they can be coded
        % with less bytes. But this also limits the range available. For
        % example, Kongsberg data have 0.5dB resolution in order to be
        % coded directly in int8. The range of values possible are -63.5dB
        % to 64dB. 
        % After processing data, we may want to maintain the resolution of
        % the processed result, and values may fall outside of these
        % bounds. 
        % Here, we're going to use the desired saving precision
        % these data will result in precision that is higher than this, which makes
        % little sense. So inform here whether processed data is to be stored at
        % the precision resulting from the calculations, or at the precision of the
        % original data.
        
        saving_precision = '1 byte'; % '1 byte' or '2 bytes'
        
        % original data storage precision
        wcdata_Class  = fData_tot{itt}.(sprintf('%s_1_SampleAmplitudes_Class',dg_source)); % int8 or int16
        wcdata_Factor = fData_tot{itt}.(sprintf('%s_1_SampleAmplitudes_Factor',dg_source));
        wcdata_Nanval = fData_tot{itt}.(sprintf('%s_1_SampleAmplitudes_Nanval',dg_source));
        wcdata_Offset = fData_tot{itt}.(sprintf('%s_1_SampleAmplitudes_Offset',dg_source));
        
        % processed data storage precision
        switch saving_precision
            case '2 bytes'
                % 2 bytes allow storage of 65535 different values, allowing
                % for example a dynamic range of 655 dB at 0.01 dB precision
                wcdataproc_Class   = 'uint16';
            case '1 byte'
                % 1 byte allows storage of 255 difference values, allowing
                % for example a dynamic range of 25 dB at 0.1 dB precision, or
                % 127 at 0.5 dB precision.
                wcdataproc_Class   = 'uint8';
        end
        
        % number, dimensions, and pings of memmap files data
        nMemMapFiles = length(fData_tot{itt}.(sprintf('%s_SBP_SampleAmplitudes',dg_source)));
        [nSamples, nBeams, nPings] = cellfun(@(x) size(x.Data.val),fData_tot{itt}.(sprintf('%s_SBP_SampleAmplitudes',dg_source)));
        ping_gr_start = fData_tot{itt}.(sprintf('%s_n_start',dg_source));
        ping_gr_end   = fData_tot{itt}.(sprintf('%s_n_end',dg_source));
        
        % create empty binary files for processed data and memory-map them
        % in fData 
        newfieldname = 'X_SBP_WaterColumnProcessed';
        fData_tot{itt} = CFF_init_memmapfiles(fData_tot{itt},...
            'field', newfieldname, ...
            'wc_dir', wc_dir, ...
            'Class', wcdataproc_Class, ...
            'Factor', NaN, ... % to be informed later, from data
            'Nanval', intmin(wcdataproc_Class), ...
            'Offset', NaN, ... % to be informed later, from data
            'MaxSamples', nSamples, ...
            'MaxBeams', nanmax(nBeams), ...
            'ping_group_start', ping_gr_start, ...
            'ping_group_end', ping_gr_end);
        
        for ig = 1:nMemMapFiles
            
            % pings in this memmap file
            iPings = ping_gr_start(ig):ping_gr_end(ig);
            
            % block processing setup
            mem = CFF_memory_available;
            blockLength = ceil(mem/(nSamples(ig)*nBeams(ig)*8)/20);
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
                
                % transform data for storage
                minsrc = floor(min(data(:)));
                maxsrc = ceil(max(data(:)));
                mindest = single(intmin(wcdataproc_Class)+1); % the min value is reserved for NaN
                maxdest = single(intmax(wcdataproc_Class));
                transform_factor = (maxdest-mindest)./(maxsrc-minsrc);
                transform_offset = ((mindest.*maxsrc)-(maxdest.*minsrc))./(maxsrc-minsrc);
               
                % test 
                % transform_factor.*min(data(:)) + transform_offset
                % transform_factor.*max(data(:)) + transform_offset
                
                % transform
                data_cast = cast(data.*transform_factor + transform_offset, wcdataproc_Class);
                
                % decode factor/offset
                wcdataproc_Factor = 1./transform_factor;
                wcdataproc_Offset = -(transform_offset./transform_factor);
                
                % set nan values
                data_cast(isnan(data)) = intmin(wcdataproc_Class);
                
                % store
                fData_tot{itt}.X_SBP_WaterColumnProcessed{ig}.Data.val(:,:,blockPings) = data_cast;
                
                % update memmap parameters
                p_field = strrep(newfieldname,'SBP','1');
                fData_tot{itt}.(sprintf('%s_Factor',p_field))(ig) = wcdataproc_Factor;
                fData_tot{itt}.(sprintf('%s_Offset',p_field))(ig) = wcdataproc_Offset;
                
                % disp processing progress
                if nMemMapFiles == 1
                    textprogressbar(round(iB.*100./nBlocks)-1);
                end
                
            end
            
            % disp processing progress
            if nMemMapFiles > 1
                textprogressbar(round(ig.*100./nMemMapFiles)-1);
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

