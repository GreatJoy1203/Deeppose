
%init caffe net

input_data = h5read( './output/attribute/attribute_part_1.h5','/data');
label_data = h5read( './output/attribute/attribute_part_1.h5','/label');

addpath(genpath( '/home/jiyanggao/Downloads/caffe-master/matlab/' ) )

model_handle{1} = @()( matcaffe_init( 0 , ...
    './model/attribute_l2/attribute_l2.prototxt', ...
    './model/attribute_l2/attribute_iter_5000.caffemodel' ) );


% 
model_handle{2} = @()( matcaffe_init( 0 , ...
    './model/attribute/attribute.prototxt', ...
    './model/attribute/attribute_iter_10000.caffemodel' ) );






%%

hold off
clear th
clear tpr
clear fpr
clear res
load('data.mat')
for k = 2:length( model_handle )%:-1:1
    model_handle{k}();
    res{k} = zeros(1, size(input_data, 4));

    for index=1:size(input_data, 4)
        scores = caffe('forward', { input_data(:,:,:,index) });
        %res(index) = scores{1};
        if k == 1
            res{k}(index) = scores{1};%
        else
            res{k}(index) = exp(scores{1}(2))/(exp(scores{1}(1))+exp(scores{1}(2)));
        end
    end
    label = double(label_data);

    
    [tpr{k}, fpr{k}, th{k}] = roc( label , res{k});
    plot( fpr{k}, tpr{k}, 'color', rand( 1, 3 ) )
end


%%
hold off
for k = 1:2
    plot( fpr{k}, tpr{k}, 'color', rand( 1, 3 ) )
    hold on
end
legend( 'l2','softmax')

%%
save('data.mat', 'tpr','fpr')

%%

save('l2_result', 'tpr','fpr')

%%
hold off
plot(fpr, tpr, 'r')
l2_result = load( 'l2_result' );
hold on
plot(l2_result.fpr, l2_result.tpr,'b')
grid on