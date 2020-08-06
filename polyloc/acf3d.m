% Calculate 3d autocorrelation function for detections.
%
% Input:
%   detections : 1xT array of struct('x', [1xN double], 'y', [1xN double])
%       Note: we use the index in the struct array as frame number, i.e.
%             detections(fr) are the detections in frame fr.
%   spec : struct with fields xdim, xres, tdim
%       The *dim values determine extent of the acf in the space and time
%       directions, xres is the spatial resolution, i.e. voxel size.
%       Note: xres only enters via histcounts2, which seems to be *faster*
%             for higher resolution!
% Parameters:
%   normalization : 'probability', 'counts'
%       whether to normalize everything by the total detection count.
%       Default: 'probability', i.e. the center voxel of the acf is 1
%   showProgress : double
%       update the progress bar every x seconds. Set to Inf for no progress
%       bar.
%       default: 1
%   deleteCenter : logical
%       whether to set the center voxel to 0. Obsolete; use clean_acf.m
%       default: false
%   attachNegativeTimes : logical
%       if set to false, only output the acf for positive lag (since it's
%       point symmetric around the origin anyways). Default: true
%   verbose : show progress info. Default: true
%
% Output:
%   acf : 3d autocorrelation function of the detections
%
% (c) Simon Grosse-Holz, 2020

function acf = acf3d(detections, spec, varargin)
    % Input processing
    p = inputParser;
    p.addParameter('normalization', 'probability', @(norm) ismember(norm, {'probability', 'count'}));
    p.addParameter('showProgress', 1, @(i) ~mod(i, 1));
    p.addParameter('deleteCenter', false, @islogical);
    p.addParameter('attachNegativeTimes', true, @islogical);
    p.addParameter('verbose', true, @islogical);
    p.parse(varargin{:});
    params = p.Results;

    % Get the spatial bin edges, such that we have a bin centered at 0
    dx = spec.xres/2 : spec.xres : spec.xdim+(0.99*spec.xres);
    dx = [-dx(end:-1:1), dx];

    % Initialize
    acf = zeros(length(dx)-1, length(dx)-1, spec.tdim+1);
    T = length(detections);

    % Progress bar
    progressbar('init', 'what', 'ACF', 'silent', ~params.verbose);
    for t = 1:T
        progressbar('update', t/T);

        % Skip empty frames
        if isempty(detections(t).x)
            continue;
        end

        for t2 = t:min(T, t+spec.tdim)
            if isempty(detections(t2).x)
                continue;
            end

            diffx = detections(t).x - detections(t2).x';
            diffy = detections(t).y - detections(t2).y';
            h = histcounts2(diffx(:), diffy(:), dx, dx);
            acf(:, :, t2-t+1) = acf(:, :, t2-t+1) + h;
        end
    end % for t = 1:T
    progressbar('finalize');

    % Some post-processing, guided by parameter switches
    ind0 = find(dx(1:(end-1)) <= 0 & dx(2:end) > 0);
    if strcmp(params.normalization, 'probability')
        acf = acf / acf(ind0, ind0, 1);
    end
    if params.deleteCenter
        acf(ind0, ind0, 1) = 0;
    end
    if params.attachNegativeTimes
        acf = cat(3, acf(end:-1:1, end:-1:1, end:-1:2), acf);
    end
end
