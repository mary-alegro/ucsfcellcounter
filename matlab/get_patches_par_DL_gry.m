function [patches,classes] = get_patches_par_DL_gry(img,mask,ws,incBack)

%[rows cols N]  = size(img);

%avoid pixels that fall on the image edges
%mask = mask(ws:rows-ws,ws:cols-ws);

%ncores = 6;

idx_fore = find(mask == 255);
idx_back = find(mask == 0);
nFore = length(idx_fore);
nBack = length(idx_back);

if nFore >= nBack
   rnd_idx = randperm(nFore,nBack);
   idx_fore = idx_fore(rnd_idx);
else
    rnd_idx = randperm(nBack,nFore);
    idx_back = idx_back(rnd_idx);
end

nFore = length(idx_fore);
nBack = length(idx_back);

% R = img(:,:,1);
% G = img(:,:,2);
% B = img(:,:,3);

nChan = 1;
nWindow = ws*ws*nChan; 

patches_fore = zeros(nFore,nWindow);
classes_fore = zeros(nFore,1);

%parobj = parpool('local',ncores); 

parfor i=1:nFore
%for i=1:nFore
    ii = idx_fore(i);
%     w1 = getwindowmod(ii,R,ws);
%     w2 = getwindowmod(ii,G,ws);
%     w3 = getwindowmod(ii,B,ws);
% 
%     w = [w1(:); w2(:); w3(:)]; 
%     %w = [w1(:); w2(:)]; 
    w1 = getwindowmod(ii,img,ws);
    w = w1(:);
    w = w';
    patches_fore(i,:) = w(:);
    classes_fore(i) = 1;
end

if incBack == 1 %include background points
    
    patches_back = zeros(nBack,nWindow);
    classes_back = zeros(nBack,1);
    
    parfor i=1:nFore
    %for i=1:nBack
        ii = idx_back(i);
%         w1 = getwindowmod(ii,R,ws);
%         w2 = getwindowmod(ii,G,ws);
%         w3 = getwindowmod(ii,B,ws);
%         
%         w = [w1(:); w2(:); w3(:)];
%         %w = [w1(:); w2(:)]; 
        w1 = getwindowmod(ii,img,ws);
        w = w1(:);
        w = w';
        patches_back(i,:) = w(:);
        classes_back(i) = 0;  
    end
end

if incBack == 1
    classes = cat(1,classes_fore,classes_back);
    patches = cat(1,patches_fore,patches_back);
else
    classes = classes_fore;
    patches = patches_fore;
end 

clear classes_fore;
clear classes_back;
clear patches_fore;
clear patches_back;

%delete(parobj);


end


