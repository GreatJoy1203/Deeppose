function [ img , label ] = assignCategory( data, sel_id )
    img = getZScore( data.img );
    
    if nargin > 1
        label = data.category( sel_id );
    else
        label = data.category;
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


