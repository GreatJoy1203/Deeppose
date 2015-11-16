%%
%init caffe net
caffe_toolbox_path = '/home/jiyanggao/Downloads/caffe-master/matlab';

addpath(genpath( caffe_toolbox_path ))

%matcaffe_init( 0 , ...
%    './model/heat_map/simple_heat_map.prototxt', ...
%    './model/heat_map/heat_map_iter_1000.caffemodel' )

prototxt_file = './model/heat_map/simple_heat_map.prototxt';
caffemodel_file = './model/heat_map/heat_map_iter_20000.caffemodel';
caffe('set_mode_cpu');
caffe('init', prototxt_file, caffemodel_file, 'test');

layers = caffe('get_weights');
disp({layers.layer_names});
%%

image_data = h5read( './output/heatMap/32_32_pose/heatMap_part_2.h5','/data');
label_data = h5read( './output/heatMap/32_32_pose/heatMap_part_2.h5','/label');

%%


subplot( 1 ,3 , 1 )
input_index = randi( size( image_data, 4 ) );

imshow( image_data(:,:,:, input_index ) )



tic
heat_map = caffe('forward', { image_data(:,:,:, input_index ) });
toc

heat_map = heat_map{1};
current_label_map = label_data(:,:,:,input_index );
% for j = 1:size( heat_map, 3 )
%     subplot(3,3,j + 1)
%     imagesc( labe_map(:,:,j ) )

% end
hold on
subplot(1,3,2)
imagesc(sum(current_label_map, 3));
hold on
subplot(1,3,3)
imagesc(sum(heat_map(:,:,:),3));

figure;
for i=1:7
    hold on
    subplot(3,3,i)
    imagesc(heat_map(:,:,i));
end
