function [ data ] = transformData( dataset, len_data, start_offset )
%TRANSFORMDATA Summary of this function goes here
%   Detailed explanation goes here
data=cell(1,len_data);
for i=1+start_offset:len_data+start_offset
    data{i-start_offset}.name=[dataset.image_root dataset.name_list{i}];
    data{i-start_offset}.img=[];
    data{i-start_offset}.pose=[dataset.pose(i,1:2:41)',dataset.pose(i,2:2:42)'];
    data{i-start_offset}.box=[];
    data{i-start_offset}.category=dataset.label(i,:);

end

end
