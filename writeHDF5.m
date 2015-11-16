function writeHDF5( data, labelh5 , h5file)
%WRITEHDF5 Summary of this function goes here
%   Detailed explanation goes here

% datah5 = zeros(pw, ph, channels, item_num);
% labelh5 = zeros(1, item_num);

size_label_data = size( labelh5 );

if( length( size_label_data ) > 2 )
    size_head = prod( size_label_data( 1 : end-1 ) );
    labelh5 = reshape(labelh5, size_head , size_label_data( end ) );
end

h5create(h5file, '/data', (size(data)), 'Datatype','single');
h5create(h5file, '/label', (size(labelh5)), 'Datatype','single');
h5write(h5file, '/data', data);
h5write(h5file, '/label', labelh5);
end

