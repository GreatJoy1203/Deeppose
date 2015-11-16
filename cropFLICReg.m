function output_data = cropFLICReg( data, cropper_config )    

    if cropper_config.stage1==true
        pose_center = mean( data.pose );
    else
        k=cropper_config.cropping_center;
        pose_center = data.pose(k,:);
    end
    pose_sigma = std( data.pose );

    pose_sigma = min( pose_sigma(2) / cropper_config.yx_lambda , pose_sigma(1) );
    current_scale = pose_sigma / cropper_config.mean_scale;

    %current_scale=0.8;
    if cropper_config.sample_range==0
        offset_range=0;
    else
        offset_range = randi( cropper_config.sample_range ) * current_scale;
    end
    theta = rand()* 2*pi;
    offset = offset_range * [sin(theta) cos(theta)];
    pose_center = pose_center + offset;
    
    source_win_size = cropper_config.before_size( randi(length(cropper_config.before_size)) );
    
    if cropper_config.stage1==true
        source_win_size = source_win_size * current_scale;
    else
        source_win_size = source_win_size * current_scale*0.5;% for stage 2
    end
    half_win_size = source_win_size / 2;

    source_win = repmat( pose_center,2,1) +[-1 -1;1 1]*half_win_size;
    target_win = [1 1; cropper_config.after_size cropper_config.after_size];
    
    output_data = poseCrop( data, source_win, target_win);
    if cropper_config.stage1==false
        k=cropper_config.cropping_center;
        output_data.pose=output_data.pose(k,:);% for stage 2,3
    end
    
    if cropper_config.for_eval==false
        if randn() < 0     % flip the image
            width = size( output_data.img , 2 );

            pose = output_data.pose( cropper_config.inverse_id , : );        

            pose(:,1) = width + 1 - pose(:,1);        

            output_data.pose = pose;        
            %flip
            output_data.img = output_data.img( :, end:-1:1, : );
        end
    end
end

function output_data = poseCrop( data, src_box, tgt_box )

    xWorldLimits = [1 tgt_box(2,1) ];
    yWorldLimits = [1 tgt_box(2,2) ];
    
    output_data = data;
    
    if_fitgeo = exist( 'fitgeotrans' ) == 2;
    
    if 0%if_fitgeo
        t_form = fitgeotrans( src_box, tgt_box, 'nonreflectivesimilarity');
        %t_form = cp2tform( src_box, tgt_box , 'nonreflective similarity');
        
        if isfield( data, 'pose' )
            output_data.pose = transformPointsForward( t_form, data.pose );
        end
        
        RA = imref2d(tgt_box(2,:), xWorldLimits, yWorldLimits);

        output_data.img = imwarp( data.img, t_form , ...,
            'OutputView', RA);
    else
       
        t_form = cp2tform( src_box, tgt_box , 'nonreflective similarity');
        
        if isfield( data, 'pose' )
            output_data.pose = tformfwd( t_form, data.pose );
        end
        
        output_data.img = imtransform( data.img, t_form, ...
            'XData', xWorldLimits , ...
            'YData', yWorldLimits );
    end
end