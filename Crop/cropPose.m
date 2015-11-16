function output_data = cropPose( data, config )
% cropper transform image and pose

    output_data = data;
    
    if_fitgeo = exist( 'fitgeotrans', 'builtin' );
    if if_fitgeo
        t_form = fitgeotrans( data.pose, config.mean_pose, 'nonreflectivesimilarity');
        
        output_data.pose = transformPointsForward( t_form, data.pose );
        
    else
        t_form = cp2tform(data.pose, config.mean_pose, 'nonreflective similarity');
        
        output_data.pose = tformfwd( t_form, data.pose );
    end
    
    my_size = config.image_size;
    if length( config.image_size ) == 1
        my_size = my_size * [ 1 1 ];
    end
    
    if ~isfield( config, 'resize_size' )
        config.resize_size = my_size;
    end
    
    
    xWorldLimits = [1 my_size(1) ];
    yWorldLimits = [1 my_size(2) ];
    
    if size( data.img , 3 ) == 1
        data.img = repmat( data.img, [1 1 3] );
    end
        
    if if_fitgeo        

        RA = imref2d(config.resize_size, xWorldLimits, yWorldLimits);

        output_data.img = imwarp( data.img, t_form , ...,
            'OutputView', RA);
    else
        output_data.img = imtransform( data.img, t_form, ...
            'XData', xWorldLimits , ...
            'YData', yWorldLimits );
    end
        
end