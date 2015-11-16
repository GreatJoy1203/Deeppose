clear all
clc

caffe_toolbox_path = '/home/jiyanggao/works/caffe-master/matlab';

addpath(genpath( caffe_toolbox_path ))

caffe('reset')
prototxt_file = './model/DeepPose/ms.prototxt';
caffemodel_file = './model/DeepPose/ms_iter_100000.caffemodel';
caffe('set_mode_gpu');
caffe('init', prototxt_file, caffemodel_file, 'test');
%%
%input_data = h5read( './output/FLIC_pose_test/FLIC_pose_part_1.h5','/data');
%input_data = h5read( './output/FLIC_pose_train/FLIC_pose_part_1.h5','/data');

%%
folder_name = './input/FLIC/';
[ data, log ] = parseAlign( folder_name );

%%
output_data=data;

for k = 1:size(data,2)
    disp(['Processing Image ' num2str(k) '...']);
    pose_center = mean(data{k}.pose);
    source_win_size = 256;
    half_win_size = source_win_size / 2;
    source_win = repmat( pose_center,2,1) +[-1 -1;1 1]*half_win_size;
    target_win = [1 1; 64 64];
    originImage = imread(data{k}.name);
    croppedImage = poseCrop( originImage, source_win, target_win);
    croppedImage = single(croppedImage);
    croppedImage = getZScore(croppedImage);
    tic
    scores = caffe('forward', { croppedImage });
    toc
    scores = scores{1};
    pose = reshape( scores, 7,2 );
    pose = pose*half_win_size+[pose_center;pose_center;pose_center;pose_center;pose_center;pose_center;pose_center];
    
    %imshow( originImage )
    %hold on
    %plot( pose(1:3,1), pose(1:3,2),'r+','MarkerSize',9);
   % plot( data{k}.pose(1:3,1), data{k}.pose(1:3,2),'g+','MarkerSize',9);
    leftarm = pose(1:3,:);
    output_data{k}.stage1_pose=double(leftarm);
    output_data{k}.pose = output_data{k}.pose(1:3,:);
end
save 'stage2_data.mat' output_data