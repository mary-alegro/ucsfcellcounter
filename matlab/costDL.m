function R = costDL(D,X,alpha,param)
    R = mean(0.5*sum((X-D*alpha).^2)+param.lambda*sum(abs(alpha)));
end

