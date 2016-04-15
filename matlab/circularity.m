function C = circularity(A,P)

if A == 0 || P == 0
    C = 0;
    return;
end

C = (P^2)/(4*pi*A);

