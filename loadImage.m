function data = loadImage( data )
% loading all image will occupied too much space
% quan ni bie yong
    return;
    n = length( data );
    
    tic
    timer_start = toc;
    
    timer = timer_start - 15;
    
    sz = 0;
    
    for i = 1:n
        try
            data{i}.img = imread( data{i}.name );
        catch
            continue;
        end
        
        sz = sz + size( data{i}.img , 1 ) * size( data{i}.img , 2 );
        
        if toc - timer > 20            
            timer = toc;
            rest_time = ( timer - timer_start ) / i * (n - i );
            disp( ['rest time ' num2str( timer / 3600 ) ' hours '] );            
            avg_size = sz / i * n * 3 / (1024^3);
            disp( ['space ' num2str( avg_size ) ' GB required'] );
            
        end
    end
end