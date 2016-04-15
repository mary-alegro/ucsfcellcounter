function [patches,classes] = get_patches(img,mask,ws,incBack)

[rows cols N]  = size(img);

%avoid pixels that fall on the image edges
%mask = mask(ws:rows-ws,ws:cols-ws);



idx_fore = find(mask == 255);
idx_back1 = find(mask == 0);
nFore = length(idx_fore);
nBack1 = length(idx_back1);
    
rnd_idx = randperm(nBack1,nFore);
idx_back2 = idx_back1(rnd_idx);

patches = [];
classes = [];
R = img(:,:,1);
G = img(:,:,2);
B = img(:,:,3);



for i=idx_fore'
    w1 = getwindowmod(i,R,ws);
    w2 = getwindowmod(i,G,ws);
    w3 = getwindowmod(i,B,ws);
    %w = [w1(:); w2(:); w3(:)]; 
    w = [w1(:); w2(:)]; 
    
    %fprintf('%d\n',length(w));
    
    patches = cat(1,patches,w'); 
    classes = cat(1,classes,1);
end

if incBack == 1 %include background points
    for i=idx_back2'
        w1 = getwindowmod(i,R,ws);
        w2 = getwindowmod(i,G,ws);
        w3 = getwindowmod(i,B,ws);
        %w = [w1(:); w2(:); w3(:)];
        w = [w1(:); w2(:)]; 
        
        %fprintf('%d\n',length(w));
        
        patches = cat(1,patches,w'); 
        classes = cat(1,classes,0);
    end
end



end


