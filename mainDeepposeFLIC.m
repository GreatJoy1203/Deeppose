%%-------------------------------
% mainDeepposeFLIC: Generate dataset from FLIC for Deeppose, and a little
% testing(see evalDeepposeMultiStages.m and evalDeepposeSingleStages.m)
% set global_config.stage1=true for Deeppose Stage 1. 
% set cropper_config.for_eval=true for testing dataset, false for training(flip or not)
% if global_config.stage1==false, then cropper_config.cropping_center tells
% which part is the current training part in Deeppose.
% global_config.save_folder should be set properly

 %1-3 left, 4-6 right, 7 head
    %key.lsho = 1;
    %key.lelb = 2;
    %key.lwri = 3;
    %key.rsho = 4;
    %key.relb = 5;
    %key.rwri = 6;
%%-------------------------------

%% 
clc
clear all

addpath(genpath( 'Parse' ) )
addpath(genpath( 'Crop' ) )
addpath(genpath( 'Assign' ) )
addpath(genpath( 'Eval' ) )

folder_name = './input/FLIC/';


 [ data, log ] = parseAlign( folder_name );


%%
global_config.stage1 = false;
cropper_config.stage1=global_config.stage1;
cropper_config.cropping_center= 4; % key for the body part
cropper_config.mean_scale = 55;
cropper_config.yx_lambda = 1.1589;
before_size = 256;
cropper_config.before_size = [round(before_size/1.05):round(before_size*1.05)];
cropper_config.after_size = 227;

if global_config.stage1==true
    cropper_config.inverse_id = [ 4 5 6 1 2 3 7 ];
else
    cropper_config.inverse_id = 1;
end

if global_config.stage1==false
    cropper_config.sample_range = round( before_size * .1 );
else
    cropper_config.sample_range = round( before_size * .4 );
end

cropper_config.zero_prob = .3;
cropper_config.for_eval=false;

cropper = @( data )cropFLICReg( data , cropper_config );

testCropper( data, cropper );

%%

%inverse_id = [ 4 5 6 1 2 3 7 ];
assigner = @(data)assignPoseFLIC( data , cropper_config.after_size);
%assigner = @(data)assignPose( data );

testAssigner( data, cropper, assigner );

%% generate training dataset


train_n = 3987;

global_config.sample_n = 20;
global_config.cropper_save_batch = 200;
global_config.hdf5_size = 5000;
if global_config.stage1==true
    global_config.save_folder = './output/FLIC_pose_train_227/';
else
    global_config.save_folder = './output/FLIC_pose_Stage2_p4_train_227/';
end
global_config.hdf5_prefix = 'FLIC_pose';
generateHDF5( data(1:train_n) , cropper, assigner, global_config);

%% generate testing dataset
global_config.sample_n = 5; 
if global_config.stage1==true
    global_config.save_folder = './output/FLIC_pose_test_227/';
else
    global_config.save_folder = './output/FLIC_pose_Stage2_p1_test_227/';
end
global_config.hdf5_prefix = 'FLIC_pose';
generateHDF5( data(1+train_n:end) , cropper, assigner, global_config);

%%


%init caffe net
caffe_toolbox_path = '/home/jiyanggao/works/caffe-master/matlab';

addpath(genpath( caffe_toolbox_path ))

caffe('reset')
prototxt_file = './model/DeepPose/deeppose_alexnet_stage2.prototxt';
caffemodel_file = './model/DeepPose/dp_alex_s2_iter_50000.caffemodel';
caffe('set_mode_cpu');
caffe('init', prototxt_file, caffemodel_file, 'test');
%%
input_data = h5read( './output/FLIC_pose_Stage2_test_227/FLIC_pose_part_1.h5','/data');
input_label = h5read( './output/FLIC_pose_Stage2_test_227/FLIC_pose_part_1.h5','/label');

%%
pred_coords_deeppose=nan(2,6,size(input_data,4));
gt_coords_deeppose=nan(2,7,size(input_data,4));
for k = 1:size(input_data,4)
    disp(['testing image ' num2str(k)]);
    input_image = input_data(:,:,:,k);
    tic
    scores = caffe('forward', { input_image });
    toc
    scores = scores{1};
   % scores = mean( scores, 1 );
   % scores = mean( scores, 2 );   
   
    pose = scores*32+32;
    pose = reshape( pose, 7,2 );
    pose = pose(1:6,:)';
    pred_coords_deeppose(:,:,k)=pose;
    
    label=input_label(:,k);
    label = label*32+32;
    label = reshape( label, 7,2 );
    label = label';
    gt_coords_deeppose(:,:,k)=label;
    %1-3 left, 4-6 right, 7 head
    %key.lsho = 1;
    %key.lelb = 2;
    %key.lwri = 3;
    %key.rsho = 4;
    %key.relb = 5;
    %key.rwri = 6;
end

%%
load MODEC_result.mat
evalPDJ(pred_coords,gt_coords,pred_coords_deeppose,gt_coords_deeppose);
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
    input_image = input_image - min( input_image(: ) );
    input_image = uint8(200 * input_image / max( input_image(: ) ));
    imshow( input_image )
   
    pose = scores*113.5+113.5;
    pose = reshape( pose, 1,2 );
    hold on
    plot( pose(:,1), pose(:,2),'r+','MarkerSize',9)
    
    %1-3 left, 4-6 right, 7 head
end

