function [ img , label, mask,pose ] = assignHeatMap( data , assinger_config )
    img = getZScore( data.img );
    
%     assinger_config.off_set = 2.5;
%     assinger_config.down_sample_rate = 2;
%     assinger_config.final_size = [ 14 14 ];

    [label,mask, pose] = getHeatMap( data.pose, assinger_config , size(img ) );
end

function [label,mask, pose_new] = getHeatMap( pose, assinger_config , img_size )
    n_pt = size( pose , 1 );
    pose_new=zeros(size(pose));
    label = zeros( [ assinger_config.final_size n_pt ] );
    mask = zeros( [ assinger_config.final_size n_pt ] );
    
    width = img_size( 2 );
    height = img_size( 1 );
    
    my_fun = @(x, bound)( min( max( 1, round(x) ), bound ) );
    
    src_box = [ assinger_config.off_set , assinger_config.off_set ;
                width-assinger_config.off_set, height - assinger_config.off_set ];
    tgt_box = [ 1 1 ; assinger_config.final_size ];
    
    xWorldLimits = [1 tgt_box(2,1) ];
    yWorldLimits = [1 tgt_box(2,2) ];    
    
    t_form = cp2tform( src_box, tgt_box , 'nonreflective similarity');
    
    pattern = fspecial( 'gaussian',assinger_config.filter_size, assinger_config.sigma );
    
    for i = 1:n_pt
        x = my_fun( pose(i,1), width );
        y = my_fun( pose(i,2), height );
        pose_new(i,1)=x;
        pose_new(i,2)=y;
        tmp_map = zeros( height, width );
        tmp_map( y, x ) = 1;
        tmp_map = imfilter( tmp_map , pattern );
        label(:,:,i) = imtransform(    tmp_map, t_form , ...
                        'XData', xWorldLimits , ...
                        'YData', yWorldLimits );
        label(:,:,i) = label(:,:,i)./max(max(label(:,:,i)));
        
        % generate mask
        for m=1:size(label(:,:,i),1)
            for n=1:size(label(:,:,i),2)
                if label(m,n,i)~=0
                    mask(m,n,i)=1;
                end
            end
        end
        
    end
end

function img = getZScore( img )
    img = single( img );
    
    for i = 1:size( img , 3 )
        tmp = img(:,:,i);
        mu = mean( tmp(:) );
        sigma = std( tmp(:) ) + 1e-3;
        img(:,:,i) = ( tmp - mu ) / sigma;
    end
end


