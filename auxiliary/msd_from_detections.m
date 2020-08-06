% Estimate the MSD just from the detections
%
% Input:
%   detections : an array of frames with detections, following the standard
%       structure
% Parameters:
%   maxlag : the maximum lag time for which to calculate anything, in
%       frames
%       default: Inf, in which case all the lags are calculated
%   binsize : width of histogram bins for fitting the density. A good value
%       for this is around the (expected) localization accuracy. Assuming
%       the data in 'detections' to be in pixels, we set the following
%       default: 0.1
%   maxDisplacement : The maximum displacement up until which to draw
%       histograms etc. I.e. we assume that everything beyond this cutoff
%       will always be background.
%       default: 100
%   bgEstimator : 'histogram' or 'kde'
%       Whether to estimate the background as a simple histogram (raises
%       the noise level a bit) or as kernel density (takes longer).
%       default: kde
%   silent : logical
%       suppress progress reporting.
%       default: false
%
% Output:
%   msd : the variance of the central Gaussian in the displacements
%   mu : the mean of that central Gaussian
%   N : the (approximate) number of data points entering the estimate at
%       time t

function [msd, mu, N] = msd_from_detections(detections, varargin)
    p = inputParser;
    p.addParameter('maxlag', Inf);
    p.addParameter('binsize', 0.1);
    p.addParameter('maxDisplacement', 100);
    p.addParameter('bgEstimator', 'kde', @(est) ismember(est, {'histogram', 'kde'}));
    p.addParameter('silent', false);
    p.parse(varargin{:});
    params = p.Results;
    
    params.maxlag = min((length(detections)-1), params.maxlag);

    msd = nan(1, params.maxlag);
    N = nan(1, params.maxlag);
    mu = nan(params.maxlag, 2);
    
    % Get the background signal from displacements at dt = 0
    dif = pairwise_diff(detections, 0, 'direction', 'xy');
    dif = dif((dif(:, 1) ~= 0 | dif(:, 2) ~= 0), :); % Remove self-terms
    binEdges = (0:params.binsize:params.maxDisplacement) + 0.5*params.binsize;
    binEdges = [-flip(binEdges), binEdges]; % make sure this is symmetric
    binMids = 0.5*(binEdges(2:end) + binEdges(1:(end-1)));
    switch params.bgEstimator
        case 'kde'
            fprintf('Estimating background density...\n'); % This might take some time
            bkgEst = [ksdensity(dif(:, 1), binMids); ksdensity(dif(:, 2), binMids)];
        case 'histogram'
            bkgEst = [histcounts(dif(:, 1), 'BinEdges', binEdges, 'normalization', 'pdf'); ...
                      histcounts(dif(:, 2), 'BinEdges', binEdges, 'normalization', 'pdf'); ];
    end
    
    % Actual MSD calculation
    progressbar('init', 'what', 'MSD from detections', 'silent', params.silent);
    for tau = 1:params.maxlag
        progressbar('update', tau/params.maxlag);
        
        dif = pairwise_diff(detections, tau, 'direction', 'xy');
        sigsq = [nan, nan];
        mode = [nan, nan];
        for i =  1:2 % do cartesian coordinates independently
            curdens = histcounts(dif(:, i), 'BinEdges', binEdges, 'Normalization', 'pdf');
            
            % Remove background and fit Gaussian
            curdens = curdens - bkgEst(i, :);
            try
                gfit = fit(binMids', curdens', 'gauss1'); % Note that starting points for the fit are optimized by MatLab
            catch
                % An error during fitting mostly just means that the fit
                % didn't converge, so just skip this data point. Initial
                % values are set to nan, so everything fine
                continue;
            end
            
            % Get results
            mode(i) = gfit.a1;
            mu(tau, i) = gfit.b1;
            sigsq(i) = gfit.c1^2 / 2;
        end
        
        msd(tau) = sum(sigsq);
        N(tau) = mean(mode.*sqrt(2*pi*sigsq)*size(dif, 1));

    end
    progressbar('finalize');
end




%%%%%%%%%%%%%%%%% OLD CODE %%%%%%%%%%%%%%%%%%%

%%%%%%
%     Ls = arrayfun(@(fr) length(fr.x), detections);
%%%%%
%     % Use a GMM to estimate drift. Everything else will be done from
%     % Rayleigh fitting
%     dif = [pairwise_diff(detections, 1, 'direction', 'x')', ...
%            pairwise_diff(detections, 1, 'direction', 'y')'];
%     sig = [1, 1];
%     sig(1, :, 2) = [max(dif(:)), max(dif(:))];
%     gmm = fitgmdist(dif, 2, ...
%         'Start', struct('mu', [0, 0; 0, 0], 'Sigma', sig, 'ComponentProportion', [0.1, 0.9]), ...
%         'CovarianceType', 'diagonal');
% %     msd(1) = mean(gmm.Sigma(:, :, 1)); % Note that Sigma are *variances*
%     mu = gmm.mu(1, :);
% %     f(1) = gmm.ComponentProportion(1);
% %     fprintf('from GMM:\n\tmsd(1) = %f\n\tf(1) = %f\n\n', mean(gmm.Sigma(:, :, 1)), gmm.ComponentProportion(1));
%%%%%

%%%%%%%%%%%%%% flat background (Hough) %%%%%%%%%%%%%%%%%%%%%
        
%         dif = pairwise_diff(detections, tau, 'direction', 'xy');
%         sig = [nan, nan];
%         mode = [nan, nan];
%         for i =  1:2 % do cartesian coordinates independently
%             [vals, edges] = histcounts(dif(:, i), 'BinWidth', params.binsize, 'Normalization', 'pdf');
%             x = (edges(1:(end-1)) + edges(2:end))/2;
%             
%             % Hough transform inspired thresholding
%             thresh = exp(halfSampleMode(log(vals)));
%             
%             % Remove background and fit Gaussian
%             x = x(vals > thresh);
%             y = vals(vals > thresh) - thresh;
%             gfit = fit(x', y', 'gauss1', 'Start', [0.1/sqrt(2*pi), 0, 1]);
%             
%             % Get results
%             mode(i) = gfit.a1;
%             mu(tau, i) = gfit.b1;
%             sig(i) = gfit.c1/sqrt(2);
%         end
%         
%         msd(tau) = mean(sig)^2;
%         N(tau) = mean(mode)*sqrt(2*pi)*mean(sig)*size(dif, 1);
        
%%%%%%%%%%%%%% partial Rayleigh %%%%%%%%%%%%%%%%%%%%%%%
        
%         % Get the data and fit Rayleigh to the first bump
%         [r2, drift] = pairwise_diff(detections, tau, 'direction', 'r2');
%         [sigsq, frac] = fit_partial_Rayleigh(r2);
%         msd(tau) = sigsq;
%         N(tau) = frac*numel(r2);
%         mu(tau, :) = drift;
%         
% %         if tau == 1
% %             fprintf('from Rayleigh fit:\n\tmsd(1) = %f\n\tf(1) = %f\n\n', msd(1), f(1));
% %         end

%%%%%%%%%%%%% bad GMM %%%%%%%%%%%%%%%%%%%%%%%

%         nel = sum(Ls((tau+1):end).*Ls(1:(end-tau)));
%         dif = nan(1, nel);
% 
%         ptr = 0;
%         for t = (tau+1):length(detections)
%             mydx = detections(t).x - detections(t-tau).x';
%             inc = numel(mydx);
%             dif(ptr+(1:inc)) = mydx(:);
%             ptr = ptr + inc;
%         end
% 
%         sig = 1;
%         sig(1, 1, 2) = 1e3; % values!!
%         try
%             lastwarn('');
%             gmm = fitgmdist(dif', 2, 'Start', struct('mu', [0; 0], 'Sigma', sig, 'ComponentProportion', [0.5, 0.5]));
%             [~, id] = lastwarn;
%             if strcmp(id, 'stats:gmdistribution:FailedToConverge')
%                 fprintf('(HANDLED: %s)\n', id);
%                 continue;
%             end
% 
%             msd(tau) = gmm.Sigma(1);
%             mu(tau) = gmm.mu(1);
%             N(tau) = nel*gmm.ComponentProportion(1);
%         catch
%             continue;
%         end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%