function [ output_args ] = evalPDJ( pred_coords_modec, gt_coords_modec, pred_coords_deeppose,gt_coords_deeppose )
%EVALPDJ Summary of this function goes here
%   Detailed explanation goes here
%scale_by_parts = {'rsho','lhip'};
scale_by_parts = {'rsho','lhip'};
range = 1:80;

elbow_err_deeppose = score_predictions(pred_coords_deeppose , gt_coords_deeppose , {'lwri'}, scale_by_parts);
accuracyCurve(elbow_err_deeppose (:),range,'b-','linewidth',3)
 hold on
elbow_err_modec = score_predictions(pred_coords_modec , gt_coords_modec , {'lwri'}, scale_by_parts);
accuracyCurve(elbow_err_modec (:),range,'r-','linewidth',3)
hold on
axis square, grid on
axis([range([1 end]) 1 100])
legend('Deeppose Elbow','Modec Elbow')

end

