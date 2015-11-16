function [data, log] = parseAlign( folder_name )
    fname = [ folder_name 'point.txt' ];
    log = parsePointFile( fname );
    
    log.img_folder = folder_name;
    
    data = database2element( log );
    
end

function log = parsePointFile( fname )
    fin = fopen( fname , 'r' );
    
    log.name_list   = {};
    log.box_cell    = {};
    log.pose        = {};
    
    delimeter_symbol = ' ';
    
    while 1
        tline = fgetl( fin );
        
        if ~ischar(tline), break; end
        
        sep = find( tline == delimeter_symbol );
        
        log.name_list{end+1} = tline( 1:sep(1)-1 );        
        log.box_cell{end+1} = sscanf( tline( sep(1)+1:sep(5)-1 ) , '%d');
        log.pose{end+1} = sscanf( tline( sep(5)+1:end ) , '%f');                        
        log.pose{end} = reshape( log.pose{end}, 7, 2 );
    end        
    
    log.n = length( log.name_list );
    
    log.box = zeros( log.n , 4 );
    
    for i = 1 : log.n
        log.box( i , : ) = log.box_cell{ i };
    end
    
    fclose( fin );
end
