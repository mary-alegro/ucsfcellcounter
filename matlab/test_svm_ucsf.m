function test_svm_ucsf(dir_root)

if dir_root(end) ~= '/'
    dir_root = [dir_root '/'];
end

files = dir(strcat(dir_root,'*_mask.tif'));
nFiles = length(files);

cases = 1:nFiles;
for test_case=1:nFiles
    train_cases = cases(cases ~= test_case);
    
    % build train data matrix
    train_data = [];
    train_labels = [];
    fprintf('Building training data matrix.\n');
    for v=train_cases
        fname = files(v).name;
        mask_name = strcat(dir_root,fname);
        tmp = strfind(fname,'_mask.tif');
        img_name = fname(1:tmp-1);
        img_name = strcat(dir_root,img_name,'.tif');
        
        mask = imread(mask_name);
        [rm cm Nm] = size(mask);
        if Nm > 1
            mask = mask(:,:,1);
        end
        
        img = imread(img_name);
        R = img(:,:,1);
        G = img(:,:,2);
        B = img(:,:,3);
        
        idx_fore = find(mask == 255);
        idx_back_tmp = find(mask == 0);
        
        nFore = length(idx_fore);
        nBack = length(idx_back_tmp);
        rnd_idx = randperm(nBack,nFore);
        idx_back = idx_back_tmp(rnd_idx);
        
        class_fore = ones(nFore,1);
        class_back = 0*class_fore;
        data_fore = cat(2,R(idx_fore),G(idx_fore),B(idx_fore));
        data_back = cat(2,R(idx_back),G(idx_back),B(idx_back));
        
        train_data = cat(1,train_data,data_fore,data_back);
        train_labels = cat(1,train_labels,class_fore,class_back);
    end
    
    %train SVM
    bestc = 1; bestg = 2;
    
    train_labels = double(train_labels);
    train_data = rescale2(double(train_data));
    
    fprintf('Training SVM.\n');
    model = svmtrain(train_labels,train_data,['-t 2 -h 0 -m 200 -c' num2str(bestc) '-g ' num2str(bestg)]);
    
    %build test data matrix
    fprintf('Building test data matrix.\n');
    
    fname = files(test_case).name;
    tmp = strfind(fname,'_mask.tif');
    img_name = fname(1:tmp-1);
    img_name = strcat(dir_root,img_name,'.tif');
    img = imread(img_name);
    
    img = imresize(img,0.25);
    
    R = img(:,:,1);
    G = img(:,:,2);
    B = img(:,:,3);
    [rT cT NT] = size(R);
    
    test_data = cat(2,R(:),G(:),B(:));
    test_data = rescale2(double(test_data));
    
    labels = double(zeros(rT*cT,1));
    
    fprintf('Running classification.\n');
    [classes, precision, probs] = svmpredict(labels, test_data, model);
    
     %test SVM
    segment = zeros(rT,cT);
    segment(classes == 0) = 255;
    figure, imshow(segment);
   
end
