function output_data = cropBox( data, cropper_config )    
    
    b = data.box;
    
    x_cen = mean( b(2:3) );
    y_cen = mean( b([1 4]) );
    
    half_win = b(4) - y_cen;
    
    tgt_box = [1 1; cropper_config.after_pad_size cropper_config.after_pad_size ];
    src_box = getSourceBox( cropper_config, x_cen, y_cen, half_win );
    
    if size( data.img , 3 ) == 1
        data.img = repmat( data.img, [1 1 3] );
    end
    
    output_data = poseCrop( data, src_box, tgt_box );
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

function src_box = getSourceBox( cropper_config, x_cen, y_cen, half_win )
    % pading
    half_win = half_win ...
        / cropper_config.box_resize ...
        * cropper_config.after_pad_size;
    
    x_offset    = randn() * cropper_config.sigma_x;
    y_offset    = randn() * cropper_config.sigma_x;
    theta       = randn() * cropper_config.sigma_theta;
    cs = cos( theta );
    ss = sin( theta );
    
    x_cen = x_cen + x_offset;
    y_cen = y_cen + y_offset;
    
    x_l = x_cen - half_win * cs + half_win * ss;
    x_r = x_cen + half_win * cs - half_win * ss;
    y_t = y_cen - half_win * cs - half_win * ss;
    y_b = y_cen + half_win * cs + half_win * ss;
    
    src_box = [ x_l y_t; x_r y_b ];
end