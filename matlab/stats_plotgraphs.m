
%root_dir = '/Users/maryana/workspace/CellCounter/github/ucsfcellcounter/matlab/';
root_dir = '/home/maryana/Projects/workspace/CellCounter/github/ucsfcellcounter/matlab/';

seg_stats = '0_counter_segstats.mat';
test1_stats = [root_dir 'test1/stats.mat'];
test2_stats = [root_dir 'test2/stats.mat'];
test3_stats = [root_dir, 'test3/stats.mat'];
test4_stats = [root_dir 'test4/stats.mat'];

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
TNs = cat(1,s(5),t1(5),t2(5),t3(5),t4(5));
gtTots = cat(1,s(1),t1(1),t2(1),t3(1),t4(1));

%stats
P = TPs./(TPs+FPs);
R = TPs./(TPs+FNs);
FPR = (TPs./TNs).*1000;
tp = TPs./gtTots;
fn = FNs./gtTots;
F1 = ((P.*R)/(P+R)).*2;

%boxplot
TP_box = cat(2,stats(:,2),test1(:,2),test2(:,2),test3(:,2),test4(:,2));
FP_box = cat(2,stats(:,3),test1(:,3),test2(:,3),test3(:,3),test4(:,3));
FN_box = cat(2,stats(:,4),test1(:,4),test2(:,4),test3(:,4),test4(:,4));

doD = 1;
if doD == 1    
    figure,   
    boxplot(TP_box,'labels',{'DL','AC','CP','DU','CC'});
    
    figure, 
    boxplot(FP_box,'labels',{'DL','AC','CP','DU','CC'});

    figure,  
    boxplot(FN_box,'labels',{'DL','AC','CP','DU','CC'});
end
    
    
    
doG = 0;
if doG == 1
    figure, 
    plot(R(1),P(1),'r.','MarkerSize',30); hold on,
    plot(R(2),P(2),'b.','MarkerSize',30);
    plot(R(3),P(3),'g.','MarkerSize',30);
    plot(R(4),P(4),'c.','MarkerSize',30);
    plot(R(5),P(5),'m.','MarkerSize',30);
    xlabel('Recall') % x-axis label
    ylabel('Precision') % y-axis label
    leg = legend('DL','AC','CP','DU','CC');
    hold off

    figure,
    plot(FPR(1),R(1),'r.','MarkerSize',30); hold on,
    plot(FPR(2),R(2),'b.','MarkerSize',30);
    plot(FPR(3),R(3),'g.','MarkerSize',30);
    plot(FPR(4),R(4),'c.','MarkerSize',30);
    plot(FPR(5),R(5),'m.','MarkerSize',30);
    xlabel('False Positive Rate (x10^3)') % x-axis label
    ylabel('True Positive Rate (Recall)') % y-axis label
    xlim([0 0.01]);
    ylim([0 1]);
    leg = legend('DL','AC','CP','DU','CC');
    hold off
end


fprintf('CellCounter: Precision=%0.2f    Recall=%0.2f    TP=%0.2f    FN=%0.2f    F1=%0.2f    FPR(10^3)=%0.4f\n',P(1),R(1),tp(1),fn(1),F1(1),FPR(1));
fprintf('Test1:       Precision=%0.2f    Recall=%0.2f    TP=%0.2f    FN=%0.2f    F1=%0.2f    FPR(10^3)=%0.4f\n',P(2),R(2),tp(2),fn(2),F1(2),FPR(2));
fprintf('Test2:       Precision=%0.2f    Recall=%0.2f    TP=%0.2f    FN=%0.2f    F1=%0.2f    FPR(10^3)=%0.4f\n',P(3),R(3),tp(3),fn(3),F1(3),FPR(3));
fprintf('Test3:       Precision=%0.2f    Recall=%0.2f    TP=%0.2f    FN=%0.2f    F1=%0.2f    FPR(10^3)=%0.4f\n',P(4),R(4),tp(4),fn(4),F1(4),FPR(4));
fprintf('Test4:       Precision=%0.2f    Recall=%0.2f    TP=%0.2f    FN=%0.2f    F1=%0.2f    FPR(10^3)=%0.4f\n\n\n',P(5),R(5),tp(5),fn(5),F1(5),FPR(5));


fprintf('\\begin{table}[h]\n');
fprintf('\\centering\n');
fprintf('\\begin{tabular}{|c|c|c|c|c|}\n');
fprintf('\\hline\n');

fprintf('Methods     & Precision     & Recall        & FNR & F1 score      \\\\ \\hline\\hline\n');
fprintf('AC          & %0.3f         & %0.3f         & %0.3f               & %0.3f       \\\\    \\hline\n',P(2),R(2),fn(2),F1(2));
fprintf('CP          & %0.3f         & %0.3f         & %0.3f               & %0.3f          \\\\ \\hline\n',P(3),R(3),fn(3),F1(3));
fprintf('DU          & %0.3f         & %0.3f         & %0.3f               & %0.3f          \\\\ \\hline\n',P(4),R(4),fn(4),F1(4));
fprintf('CC          & %0.3f         & %0.3f         & %0.3f               & %0.3f          \\\\ \\hline\n',P(5),R(5),fn(5),F1(5));
fprintf('\\textbf{DL} & \\textbf{%0.3f} & \\textbf{%0.3f} & \\textbf{%0.3f}    & \\textbf{%0.3f} \\\\ \\hline\n',P(1),R(1),fn(1),F1(1));
fprintf('\\end{tabular}\n');
fprintf('\\caption{Precision, recall, false negative rate (FNR - the percentage of non detected cell) and F1 score for all tested methods.}\n');
fprintf('\\label{table:results}\n');
fprintf('\\end{table}\n');


