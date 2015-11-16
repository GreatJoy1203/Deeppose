function output_data = poseCrop( data, src_box, tgt_box )

    xWorldLimits = [1 tgt_box(2,1) ];
    yWorldLimits = [1 tgt_box(2,2) ];
     
    t_form = cp2tform( src_box, tgt_box , 'nonreflective similarity');


    output_data = imtransform( data, t_form, ...
        'XData', xWorldLimits , ...
        'YData', yWorldLimits );
   
end