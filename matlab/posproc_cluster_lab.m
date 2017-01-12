function mask_class = posproc_cluster_lab(img,mask)


[labels nL] = bwlabel(mask);
[r g b] = chromacity(img);

% cform = makecform('srgb2lab');
% lab = applycform(img, cform);
% 
% r = lab(:,:,1);
% g = lab(:,:,2);
% b = lab(:,:,3);

chromaR = zeros(nL,1);
chromaG = zeros(nL,1);
chromaB = zeros(nL,1);

for l=1:nL
    
    idx = find(labels == l);
    rr = r(idx);
    gg = g(idx);
    bb = b(idx);
    
    mr = mean(rr);
    mg = mean(gg);
    mb = mean(bb);
    
    chromaR(l) = mr;
    chromaG(l) = mg;
    chromaB(l) = mb;
end

%plot3(chromaR,chromaG,chromaB,'.');
%plot(chromaR,chromaG,'*');

features = cat(2,  chromaR, chromaG, chromaB);
%features = cat(2, chromaR, chromaG);

obj = clusterdata(features,'linkage','ward','savememory','on','maxclust',4);

%options = statset('Display','final');
%obj = gmdistribution.fit(features,2,'Replicates',3,'CovType','diagonal','Options',options);
%classes = cluster(obj,features);
classes = obj;

idx1 = find(classes == 1);
idx2 = find(classes == 2);
idx3 = find(classes == 3);
idx4 = find(classes == 4);

c_str(1).idx = idx1;
c_str(2).idx = idx2;
c_str(3).idx = idx3;
c_str(4).idx = idx4;

%scatter3(features(:,1),features(:,2),features(:,3),10,obj); figure,

% c1R = chromaR(idx1);
% c1G = chromaG(idx1);
% c1B = chromaB(idx1);
% c2R = chromaR(idx2);
% c2G = chromaG(idx2);
% c2B = chromaB(idx2);

mc(1,1) = mean(chromaR(idx1)); mc(1,2) = mean(chromaG(idx1)); 
mc(2,1) = mean(chromaR(idx2)); mc(2,2) = mean(chromaG(idx2)); 
mc(3,1) = mean(chromaR(idx3)); mc(3,2) = mean(chromaG(idx3)); 
mc(4,1) = mean(chromaR(idx4)); mc(4,2) = mean(chromaG(idx4)); 

ctmp = [1 2 3 4];

m = max(mc(:,1));
classR = find(mc(:,1) == m);
m = max(mc(:,2));
classG = find(mc(:,2) == m);
classY = ctmp(ctmp ~= classR & ctmp ~= classG);

 %plot(c1R,c1G, 'r.'); hold on,
 %plot(c2R,c2G, 'g.'); figure,
 %plot(c1B,c2B, 'b.'); figure,
 
mask_class = labels;
mc1 = zeros(size(labels));
mc2 = zeros(size(labels));
mc3 = zeros(size(labels)); 
mc4 = zeros(size(labels)); 
 
 for l=c_str(classR).idx';
    mask_class(labels == l) = 60;
    mc1(labels == l) = 255;
end

for l=c_str(classG).idx';
    mask_class(labels == l) = 120;
    mc2(labels == l) = 255;
end

for l=c_str(classY(1)).idx';
    mask_class(labels == l) = 250;
    mc3(labels == l) = 255;
end

for l=c_str(classY(2)).idx';
    mask_class(labels == l) = 250;
    mc4(labels == l) = 255;
end

mask_class = uint8(mask_class);

masks = cat(3,bwperim(mc1),bwperim(mc2),bwperim(mc3),bwperim(mc4));
colors = cat(1,[1 0 0],[0 1 0],[1 1 1],[1 1 1]);
overlay = imoverlaymult(img, masks, colors); imshow(overlay); 

