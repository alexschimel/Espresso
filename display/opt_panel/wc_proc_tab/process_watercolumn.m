function fData_tot = process_watercolumn(fData_tot, idx_fData, procpar)
%PROCESS_WATERCOLUMN  One-line description
%
%   See also ESPRESSO.

%   Copyright 2017-2021 Alexandre Schimel, Yoann Ladroit, NIWA
%   Licensed under MIT. Details on https://github.com/alexschimel/Espresso/

% Water-column data takes A LOT of space. Because of this, the original data are
% limited in resolution so that they could be stored with less bytes, aka use
% less storage space. The issue with this is that it also limits the range
% available. For example, Kongsberg data have 0.5dB resolution in order to be
% coded directly in 1 byte (int8). The range of values stored are -63.5dB to
% 64dB.
%
% After processing, data may need increased resolution (e.g. the average of
% -30dB and -30.5dB is a value of -30.25, so if you want to use the original
% data precision, you will have to code this as either -30 or -30.5).
% Additionally, processed values may fall outside of the bounds (e.g. -80 dB),
% which will be encoded with the minimum value of the encoding (-63.5dB).
% This is a risk of saturation.
%
% So we are going to encode processed results with a different format than the
% original data. We're letting user decide the byte precision and then we will
% dynamically choose encoding parameters to obtain optimal precision given the
% processed data dynamic range, for each memmapfile. Those parameters are stored
% so data can be decoded using them.

% Specify here the number of bytes to use:
storing_precision = '1 byte'; % '1 byte' or '2 bytes'
switch storing_precision
    case '1 byte'
        % 1 byte allows storage of 255 difference values, allowing
        % for example a dynamic range of 25.5 dB at 0.1 dB resolution,
        % or 127 dB at 0.5 dB resolution.
        wcdataproc_Class = 'uint8';
    case '2 bytes'
        % 2 bytes allow storage of 65535 different values, allowing
        % for example a dynamic range of 655.35 dB at 0.01 dB
        % resolution, or 65.535 dB at 0.001 dB resolution.
        wcdataproc_Class = 'uint16';
end

% initiate comms
comms = CFF_Comms('multilines');
comms.start('Processing water-column data');
iFD = 0;
nFData = numel(idx_fData);
comms.progress(iFD,nFData);

for itt = idx_fData(:)'
    
    % processing using a try-catch so that processing left overnight can
    % continue even if one file fails.
    try
        
        % start comms for this line
        iFD = iFD+1;
        filename = CFF_file_name(fData_tot{itt}.ALLfilename{1});
        comms.step(sprintf('%i/%i: fData line %s',iFD,nFData,filename));
        
        comms.info('Initializing processed WCD');
        
        % number, dimensions, and pings of memmap files data
        datagramSource = CFF_get_datagramSource(fData_tot{itt});
        nMemMapFiles = length(fData_tot{itt}.(sprintf('%s_SBP_SampleAmplitudes',datagramSource)));
        [nSamples, nBeams, nPings] = cellfun(@(x) size(x.Data.val),fData_tot{itt}.(sprintf('%s_SBP_SampleAmplitudes',datagramSource)));
        ping_gr_start = fData_tot{itt}.(sprintf('%s_n_start',datagramSource));
        ping_gr_end   = fData_tot{itt}.(sprintf('%s_n_end',datagramSource));
        
        % create empty binary files for processed data and memory-map them
        % in fData
        wc_dir = CFF_converted_data_folder(fData_tot{itt}.ALLfilename{1});
        newfieldname = 'X_SBP_WaterColumnProcessed';
        fData_tot{itt} = CFF_init_memmapfiles(fData_tot{itt},...
            'field', newfieldname, ...
            'wc_dir', wc_dir, ...
            'Class', wcdataproc_Class, ...
            'Factor', NaN, ... % to be updated later, from data
            'Nanval', intmin(wcdataproc_Class), ... % nan value is minimum possible value
            'Offset', NaN, ... % to be updated later, from data
            'MaxSamples', nSamples, ...
            'MaxBeams', nanmax(nBeams), ...
            'ping_group_start', ping_gr_start, ...
            'ping_group_end', ping_gr_end);
        
        % apply processing per memmap file
        for ig = 1:nMemMapFiles
            
            % indices of the pings in this memmap file
            iPingsInMemMapfile = ping_gr_start(ig):ping_gr_end(ig);
            
            % block processing setup
            [blocks,info] = CFF_setup_optimized_block_processing(...
                nPings(ig),nSamples(ig)*nBeams(ig)*4,...
                'desiredMaxMemFracToUse',0.1);
            nBlocks = size(blocks,1);
            %disp(info);
            
            % initialize encoding parameters for each data block
            minsrc_block = single(nan(1,nBlocks));
            maxsrc_block = single(nan(1,nBlocks));
            encode_factor_block = nan(1,nBlocks);
            encode_offset_block = nan(1,nBlocks);
            
            % destination values after encoding are fixed and only
            % dependent on precision byte chosen
            mindest = single(intmin(wcdataproc_Class)+1); % reserve min value for NaN
            maxdest = single(intmax(wcdataproc_Class));
            
            % processing per block of pings in memmap file, in reverse
            % since the last block is the most likely to need updating
            for iB = nBlocks:-1:1
                
                % list of pings in this block
                blockPings = (blocks(iB,1):blocks(iB,2));
                
                % corresponding pings in file
                iPings = iPingsInMemMapfile(blocks(iB,1):blocks(iB,2));
                
                % grab original data in dB
                datagramSource = CFF_get_datagramSource(fData_tot{itt});
                data = CFF_get_WC_data(fData_tot{itt},sprintf('%s_SBP_SampleAmplitudes',datagramSource),'iPing',iPings,'iRange',1:nSamples(ig),'output_format','true');
                
                % PROCESSING STEP 1/3: radiometric corrections
                if procpar.radiomcorr_flag
                    comms.info(sprintf('Block %i/%i. Applying radiometric corrections...',nBlocks-iB+1,nBlocks));
                    data = CFF_WC_radiometric_corrections_CORE(data, fData_tot{itt}, iPings, procpar.radiomcorr_params);
                end
                
                % PROCESSING STEP 2/3: filtering sidelobe artefact
                if procpar.sidelobefilter_flag
                    comms.info(sprintf('Block %i/%i. Filtering sidelobe artefact...',nBlocks-iB+1,nBlocks));
                    data = CFF_filter_WC_sidelobe_artifact_CORE(data, fData_tot{itt}, iPings, procpar.sidelobefilter_params);
                end
                
                % PROCESSING STEP 3/3: masking data
                if procpar.masking_flag
                    comms.info(sprintf('Block %i/%i. Masking unwanted data...',nBlocks-iB+1,nBlocks));
                    data = CFF_mask_WC_data_CORE(data, fData_tot{itt}, iPings, procpar.masking_params);
                end
                
                % Next is data encoding for storage. For this we need to know
                % the min and max value of all blocks, not just this one. We're
                % going to operate an intermediate  encoding using best
                % available information, and perhaps later reencode.
                
                comms.info(sprintf('Block %i/%i. Encoding processed data for storage...',nBlocks-iB+1,nBlocks));
                
                % min and max values in this block
                minsrc = nanmin(data(:));
                maxsrc = nanmax(data(:));
                
                % take the min of that or any previous block
                minsrc = nanmin(nanmin(minsrc_block),minsrc);
                maxsrc = nanmax(nanmax(maxsrc_block),maxsrc);
                
                % optimal encoding parameters
                encode_factor = (maxdest-mindest)./(maxsrc-minsrc);
                encode_offset = ((mindest.*maxsrc)-(maxdest.*minsrc))./(maxsrc-minsrc);
                % dest_check_optimal = encode_factor.*[minsrc maxsrc] + encode_offset;
                
                % suboptimal encoding parameters (to minimize changes of
                % recomputation in case there are several blocks of data).
                % This is not ideal. To change eventually
                if nBlocks > 1
                    encode_factor = nanmax(floor(encode_factor),1);
                    encode_offset = ceil((mindest-encode_factor.*minsrc)./10).*10;
                    dest_check_suboptimal = encode_factor.*[minsrc maxsrc] + encode_offset;
                    if dest_check_suboptimal(1)<mindest || dest_check_suboptimal(2)>maxdest
                        comms.info('warning: encoding saturation');
                    end
                end
                
                % encode data
                data_encoded = cast(data.*encode_factor + encode_offset, wcdataproc_Class);
                
                % set nan values
                data_encoded(isnan(data)) = intmin(wcdataproc_Class);
                
                % store
                fData_tot{itt}.X_SBP_WaterColumnProcessed{ig}.Data.val(:,:,blockPings) = data_encoded;
                
                % save parameters
                minsrc_block(iB) = minsrc;
                maxsrc_block(iB) = maxsrc;
                encode_factor_block(iB) = encode_factor;
                encode_offset_block(iB) = encode_offset;
                
            end
            
            % we may have to reencode some blocks if blocks were encoded with
            % different parameters 
            
            if nBlocks == 1
                % no need here. Just save the parameters
                encode_factor_final = encode_factor;
                encode_offset_final = encode_offset;
            else
                
                % total dynamic range across all blocks
                maxsrc = nanmax(maxsrc_block);
                minsrc = nanmin(minsrc_block);
                
                % optimal final encoding parameters
                encode_factor_final = (maxdest-mindest)./(maxsrc-minsrc);
                encode_offset_final = ((mindest.*maxsrc)-(maxdest.*minsrc))./(maxsrc-minsrc);
                
                % suboptimal final encoding parameters
                encode_factor_final = nanmax(floor(encode_factor_final),1);
                encode_offset_final = ceil((mindest-encode_factor_final.*minsrc)./10).*10;
                dest_check_suboptimal = encode_factor.*[minsrc maxsrc] + encode_offset;
                if dest_check_suboptimal(1)<mindest || dest_check_suboptimal(2)>maxdest
                    comms.info('warning: encoding saturation');
                end
                
                % look for blocks that didn't use those parameters and
                % reencode them using final parameters
                for iB = 1:nBlocks
                    
                    reencode_flag = (encode_factor_final~=encode_factor_block(iB)) || (encode_offset_final~=encode_offset_block(iB));
                    if ~reencode_flag
                        continue;
                    end
                    
                    % get stored processed data
                    blockPings  = (blocks(iB,1):blocks(iB,2));
                    encoded_data = fData_tot{itt}.X_SBP_WaterColumnProcessed{ig}.Data.val(:,:,blockPings);
                    
                    % decode
                    data_decoded = (single(encoded_data) - encode_offset_block(iB))/encode_factor_block(iB);
                    
                    % re-encode data
                    data_reencoded = cast(data_decoded.*encode_factor_final + encode_offset_final, wcdataproc_Class);
                    
                    % re-set nan values
                    data_reencoded(encoded_data==intmin(wcdataproc_Class)) = intmin(wcdataproc_Class);
                    
                    % re-store
                    fData_tot{itt}.X_SBP_WaterColumnProcessed{ig}.Data.val(:,:,blockPings) = data_reencoded;
                    
                end
                
            end
            
            % reverse (decode) parameters for storage
            wcdataproc_Factor = 1./encode_factor_final;
            wcdataproc_Offset = -(encode_offset_final./encode_factor_final);
            
            % store (update) those parameters in fData
            p_field = strrep(newfieldname,'SBP','1');
            fData_tot{itt}.(sprintf('%s_Factor',p_field))(ig) = wcdataproc_Factor;
            fData_tot{itt}.(sprintf('%s_Offset',p_field))(ig) = wcdataproc_Offset;
            
        end
        
        % save the updated fData on the drive
        comms.info('Updating fData on the drive...');
        fData = fData_tot{itt};
        folder_for_converted_data = CFF_converted_data_folder(fData.ALLfilename{1});
        mat_fdata_file = fullfile(folder_for_converted_data,'fData.mat');
        save(mat_fdata_file,'-struct','fData','-v7.3');
        clear fData;
        
        % successful end of this iteration
        comms.info('Done.');
        
        % error catching
    catch err
        [~,f_temp,e_temp] = fileparts(err.stack(1).file);
        err_str = sprintf('Error in file %s, line %d',[f_temp e_temp],err.stack(1).line);
        fprintf('%s: ERROR processing file %s \n%s\n',datestr(now,'HH:MM:SS'),fData_tot{itt}.ALLfilename{1},err_str);
        fprintf('%s\n\n',err.message);
    end
    
    % communicate progress
    comms.progress(iFD,nFData);
    
end


%% end message
comms.finish('Done.');


end

