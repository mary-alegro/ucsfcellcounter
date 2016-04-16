function print_points_csv(img,csv)






idx = find(csv(:,1) == 0);
pts_b = csv(idx,:);
idx = find(csv(:,1) == 1);
pts_r = csv(idx,:);
idx = find(csv(:,1) == 2);
pts_g = csv(idx,:);
idx = find(csv(:,1) == 3);
pts_y = csv(idx,:);

imshow(img); hold on,
[r c N] = size(pts_b);
for f=1:r
    x = csv(f,2);
    y = csv(f,3);
    plot(x,y,'b*');
end

figure, imshow(img); hold on,
[r c N] = size(pts_r);
for f=1:r
    x = csv(f,2);
    y = csv(f,3);
    plot(x,y,'r*');
end

figure, imshow(img); hold on,
[r c N] = size(pts_g);
for f=1:r
    x = csv(f,2);
    y = csv(f,3);
    plot(x,y,'g*');
end

figure, imshow(img); hold on,
[r c N] = size(pts_y);
for f=1:r
    x = csv(f,2);
    y = csv(f,3);
    plot(x,y,'y*');
end