seg_stats = '/Users/maryana/workspace/CellCounter/github/ucsfcellcounter/matlab/counter_segstats.mat';
test1_stats = '/Users/maryana/workspace/CellCounter/github/ucsfcellcounter/matlab/test1/stats.mat';
test2_stats = '/Users/maryana/workspace/CellCounter/github/ucsfcellcounter/matlab/test2/stats.mat';
test3_stats = '/Users/maryana/workspace/CellCounter/github/ucsfcellcounter/matlab/test3/stats.mat';
test4_stats = '/Users/maryana/workspace/CellCounter/github/ucsfcellcounter/matlab/test4/stats.mat';

toremove = [3,4,11,18,19,20,21,30,31,41,42]; %remove rows without data


stats = load(seg_stats);
stats = stats.stats;
test1 = load(test1_stats);
test1 = test1.stats;
test2 = load(test2_stats);
test2 = test2.stats;
test3 = load(test3_stats);
test3 = test3.stats;
test4 = load(test4_stats);
test4 = test4.stats;

nRows = size(stats,1);
tokeep = 1:nRows;
tokeep = setdiff(tokeep,toremove);

stats = stats(tokeep,:);
test1 = test1(tokeep,:);
test2 = test2(tokeep,:);
test3 = test3(tokeep,:);
test4 = test4(tokeep,:);

s = sum(stats);
t1 = sum(test1);
t2 = sum(test2);
t3 = sum(test3);
t4 = sum(test4);

TPs = cat(1,s(2),t1(2),t2(2),t3(2),t4(2));
FPs = cat(1,s(3),t1(3),t2(3),t3(3),t4(3));
FNs = cat(1,s(4),t1(4),t2(4),t3(4),t4(4));
gtTots = cat(1,s(1),t1(1),t2(1),t3(1),t4(1));


P = TPs./(TPs+FPs);
R = TPs./(TPs+FNs);
tp = TPs./gtTots;
fn = FNs./gtTots;
F1 = ((P.*R)/(P+R)).*2;

plot(R(1),P(1),'r.','MarkerSize',30); hold on,
plot(R(2),P(2),'b.','MarkerSize',30);
plot(R(3),P(3),'g.','MarkerSize',30);
plot(R(4),P(4),'c.','MarkerSize',30);
plot(R(5),P(5),'m.','MarkerSize',30);
xlabel('Recall') % x-axis label
ylabel('Precision') % y-axis label
leg = legend('DL','AC','CP','DU','CC');
hold off


fprintf('CellCounter: Precision=%0.2f    Recall=%0.2f    TP=%0.2f    FN=%0.2f    F1=%0.2f\n',P(1),R(1),tp(1),fn(1),F1(1));
fprintf('Test1:       Precision=%0.2f    Recall=%0.2f    TP=%0.2f    FN=%0.2f    F1=%0.2f\n',P(2),R(2),tp(2),fn(2),F1(2));
fprintf('Test2:       Precision=%0.2f    Recall=%0.2f    TP=%0.2f    FN=%0.2f    F1=%0.2f\n',P(3),R(3),tp(3),fn(3),F1(3));
fprintf('Test3:       Precision=%0.2f    Recall=%0.2f    TP=%0.2f    FN=%0.2f    F1=%0.2f\n',P(4),R(4),tp(4),fn(4),F1(4));
fprintf('Test4:       Precision=%0.2f    Recall=%0.2f    TP=%0.2f    FN=%0.2f    F1=%0.2f\n',P(5),R(5),tp(5),fn(5),F1(5));


% 
% s = t1;
% p = s(2)/(s(2)+s(3));
% r = s(2)/(s(2)+s(4));
% tp = s(2)/s(1);
% fn = s(4)/s(1);
% fprintf('P=%f    R=%f    TP=%f    FN=%f\n',p,r,tp,fn);
% 
% s=t2;
% p = s(2)/(s(2)+s(3));
% r = s(2)/(s(2)+s(4));
% tp = s(2)/s(1);
% fn = s(4)/s(1);
% fprintf('P=%f    R=%f    TP=%f    FN=%f\n',p,r,tp,fn);
% 
% s=t3;
% p = s(2)/(s(2)+s(3));
% r = s(2)/(s(2)+s(4));
% tp = s(2)/s(1);
% fn = s(4)/s(1);
% fprintf('P=%f    R=%f    TP=%f    FN=%f\n',p,r,tp,fn);
% 
% s=t4;
% p = s(2)/(s(2)+s(3));
% r = s(2)/(s(2)+s(4));
% tp = s(2)/s(1);
% fn = s(4)/s(1);
% fprintf('P=%f    R=%f    TP=%f    FN=%f\n',p,r,tp,fn);