root_dir = '/home/maryana/Projects/workspace/CellCounter/github/ucsfcellcounter/matlab/';

rt_stats = 'run_times.mat';
rt = load(rt_stats);
rt = rt.runtime;

timesDL = [rt.timeDL];
timesP = [rt.timeP];
timesDL = timesDL./60; %convert to minuts
timesP = timesP./60;
total = timesDL + timesP;

mDL = mean(timesDL);
sDL = std(timesDL);
mP = mean(timesP);
sP = std(timesP);
mT = mean(total);
sT = std(total);

fprintf('CellCounter: Mean DL time(min)=%0.2f(+-%0.2f) Mean Posproc time(min)=%0.2f(+-%0.2f) Mean total time(min)=%0.2f(+-%0.2f)\n',mDL,sDL,mP,sP,mT,sT);