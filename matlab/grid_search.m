function [bestc, bestg, bestcv] = grid_search(dir_root,kernel_type)


if dir_root(end) ~= '/'
    dir_root = [dir_root '/'];
end

mask_dir = strcat(dir_root,'masks/');

files = dir(strcat(mask_dir,'*_mask.tif'));
nFiles = length(files);

bestc = 0;
bestg = 0;
bestcv = 0;
cv = 0;
for log2c = -5:2:15,
  for log2g = 3:-2:-15,
      
      v = 1:nFiles;
      train_data = [];
      train_labels = [];
      for out=1:nFiles
          
          %
          %build traning data matrix
          %
          training = v(v ~= out);
          for t=training
              name = files(t).name;
              maskname = strcat(mask_dir,name);
              mask = imread(maskname);
              if size(mask,3) > 1
                  mask = mask(:,:,1);
              end
              
               %load image
              idx = strfind(name,'_mask.tif');
              newname = name(1:idx-1);
              imgname = strcat(dir_root,newname,'.tif');
              img = imread(imgname);

              R = img(:,:,1);
              G = img(:,:,2);
              B = img(:,:,3);

              %clean blue high values (which are holes and artifacts)
              h = imhist(B);
              P = percentile2i(h,0.98);
              Bmask = im2bw(B,P);
              mask(Bmask == 1) = 100;

              %get mask index
              idx_fore = find(mask == 255);
              idx_back1 = find(mask == 0);
              nFore = length(idx_fore);
              nBack1 = length(idx_back1);

              rnd_idx = randperm(nBack1,nFore);
              idx_back2 = idx_back1(rnd_idx);

              class_fore = ones(nFore,1);
              class_back = 0*class_fore;
              %data_fore = cat(2,R(idx_fore),G(idx_fore),B(idx_fore));
              %data_back = cat(2,R(idx_back2),G(idx_back2),B(idx_back2));

              data_fore = cat(2,R(idx_fore),G(idx_fore));
              data_back = cat(2,R(idx_back2),G(idx_back2));

              train_data = cat(1,train_data,data_fore,data_back);
              train_labels = cat(1,train_labels,class_fore,class_back);
                
              clear data_fore;
              clear data_back;
          end
          
          %
          %run SVM training
          %
          
          %radomize training matrix
          train_data = cat(2,train_labels,train_data);
          [r c N] = size(train_data);
          rnd_idx = randperm(r);
          train_data = train_data(rnd_idx,:);
          train_labels = double(train_data(:,1));
          train_data = double(train_data(:,2:end));
          
          [train_data, mins, ranges] = rescale_data(train_data);

           %train SVM
           c = 2^log2c; g = 2^log2g;
           cmd = ['-t ' num2str(kernel_type) ' -h 0 -m 200 -c ' num2str(c) '-g ' num2str(g)];
           model = svmtrain(train_labels,train_data,cmd);
          
          %
          %run SVM classification
          %
          
          %load test mask and data
           name = files(out).name;
           maskname = strcat(mask_dir,name);
           mask = imread(maskname);
           if size(mask,3) > 1
                  mask = mask(:,:,1);
           end
              
           %load image
           idx = strfind(name,'_mask.tif');
           newname = name(1:idx-1);
           imgname = strcat(dir_root,newname,'.tif');
           img = imread(imgname);

           R = img(:,:,1);
           G = img(:,:,2);
           B = img(:,:,3);

           %clean blue high values (which are holes and artifacts)
           h = imhist(B);
           P = percentile2i(h,0.98);
           Bmask = im2bw(B,P);
           mask(Bmask == 1) = 100;

           %get mask index
           idx_fore = find(mask == 255);
           idx_back1 = find(mask == 0);
           nFore = length(idx_fore);
           nBack1 = length(idx_back1);

           rnd_idx = randperm(nBack1,nFore);
           idx_back2 = idx_back1(rnd_idx);

           class_fore = ones(nFore,1);
           class_back = 0*class_fore;
           %data_fore = cat(2,R(idx_fore),G(idx_fore),B(idx_fore));
           %data_back = cat(2,R(idx_back2),G(idx_back2),B(idx_back2));

           data_fore = cat(2,R(idx_fore),G(idx_fore));
           data_back = cat(2,R(idx_back2),G(idx_back2));

           test_data = double(cat(1,data_fore,data_back));
           test_labels = double(cat(1,class_fore,class_back));
                
           clear data_fore;
           clear data_back;
           
           test_data = rescale_data(test_data,mins,ranges);
           
           %run SVM prediction
           [classes, precision, probs] = svmpredict(test_labels, test_data, model);
           cv = precision(1);
          
            if cv >= bestcv
                bestcv = cv;
                bestc = c;
                bestg = g;
            end
            
            fprintf('%g %g %g (best c=%g, g=%g, rate=%g)\n', log2c, log2g, cv, bestc, bestg, bestcv);
                  
      end
      
  end
end