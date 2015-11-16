function cropper_config = initPoseCropper( cropper_config )
    
    if ~isfield( cropper_config , 'padding_size' )
        cropper_config.padding_size = 20;
    end
    
%     if ~isfield( cropper_config , 'padding_size' )
%         cropper_config.resize_size = 20;
%     end
    
    mean_pose = dlmread( './input/meanpose_21crop.txt' );
    
    cropper_config.mean_pose = reshape( mean_pose, 2 , 21 )';
    cropper_config.mean_pose = cropper_config.mean_pose + cropper_config.padding_size;
    
    tmp_image_size = 39 + 2 * cropper_config.padding_size;
    
    if isfield( cropper_config, 'image_size' )
        scale = cropper_config.image_size / tmp_image_size;
        cropper_config.mean_pose = scale * cropper_config.mean_pose;
    else
        cropper_config.image_size = tmp_image_size;
    end
    
    
    
    
end