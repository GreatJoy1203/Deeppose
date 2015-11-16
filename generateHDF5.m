function generateHDF5( data , cropper, assigner, global_config)
%GENERATEHDF5 Summary of this function goes here
%   Detailed explanation goes here

    save_log = initSaveLog( data, global_config );
    
    
    tic

    timer_start = toc;
    timer = timer_start - 10;

    for tmp_i = 1 : save_log.save_temp_batch_n                        
        % sample and croping data for each temp batch ( un-shuffle )
        
        batch_index = getTempBatchIndex( tmp_i, global_config , save_log);
        % get batch index for one temp batch
        
        batch_raw_data = data( batch_index );        
        
        [ image_data, label_data ] = generateTempBatch( ...
            batch_raw_data, cropper, assigner, global_config); 

        save_log.batch_save_name{ tmp_i } ...
            = [save_log.batch_save_folder num2str( tmp_i ) '.mat'];
        
        save( save_log.batch_save_name{ tmp_i }, ...
            'image_data', 'label_data' );
        
        save_log.batch_sample_n( tmp_i ) = size( image_data, 4 );

        %break;

        if toc - timer > 20
            timer = toc;
            rest_time = (timer - timer_start ) /tmp_i * (save_log.save_temp_batch_n - tmp_i );
            disp( [ 'rest time ' num2str( rest_time / 3600 ) ' hours ' ])
        end    
    end % end for
    
    clear image_data label_data
    
    
    commend_line = ['mkdir "' global_config.save_folder '"'];
    system( commend_line );
    
    
    
    fname_save_log = [save_log.batch_save_folder 'save_log.mat'];
    save_log.n_sample = sum( save_log.batch_sample_n );
        
    [shuffle_table, save_log ] = getShuffleTable( save_log, global_config );
    
    if ~isfield( global_config, 'hdf5_save_handle' )
        global_config.hdf5_save_handle = @writeHDF5 ;
    end
    shuffleAndSave( shuffle_table, save_log, global_config );
end
    
function shuffleAndSave( shuffle_table, save_log, global_config )
    for i = 1 : save_log.n_hdf5
        for k = 1 : save_log.save_temp_batch_n
            ref = shuffle_table{i,k}.ref;
            tgt = shuffle_table{i,k}.tgt;

            tmp_batch_data = load( save_log.batch_save_name{k} );
            if( k == 1 )
                img_data_size = size( tmp_batch_data.image_data );
                lab_data_size = size( tmp_batch_data.label_data );
                img_data_size(4) = save_log.hdf5_bag_count(i);
                lab_data_size(4) = save_log.hdf5_bag_count(i);
                image_data = zeros( img_data_size );
                label_data = zeros( lab_data_size );
            end

            image_data( :,:,:,tgt) = tmp_batch_data.image_data(:,:,:,ref);
            label_data( :,:,:,tgt) = tmp_batch_data.label_data(:,:,:,ref);            
        end
        save_name = [global_config.save_folder ...
            global_config.hdf5_prefix ...
            '_part_' num2str( i ) '.h5'];
        
        if ~isempty( dir( save_name ) )
            commend_line = ['rm "' save_name '"'];
            disp( commend_line );
            system( commend_line );
        end
                
        global_config.hdf5_save_handle( image_data, label_data, save_name );
    end
end


function [shuffle_table,save_log] = getShuffleTable( save_log, global_config )

    ref_index = [];
    for i = 1 : save_log.save_temp_batch_n
        n_sample_current_batch = save_log.batch_sample_n( i );

        current_index = [i*ones(1,n_sample_current_batch);1:n_sample_current_batch]';
        ref_index = [ref_index ; current_index];         
    end

    % shuffle now!

    ref_index = ref_index( randperm( save_log.n_sample ) , : );

    save_log.n_hdf5 = ceil( save_log.n_sample / global_config.hdf5_size );

    shuffle_table = cell( save_log.n_hdf5 , save_log.save_temp_batch_n );

    save_log.hdf5_bag_count = zeros( 1, save_log.n_hdf5 );

    for i = 1 : save_log.n_hdf5
        left = (i-1) * global_config.hdf5_size + 1;
        right = left + global_config.hdf5_size - 1;
        right = min( right , save_log.n_sample );
        left_right_index = left:right;

        save_log.hdf5_bag_count(i) = length( left_right_index );

        temp_index = ref_index( left_right_index , : );

        tgt_index =(1:length( left_right_index ))';

        for k = 1 :  save_log.save_temp_batch_n
            map_index = find( temp_index(:,1) == k );
            shuffle_table{i,k}.ref = temp_index( map_index, 2 );
            shuffle_table{i,k}.tgt = tgt_index( map_index );
        end        
    end
end

function batch_index = getTempBatchIndex( tmp_i, global_config , save_log)
    left = ( tmp_i - 1 ) * global_config.cropper_save_batch + 1;
    right = min( left + global_config.cropper_save_batch - 1, save_log.n_raw_sample );
    batch_index = left : right;
end

function [ image_data, label_data ] = generateTempBatch( ...
            batch_raw_data, cropper, assigner, global_config)
% generateTempBatch convert batch_raw_data into final image and label data 
% which cnn required
% but unshuffled

        batch_raw_n = length( batch_raw_data );
        sample_n = global_config.sample_n;    


        sample_img = cell( batch_raw_n, sample_n );
        sample_label = sample_img;

        %parfor data_i = 1:length( batch_raw_data )  
        parfor data_i = 1:length( batch_raw_data )  
            tmp_data = batch_raw_data{ data_i };

            if ~isempty( dir( tmp_data.name ) )
                try
                    tmp_data.img = imread( tmp_data.name );    
                catch
                    continue;
                end

                for sample_i = 1:sample_n
                    crop_data = cropper( tmp_data );        
                    [sample_img{data_i, sample_i}, ...
                        sample_label{data_i, sample_i}] ...
                        = assigner( crop_data );            
                end            
            end                
        end

        clear image_data
        clear label_data

        k = 0;

        batch_sample_n = batch_raw_n * sample_n;

        for data_i = 1:length( batch_raw_data )
            for sample_i = 1:sample_n

                if isempty( sample_img{data_i, sample_i} )                                
                    continue;
                end

                k = k + 1;
                if k == 1
                    size_image_quan = [size( sample_img{data_i, sample_i} ) batch_sample_n];
                    image_data = zeros( size_image_quan , 'single' );

                    size_label_quan = size( sample_label{data_i, sample_i} );
                    if length( size_label_quan ) == 1
                        size_label_quan = [ size_label_quan 1 1 batch_sample_n ];
                    elseif length( size_label_quan ) == 2
                        size_label_quan = [ size_label_quan 1 batch_sample_n ];
                    elseif length( size_label_quan ) == 3
                        size_label_quan = [ size_label_quan batch_sample_n ];                   
                    end
                    label_data = zeros( size_label_quan , 'single' );                
                end

                image_data(:,:,:,k) = single( sample_img{data_i, sample_i} );
                label_data(:,:,:,k) = sample_label{data_i, sample_i};                                    
            end        
        end
        image_data = image_data( :,:,:,1:k );
        label_data = label_data( :,:,:,1:k );
end

function save_log = initSaveLog( data, global_config )
    save_log.n_raw_sample = length( data );
    save_log.save_temp_batch_n = ceil( save_log.n_raw_sample / global_config.cropper_save_batch );   

    save_log.batch_save_folder = './output/temp/';

    save_log.batch_save_name = cell( 1, save_log.save_temp_batch_n );
    save_log.batch_sample_n = zeros( 1, save_log.save_temp_batch_n );
end

