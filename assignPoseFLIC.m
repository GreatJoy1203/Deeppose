function [ img , label ] = assignPoseFLIC( data, win_size )
    img = getZScore( data.img );
    
    label = data.pose(:)';
    label = (label - win_size /2 )/ ( win_size / 2 );
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
