function testAssigner( data, cropper_handle, assigner )
%TESTCROPPER Summary of this function goes here
%   Detailed explanation goes here

    n = length( data );
    
    for i = 1:16
        subplot( 4, 4, i )
        tmp = data{ randi(n) };
        tmp.img = imread( tmp.name );
        tmp_crop = cropper_handle( tmp );
        [img, label] = assigner( tmp_crop );
        hold off
        imshow(img)
        if isfield( tmp_crop, 'pose' )
            hold on
            plot( tmp_crop.pose(:,1), tmp_crop.pose(:,2),'r.')
        end
        
        %title( label )
    end

end

