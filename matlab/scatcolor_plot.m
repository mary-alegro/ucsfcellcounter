

samples=load('cell_samples.mat');
samples = samples.samples;
[red green yellow] = pack_samples(samples);
plot3(red(:,1),red(:,2),red(:,3),'r.','MarkerSize',20); hold on,
plot3(green(:,1),green(:,2),green(:,3),'g.','MarkerSize',20); 
plot3(yellow(:,1),yellow(:,2),yellow(:,3),'y.','MarkerSize',20);
xlabel('L');
ylabel('A');
zlabel('B');
legend('red cells','green cell','yellow cells','Location','best')