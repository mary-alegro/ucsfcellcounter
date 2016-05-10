function R = costDL(D,U,X,alpha,param)

    alpha2 = alpha;
    alpha2(U) = 0;
    R = mean(0.5*sum((X-D*alpha).^2)+param.lambda*sum(abs(alpha)));
    %R = mean(0.5*sum((X-D*alpha).^2));
end

