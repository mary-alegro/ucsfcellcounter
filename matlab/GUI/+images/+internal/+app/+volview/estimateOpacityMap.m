function [alpha,vout] = estimateOpacityMap(V)
% Estimate opacity map map for use in direct volume rendering.
% F = estimateOpacityMap(V) estimates the 1-D opacity map F that maps a given
% scalar valued intensity value in V(X,Y,Z) to an alpha value that
% determines the level of opacity/transparency during volume rendering.

%   References:
%   -----------
%   [1] G. Kindlmann, "Semi-Automated Generation of Transfer Functions For
%   Direct Volume Rendering", VVS '98 Proceedings of the 1998 IEEE symposium
%   on Volume Visualization, Pages 79-86, 1998

%   Copyright 2014 The MathWorks, Inc.

% Move to double to compute directional derivatives in floating point
V = double(V);

FgradMag = computeFirstDirectionalDerivative(V);

Fsecond = estimateSecondDirectionalDerivative(V);

[VolHist,vBins,gradBins,secondBins] = buildHistogramVolume(V,FgradMag,Fsecond);

[g,h] = computeDirectionDirCentroids(VolHist,gradBins,secondBins);

alpha = computeAlphaMapFromGandH(g,h);

vout = constructVout(vBins);

function Fprime = computeFirstDirectionalDerivative(V)

[FgradX,FgradY,FgradZ] = gradient(V);
Fprime = sqrt(FgradX.^2 + FgradY.^2 + FgradZ.^2);

function FprimePrime = estimateSecondDirectionalDerivative(V)

% Determine f'' using the Laplacian
h = zeros(3,3,3);
h(:,:,1) = [0 0 0; 0 1 0; 0 0 0];
h(:,:,2) = [0 1 0; 1 -6 1; 0 1 0];
h(:,:,3) = h(:,:,1);

FprimePrime = imfilter(V,h,'replicate');

function gradientImage = clipOutliers(gradientImage)
% This function saturates 1% of the outliers on both the LHS and the RHS
% of the CDF.

probThreshold = .99;

[N,edges] = histcounts(gradientImage,1000,'Normalization','cdf');
idxMax = find(N >= probThreshold,1,'first');
idxMin = find(N >= 1-probThreshold,1,'first');
maxGrad = edges(idxMax);
minGrad = edges(idxMin);

gradientImage(gradientImage > maxGrad) = maxGrad;
gradientImage(gradientImage < minGrad) = minGrad;

function [VolHist,vBins,gradBins,secondBins] = buildHistogramVolume(V,FgradMag,Fsecond)

NUM_BINS = 256;

FgradMag = clipOutliers(FgradMag);
Fsecond  = clipOutliers(Fsecond);

[~,vBins,idxVal] = histcounts(V,NUM_BINS);
[~,gradBins,idxPrime] = histcounts(FgradMag,NUM_BINS);
[~,secondBins,idxPrimePrime] = histcounts(Fsecond,NUM_BINS);

% Form HistogramVolume given binned index volues for f, f', and f''for each
% sample location in the volume.
subs = [idxVal(:), idxPrime(:), idxPrimePrime(:)]; 
val = 1;
VolHist = accumarray(subs,val,[NUM_BINS,NUM_BINS,NUM_BINS]);

function [g,h] = computeDirectionDirCentroids(VolHist,gradBins,secondBins)

[g,h] = deal(nan(1,size(VolHist,1)));

gradFirstBinCenter = gradBins(1)+diff(gradBins(1:2))/2;
gradLastBinCenter = gradBins(end)-diff(gradBins(1:2))/2;
y = linspace(gradFirstBinCenter,gradLastBinCenter,length(gradBins)-1);

secondDiffFirstBinCenter = secondBins(1)+diff(secondBins(1:2))/2;
secondDiffLastBinCenter = secondBins(end)-diff(secondBins(1:2))/2;
x = linspace(secondDiffFirstBinCenter,secondDiffLastBinCenter,length(secondBins)-1);

[x,y] = meshgrid(x,y);
for v = 1:size(VolHist,1)
    Vslice = squeeze(VolHist(v,:,:));
    normalization = sum(Vslice(:));
    if normalization ~=0
        g(v) = sum(y(:) .* Vslice(:)) ./ normalization;
        h(v) = sum(x(:) .* Vslice(:)) ./ normalization;
    end
end

g = naninterp(g);
h = naninterp(h);

function alpha = computeAlphaMapFromGandH(g,h)

sigma = 2*sqrt(exp(1))*max(g) ./ ( max(h)-min(h) + eps);
gthresh = 0;
p = -sigma^2 * h ./ max(g-gthresh,0);

% For now, use Gaussian to model b(x), the boundary modulation function.
% This could be exposed as a parameter to allow users control of how alpha
% transitions from low to high values.
x = -8:0.1:8;
mu = 0;
sigmaB = 1;
g = 1/(sigmaB*sqrt(2*pi))*exp(-(x-mu).^2 / (2*sigmaB^2));
g = g ./ max(g(:));
alpha = interp1(x,g,p,'pchip',0);

function vout = constructVout(vBins)

vFirstBinCenter = vBins(1)+diff(vBins(1:2))/2;
vLastBinCenter  = vBins(end)-diff(vBins(1:2))/2;
vout = linspace(vFirstBinCenter,vLastBinCenter,length(vBins)-1);

function X = naninterp(X) 
% Interpolate over NaNs 
X(isnan(X)) = interp1(find(~isnan(X)), X(~isnan(X)), find(isnan(X)), 'linear'); 




