function X = preproc_img(X)

X = X./255;

m = mean(X(:))*ones(size(X));
X = X-m;

w = 

X=X ./ repmat(sqrt(sum(X.^2)),[size(X,1) 1]);

end

