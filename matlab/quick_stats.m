s = sum(stats);
t1 = sum(test1);
t2 = sum(test2);
t3 = sum(test3);
t4 = sum(test4);


p = s(2)/(s(2)+s(3));
r = s(2)/(s(2)+s(4));
tp = s(2)/s(1);
fn = s(4)/s(1);
fprintf('P=%f    R=%f    TP=%f    FN=%f\n',p,r,tp,fn);

s = t1;
p = s(2)/(s(2)+s(3));
r = s(2)/(s(2)+s(4));
tp = s(2)/s(1);
fn = s(4)/s(1);
fprintf('P=%f    R=%f    TP=%f    FN=%f\n',p,r,tp,fn);

s=t2;
p = s(2)/(s(2)+s(3));
r = s(2)/(s(2)+s(4));
tp = s(2)/s(1);
fn = s(4)/s(1);
fprintf('P=%f    R=%f    TP=%f    FN=%f\n',p,r,tp,fn);

s=t3;
p = s(2)/(s(2)+s(3));
r = s(2)/(s(2)+s(4));
tp = s(2)/s(1);
fn = s(4)/s(1);
fprintf('P=%f    R=%f    TP=%f    FN=%f\n',p,r,tp,fn);

s=t4;
p = s(2)/(s(2)+s(3));
r = s(2)/(s(2)+s(4));
tp = s(2)/s(1);
fn = s(4)/s(1);
fprintf('P=%f    R=%f    TP=%f    FN=%f\n',p,r,tp,fn);