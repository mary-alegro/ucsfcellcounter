function T = thinness(A,P)

if A == 0 || P == 0
    T = 0;
    return;
end

T = 4*pi*(A/(P^2));

