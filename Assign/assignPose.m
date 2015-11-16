function [ img , label ] = assignCategory( data )
    img = getZScore( data.img );
    
    label = data.pose(:)';
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


