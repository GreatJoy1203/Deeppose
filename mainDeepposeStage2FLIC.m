clc
clear all

addpath(genpath( 'Parse' ) )
addpath(genpath( 'Crop' ) )
addpath(genpath( 'Assign' ) )

folder_name = './input/FLIC/';

load 'stage2_data.mat'
data = output_data;

%%

%data = data{1};

%%

cropper_config.mean_scale = 55;
cropper_config.yx_lambda = 1.1589;
before_size = 256;
cropper_config.before_size = [round(before_size/1.05):round(before_size*1.05)];
cropper_config.after_size = 64;

%1-3 left, 4-6 right, 7 head
cropper_config.inverse_id = [1 2 3];

cropper_config.sample_range = round( before_size * .4 );

cropper_config.zero_prob = .3;

cropper = @( data )cropFLICReg( data , cropper_config );

testCropper( data, cropper );

%%

%inverse_id = [ 4 5 6 1 2 3 7 ];
assigner = @(data)assignPoseFLIC( data , cropper_config.after_size);
%assigner = @(data)assignPose( data );

testAssigner( data, cropper, assigner );

%%


train_n = 4000;

global_config.sample_n = 20;
global_config.cropper_save_batch = 500;
global_config.hdf5_size = 15000;
global_config.save_folder = './output/FLIC_pose_Stage2_train/';
global_config.hdf5_prefix = 'FLIC_pose';
generateHDF5( data(1:train_n) , cropper, assigner, global_config);


global_config.sample_n = 2; 
global_config.save_folder = './output/FLIC_pose_Stage2_test/';
global_config.hdf5_prefix = 'FLIC_pose';
generateHDF5( data(1+train_n:end) , cropper, assigner, global_config);

%%


%init caffe net
caffe_toolbox_path = '/home/jiyanggao/works/caffe-master/matlab';

addpath(genpath( caffe_toolbox_path ))

caffe('reset')
prototxt_file = './model/DeepPose/ms.prototxt';
caffemodel_file = './model/DeepPose/ms_iter_100000.caffemodel';
caffe('set_mode_cpu');
caffe('init', prototxt_file, caffemodel_file, 'test');
%%
input_data = h5read( './output/FLIC_pose_test/FLIC_pose_part_1.h5','/data');
%input_data = h5read( './output/FLIC_pose_train/FLIC_pose_part_1.h5','/data');

%%
for k = 1:16
    subplot(4,4,k)
    input_image = input_data(:,:,:,randi(size(input_data,4)) );
    tic
    scores = caffe('forward', { input_image });
    toc
    scores = scores{1};
   % scores = mean( scores, 1 );
   % scores = mean( scores, 2 );
    %break;
    hold off
    %input_image = input_image - min( input_image(: ) );
    %input_image = uint8(200 * input_image / max( input_image(: ) ));
    imshow( input_image )
    input_image
    pose = scores*32+32;
    pose = reshape( pose, 7,2 );
    hold on
    plot( pose(7,1), pose(7,2),'r+','MarkerSize',9)
    
    %1-3 left, 4-6 right, 7 head
end

