function  train_cell_class(GT_train)

%
% Trains the cell classification (in RED, GREEN and YELLOW) step. Used in
% leave-v-out validation.
% Grab pixel samples from the fluorescence images using GT coordinates as a
% guide. Converts then to LAB. 
%
%

samples = train_classify(GT_train);
GT_name = strcat('cell_samples.mat');
save(GT_name,'samples'); 

end

