function [data, log] = parseAttribute( folder_name )
% parser for Yang Fan's attribute dataset
% like Meitu / CHN / SJJY dataset
% parser will parse dataset info contains facelist
% pose and attribute and convert into a cell
% of data elements

    info_path = [folder_name 'AttributesInfo/' ];
    
    log.img_folder = [folder_name 'Image/'];
    
    fname_face_list = [info_path 'FaceList.txt'];    
    log.name_list = parseFaceList( fname_face_list );
    
    fname_pt_list = [info_path 'pt21List.txt'];    
    log.pose = parsePose( fname_pt_list );
    
    fname_attribute = [info_path 'Attributes.txt'];    
    log.category = parseAttributeMat( fname_attribute );        
    
    data = database2element( log );
    
    
    
end

function attribute = parseAttributeMat( fname_attribute )

    fin = fopen( fname_attribute , 'r' );
    
    n           = fscanf( fin , '%d', [ 1 1 ] );
    n_attribute = fscanf( fin , '%d', [ 1 1 ] );
    
    attribute = fscanf( fin , '%d' , [ n_attribute n ] )';
    
    fclose( fin );
end

function pose = parsePose( fname_pt_list )
    fin = fopen( fname_pt_list , 'r' );
        
    n       = fscanf( fin , '%d', [ 1 1 ] );
    n_pt    = fscanf( fin , '%d', [ 1 1 ] );
    
    pose_mat = fscanf( fin , '%f' , [ n_pt*2 n ] );
    
    pose = cell( 1, n );
    
    for i = 1:n
        pose{i} = reshape( pose_mat( : , i ), 2, n_pt )';
    end    
    
    fclose( fin );
end

function face_list = parseFaceList( fname_face_list )
    fin = fopen( fname_face_list , 'r' );
    
    line = fgetl( fin );
    n = sscanf( line , '%d', [ 1 1 ] );
    face_list = cell( 1 , n );
    
    for i = 1:n
        line = fgetl( fin );
        sep = find( line == '	' , 1 );
        face_list{ i } = line( 1 : sep-1 );
        face_list{ i }( face_list{ i } == '\' ) = '/';        
    end
    
    fclose( fin );
end