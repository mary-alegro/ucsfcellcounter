function [pts_b, pts_r, pts_g, pts_y] = print_points_csv(img,csv)


idx = find(csv(:,1) == 0);
pts_b = csv(idx,2:3);
idx = find(csv(:,1) == 1);
pts_r = csv(idx,2:3);
idx = find(csv(:,1) == 2);
pts_g = csv(idx,2:3);
idx = find(csv(:,1) == 3);
pts_y = csv(idx,2:3);

imshow(img); 
hold on
%plot(pts_b(:,1),pts_b(:,2),'w*','MarkerSize', 10);
plot(pts_r(:,1),pts_r(:,2),'r*','MarkerSize', 10);
plot(pts_g(:,1),pts_g(:,2),'g*','MarkerSize', 10);
plot(pts_y(:,1),pts_y(:,2),'y*','MarkerSize', 10);

