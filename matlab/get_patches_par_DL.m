function [patches,classes] = get_patches_par_DL(img,mask,ws,incBack)

%[rows cols N]  = size(img);

%avoid pixels that fall on the image edges
%mask = mask(ws:rows-ws,ws:cols-ws);

%ncores = 6;

idx_fore = find(mask == 100);

maskb = zeros(size(mask));
maskb(mask == 255) = 255;
se = strel('disk',10);
maskb = imerode(maskb,se);

idx_back1 = find(maskb == 255);
nFore = length(idx_fore);
nBack1 = length(idx_back1);

if nFore >= nBack1
   rnd_idx = randperm(nFore);
else
    rnd_idx = randperm(nBack1,nFore);
end
idx_back2 = idx_back1(rnd_idx);

R = img(:,:,1);
G = img(:,:,2);
B = img(:,:,3);

nChan = 3;
nWindow = ws*ws*nChan; 

patches_fore = zeros(nFore,nWindow);
classes_fore = zeros(nFore,1);

%parobj = parpool('local',ncores); 

parfor i=1:nFore
%for i=1:nFore
    ii = idx_fore(i);
    w1 = getwindowmod(ii,R,ws);
    w2 = getwindowmod(ii,G,ws);
    w3 = getwindowmod(ii,B,ws);

    w = [w1(:); w2(:); w3(:)]; 
    %w = [w1(:); w2(:)]; 
 
    w = w';
    patches_fore(i,:) = w(:);
    classes_fore(i) = 1;
end

if incBack == 1 %include background points
    
    patches_back = zeros(nFore,nWindow);
    classes_back = zeros(nFore,1);
    
    parfor i=1:nFore
    %for i=1:nFore
        ii = idx_back2(i);
        w1 = getwindowmod(ii,R,ws);
        w2 = getwindowmod(ii,G,ws);
        w3 = getwindowmod(ii,B,ws);
        
        w = [w1(:); w2(:); w3(:)];
        %w = [w1(:); w2(:)]; 
        
        w = w';
        patches_back(i,:) = w(:);
        classes_back(i) = 0;  
    end
end

if incBack == 1
    classes = cat(1,classes_fore,classes_back);
    clear classes_fore;
    clear classes_back;
    
    patches = cat(1,patches_fore,patches_back);
    clear patches_fore;
    clear patches_back;
else
    classes = classes_fore;
    clear classes_fore;
    clear classes_back;
    
    patches = patches_fore;
    clear patches_fore;
    clear patches_back;
end 

%delete(parobj);

end


