% Remove the background signal from the acf.
% Idea: the signal in the center slice of the acf should be Poisson
%       distributed. Since this is additive, subtract the mean from
%       everything, and then set a threshold at the 99th percentile of this
%       Poisson distribution to cut off noise
% Also: Normalize to the (0, 0, 1) voxel. Since this might be noisy with
%       high resolution, determine all the voxels at dt=1 that make up one
%       pixel, and normalize to their average.
%
% Input:
%   acf : normalized as counts! (Such that the Poisson argument works out)
%
% Parameters:
%   percentile : the Poisson percentile determining the threshold.
%       default: 99
%   normalizationSize : edge length of the maximal volume used for
%       normalization, in voxels. Will be floor()'d, so can be double.
%       default: 1
%
% Output:
%   acf : cleaned up acf
%
% (c) Simon Grosse-Holz, 2020

function acf = clean_acf(acf, varargin)
    p = inputParser;
    p.addParameter('percentile', 99, @(x) isnumeric(x) && x < 100);
    p.addParameter('normalizationSize', 0.5, @isnumeric);
    p.parse(varargin{:});
    params = p.Results;
    
    % Get MLE for lambda from the center slice
    center_inds = (size(acf)-1)/2 + 1;
    cl = acf(:, :, center_inds(3));
    cl(center_inds(1), center_inds(2)) = 0;
    lambdaMLE = sum(cl, 'all')/(numel(cl)-1); % Exclude the center voxel
    
    % For cell tracking data, which are semi-artificial, there is no
    % background to subtract
    if lambdaMLE ~= 0
    
        % Find desired percentile
        x = floor(lambdaMLE):ceil(4*lambdaMLE);
        cdf = poisscdf(x, lambdaMLE);
        ind = find(cdf < params.percentile/100, 1, 'last');
        threshold = x(ind)+1;

        % Remove background
        acf = acf - lambdaMLE;
        acf(acf < threshold - lambdaMLE) = 0; % Pay attention to the order of subtracting mean and thresholding
    end
    
    % Set the center plane to be something reasonable, such that we don't
    % disconnect clusters
    acf(:, :, center_inds(3)) = 0.5*(acf(:, :, center_inds(3)-1) + acf(:, :, center_inds(3)-1));
    
    % Find the voxels we want to normalize to
    nvox = max(floor(params.normalizationSize), 1); % side length of the voxel square to average over
    nvox = floor((nvox-1)/2); % number of voxels on each side
    ind = center_inds(1)+(-nvox:nvox);
    
    % Normalize
    norm = mean(acf(ind, ind, center_inds(3)), 'all');
    acf = acf / norm;
end
