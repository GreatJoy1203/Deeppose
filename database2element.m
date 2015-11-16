function data = database2element( database )
% database2element convert a database into a cell of data element
% database should have the field of name_list
% optional field: box, pose, category, n
%
%
    if ~isfield( database, 'n' )
        database.n = length( database.name_list );
    end
    
    data = cell( 1, database.n );
    
    for i = 1:length( data )
        data{i} = initDataElement();
    end
    
    prefix = [];
    
    if isfield( database, 'img_folder' )
        prefix = database.img_folder;
    end
    
        
    if isfield( database, 'name_list' )
        for i = 1:length( data )
            data{i}.name = [prefix database.name_list{i}];
        end
    else
        disp('warning! failed to figure out name_list' );
    end
    
    if isfield( database, 'pose' )
        for i = 1:length( data )
            data{i}.pose = database.pose{i};
        end
    end
    
    if isfield( database, 'box' )
        for i = 1:length( data )
            data{i}.box = database.box( i , : );
        end
    end
    
    if isfield( database, 'category' )
        for i = 1:length( data )
            data{i}.category = database.category( i , : );
        end
    end
end