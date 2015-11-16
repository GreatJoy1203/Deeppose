function testCropper( data, cropper_handle )
%TESTCROPPER Summary of this function goes here
%   Detailed explanation goes here

    n = length( data );
    
    for i = 1:16
        i_img=randi(length(data));
        disp(['test image: ' num2str(i_img)]);
        subplot( 4, 4, i )
        tmp = data{ i_img };
        tmp.img = imread( tmp.name );
        tmp_crop = cropper_handle( tmp );
        hold off
        imshow(tmp_crop.img)
        if isfield( tmp_crop, 'pose' )
            hold on
            plot( tmp_crop.pose(:,1), tmp_crop.pose(:,2),'r.')
        end
        
        title( size( tmp_crop.img )' )
        %break;
    end

end

