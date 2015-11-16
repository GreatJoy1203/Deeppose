clc
clear all

addpath(genpath( 'Parse' ) )
addpath(genpath( 'Eval' ) )

folder_name = './input/FLIC/';
[ data, log ] = parseAlign( folder_name );
load ./input/FLIC/examples.mat

cropper_config.mean_scale = 55;
cropper_config.yx_lambda = 1.1589;
before_size = 256;
%cropper_config.before_size = [round(before_size/1.05):round(before_size*1.05)];
cropper_config.before_size = before_size;
cropper_config.after_size = 227;
cropper_config.inverse_id = [ 4 5 6 1 2 3 7 ];
cropper_config.sample_range = 0;
cropper_config.zero_prob = .3;
%cropper = @( data )cropFLICReg( data , cropper_config );


%assigner = @(data)assignPoseFLIC( data , cropper_config.after_size);




%%


%init caffe net
caffe_toolbox_path = '/home/jiyanggao/works/caffe-master/matlab';

addpath(genpath( caffe_toolbox_path ))

caffe('reset')
prototxt_file = './model/DeepPose/deeppose_alexnet.prototxt';
caffemodel_file = './model/DeepPose/dp_alex_iter_10000.caffemodel';
caffe('set_mode_cpu');
caffe('init', prototxt_file, caffemodel_file, 'test');


%%
train_n = 3987;
pred_coords_deeppose=nan(2,7,1016);
gt_coords_deeppose=nan(2,29,1016);

for k=train_n+1:size(data,2)
    disp(['testing image ' num2str(k)]);
    data{k}.img=imread(data{k}.name);
    tmp_data=data{k};
    pose_center = mean( tmp_data.pose );
    pose_sigma = std( tmp_data.pose );
    pose_sigma = min( pose_sigma(2) / cropper_config.yx_lambda , pose_sigma(1) );
    current_scale = pose_sigma / cropper_config.mean_scale;
    source_win_size = cropper_config.before_size;
    source_win_size = source_win_size * current_scale;
    half_win_size = source_win_size / 2;
    
    crop_data = cropFLICReg( tmp_data , cropper_config);        
    [sample_image, sample_label] = assignPoseFLIC( crop_data, cropper_config.after_size );      
    
    tic
    scores = caffe('forward', { sample_image });
    toc
    scores = scores{1};
    pred_coords = reshape( scores, 7,2 );
    pred_coords = pred_coords*half_win_size+[pose_center;pose_center;pose_center;pose_center;pose_center;pose_center;pose_center];
    pred_coords_deeppose(:,:,k-train_n)= pred_coords';
    
    gt_coords_deeppose(:,:,k-train_n)=examples(k).coords;

end

%%
evalPDJ( pred_coords_modec, gt_coords_modec, pred_coords_deeppose,gt_coords_deeppose )

%%
for index=1:9
    k=randi([train_n+1, size(data,2)]);
    
    disp(['testing image ' num2str(k)]);
    data{k}.img=imread(data{k}.name);
    tmp_data=data{k};
    pose_center = mean( tmp_data.pose );
    pose_sigma = std( tmp_data.pose );
    pose_sigma = min( pose_sigma(2) / cropper_config.yx_lambda , pose_sigma(1) );
    current_scale = pose_sigma / cropper_config.mean_scale;
    source_win_size = cropper_config.before_size;
    source_win_size = source_win_size * current_scale;
    half_win_size = source_win_size / 2;
    
    crop_data = cropFLICReg( tmp_data , cropper_config);        
    [sample_image, sample_label] = assignPoseFLIC( crop_data, cropper_config.after_size );      
    
    tic
    scores = caffe('forward', { sample_image });
    toc
    scores = scores{1};
    pred_coords = reshape( scores, 7,2 );
    pred_coords = pred_coords*half_win_size+[pose_center;pose_center;pose_center;pose_center;pose_center;pose_center;pose_center];
    
    subplot(3,3,index);
    imshow(tmp_data.img);
    hold on
    plot( pred_coords(:,1), pred_coords(:,2),'r+','MarkerSize',5);
    hold on
    plot( pred_coords_modec(1,:,k-train_n), pred_coords_modec(2,:,k-train_n),'b+','MarkerSize',5);
    hold on
    plot( gt_coords_modec(1,1:8,k-train_n), gt_coords_modec(2,1:8,k-train_n),'g+','MarkerSize',5);

end
