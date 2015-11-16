 %1-3 left, 4-6 right, 7 head
    %key.lsho = 1;
    %key.lelb = 2;
    %key.lwri = 3;
    %key.rsho = 4;
    %key.relb = 5;
    %key.rwri = 6;

clc
clear all

addpath(genpath( 'Parse' ) )
addpath(genpath( 'Eval' ) )

folder_name = './input/FLIC/';
[ data, log ] = parseAlign( folder_name );

load ./input/FLIC/examples.mat
%training set goes first and testing set goes second
testex = examples([examples.istest]);
trainex = examples([examples.istrain]);
examples=[trainex testex]; 

cropper_config.mean_scale = 55;
cropper_config.yx_lambda = 1.1589;
before_size = 256;
cropper_config.before_size = before_size; % in test phase, the size of source window is fixed
cropper_config.after_size = 227;
cropper_config.sample_range = 0; % in test phase, no offset for center point
cropper_config.zero_prob = .3;
cropper_config.for_eval=true;


%%
caffe_toolbox_path = '/home/jiyanggao/works/caffe-matcaffe3/matlab';
addpath(genpath( caffe_toolbox_path ))

caffe.set_mode_gpu();

model_stage1 = './model/DeepPose/deeppose_alexnet.prototxt';
weights_stage1 = './model/DeepPose/dp_alex_iter_50000.caffemodel';

model_stage2 = './model/DeepPose/deeppose_alexnet_stage2.prototxt';
weights_stage2=cell(6);
weights_stage2{1} = './model/DeepPose/dp_alex_s2_p1_iter_50000.caffemodel';
weights_stage2{2} = './model/DeepPose/dp_alex_s2_p2_iter_50000.caffemodel';
weights_stage2{3} = './model/DeepPose/dp_alex_s2_p3_iter_50000.caffemodel';
weights_stage2{4} = './model/DeepPose/dp_alex_s2_p4_iter_50000.caffemodel';
weights_stage2{5} = './model/DeepPose/dp_alex_s2_p5_iter_50000.caffemodel';
weights_stage2{6} = './model/DeepPose/dp_alex_s2_p6_iter_50000.caffemodel';

dp_stage1= caffe.Net(model_stage1, weights_stage1, 'test'); % create net and load weights
dp_stage2=cell(6);
for wk=1:6
    dp_stage2{wk}= caffe.Net(model_stage2, weights_stage2{wk}, 'test'); % create net and load weights
end


%% Testing & Comparision
train_n = 3987;

for index=1:4
    k=randi([train_n+1, size(data,2)]);
    
    disp(['testing image ' num2str(k)]);
    data{k}.img=imread(data{k}.name);
    tmp_data=data{k};
    %stage 1
    cropper_config.stage1=true;
    cropper_config.inverse_id = [ 4 5 6 1 2 3 7 ];
    % cropping info
    pose_center_stage1 = mean( tmp_data.pose );
    pose_sigma_stage1 = std( tmp_data.pose );
    pose_sigma_stage1 = min( pose_sigma_stage1(2) / cropper_config.yx_lambda , pose_sigma_stage1(1) );
    current_scale_stage1 = pose_sigma_stage1 / cropper_config.mean_scale;
    source_win_size_stage1 = cropper_config.before_size;
    source_win_size_stage1 = source_win_size_stage1 * current_scale_stage1;
    half_win_size_stage1 = source_win_size_stage1 / 2;
    %cropping
    crop_data = cropFLICReg( tmp_data , cropper_config);        
    [sample_image, sample_label] = assignPoseFLIC( crop_data, cropper_config.after_size );      
    % predict
    tic
    scores = dp_stage1.forward({sample_image });
    toc   
    %recover coords
    scores = scores{1};
    pred_coords_stage1 = reshape( scores, 7,2 );
    pred_coords_stage1 = pred_coords_stage1*half_win_size_stage1+[pose_center_stage1;pose_center_stage1;pose_center_stage1;pose_center_stage1;pose_center_stage1;pose_center_stage1;pose_center_stage1];
    
    %stage 2
    pred_coords_stage2=zeros(7,2);
    cropper_config.stage1=false;
    for pk=1:6
       cropper_config.cropping_center= pk; % key for the body part
        % cropping info
        half_win_size_stage2 = half_win_size_stage1*0.5;% for stage 2
        tmp_data.pose=double(pred_coords_stage1);
        %tmp_data.pose
        pose_center_stage2 = tmp_data.pose(cropper_config.cropping_center,:);
        %cropping
        crop_data = cropFLICReg( tmp_data , cropper_config);        
        [sample_image, sample_label] = assignPoseFLIC( crop_data, cropper_config.after_size ); 
        % predict
        tic
        scores = dp_stage2{pk}.forward({sample_image });
        toc
        %recover coords
        scores = scores{1};
        pred_coords_stage2_p = reshape( scores, 1,2 );
        pred_coords_stage2_p = pred_coords_stage2_p*half_win_size_stage2+pose_center_stage2;
        pred_coords_stage2(pk,:)=pred_coords_stage2_p;
    end
    
    subplot(2,2,index);
    imshow(tmp_data.img);
    hold on
    plot( pred_coords_stage1(:,1), pred_coords_stage1(:,2),'r+','MarkerSize',5);
    hold on
    plot( pred_coords_stage2(:,1), pred_coords_stage2(:,2),'b+','MarkerSize',5);
%     hold on
%     plot( tmp_data.pose(:,1),  tmp_data.pose(:,2),'g+','MarkerSize',5);
    hold on
    plot( examples(k).coords(1,1:6),  examples(k).coords(2,1:6),'g.','MarkerSize',5);


end

%% Evaluate PDJ
train_n = 3987;
pred_coords_stage1_deeppose=nan(2,7,1016);
pred_coords_stage2_deeppose=nan(2,7,1016);
gt_coords_deeppose=nan(2,29,1016);

for k=train_n+1:size(data,2)
    
    disp(['testing image ' num2str(k)]); 
    data{k}.img=imread(data{k}.name);
    tmp_data=data{k};
    %stage 1
    cropper_config.stage1=true;
    cropper_config.inverse_id = [ 4 5 6 1 2 3 7 ];
    % cropping info
    pose_center_stage1 = mean( tmp_data.pose );
    pose_sigma_stage1 = std( tmp_data.pose );
    pose_sigma_stage1 = min( pose_sigma_stage1(2) / cropper_config.yx_lambda , pose_sigma_stage1(1) );
    current_scale_stage1 = pose_sigma_stage1 / cropper_config.mean_scale;
    source_win_size_stage1 = cropper_config.before_size;
    source_win_size_stage1 = source_win_size_stage1 * current_scale_stage1;
    half_win_size_stage1 = source_win_size_stage1 / 2;
    %cropping
    crop_data = cropFLICReg( tmp_data , cropper_config);        
    [sample_image, sample_label] = assignPoseFLIC( crop_data, cropper_config.after_size );      
    % predict
    tic
    scores = dp_stage1.forward({sample_image });
    toc   
    %recover coords
    scores = scores{1};
    pred_coords_stage1 = reshape( scores, 7,2 );
    pred_coords_stage1 = pred_coords_stage1*half_win_size_stage1+[pose_center_stage1;pose_center_stage1;pose_center_stage1;pose_center_stage1;pose_center_stage1;pose_center_stage1;pose_center_stage1];
    
    %stage 2
    pred_coords_stage2=zeros(7,2);
    cropper_config.stage1=false;
    for pk=1:6
       cropper_config.cropping_center= pk; % key for the body part
        % cropping info
        half_win_size_stage2 = half_win_size_stage1*0.5;% for stage 2
        tmp_data.pose=double(pred_coords_stage1);
        %tmp_data.pose
        pose_center_stage2 = tmp_data.pose(cropper_config.cropping_center,:);
        %cropping
        crop_data = cropFLICReg( tmp_data , cropper_config);        
        [sample_image, sample_label] = assignPoseFLIC( crop_data, cropper_config.after_size ); 
        % predict
        tic
        scores = dp_stage2{pk}.forward({sample_image });
        toc
        %recover coords
        scores = scores{1};
        pred_coords_stage2_p = reshape( scores, 1,2 );
        pred_coords_stage2_p = pred_coords_stage2_p*half_win_size_stage2+pose_center_stage2;
        pred_coords_stage2(pk,:)=pred_coords_stage2_p;
    end
    
    
    %store
    gt_coords_deeppose(:,:,k-train_n)=examples(k).coords;
    pred_coords_stage1_deeppose(:,:,k-train_n)= pred_coords_stage1';
    pred_coords_stage2_deeppose(:,:,k-train_n)= pred_coords_stage2';

end
%% Figure
figure 

scale_by_parts = {'rsho','lhip'};
range = 1:40;

% stage2
elbow_err_deeppose = score_predictions(pred_coords_stage2_deeppose , gt_coords_deeppose , {'rsho','lsho'}, scale_by_parts);
accuracyCurve(elbow_err_deeppose (:),range,'b-','linewidth',3)
 hold on
 %stage1
 elbow_err_deeppose = score_predictions(pred_coords_stage1_deeppose , gt_coords_deeppose , {'rsho','lsho'}, scale_by_parts);
accuracyCurve(elbow_err_deeppose (:),range,'r-','linewidth',3)
 hold on
 % modec
 load MODEC_result.mat
elbow_err_modec = score_predictions(pred_coords_modec , gt_coords_modec , {'rsho','lsho'}, scale_by_parts);
accuracyCurve(elbow_err_modec (:),range,'g-','linewidth',3)

hold on
axis square, grid on
axis([range([1 end]) 1 100])
legend('Deeppose Stage2','Deeppose Stage1','Modec')
title('Shoulder-Iter 50000')