% Core part of the algorithm: find the connected clusters in the acf map
%
% Input:
%   detections : struct array such as returned by load_data
%   acf : 3d acf of the detections
%   acfSpec : acf meta information, most importantly the spatial resolution
%   cluster_cutoff : the cutoff to use for clustering in the acf map
% Parameters:
%   showProgress : integer
%       after how many seconds to update the progress bar. Set to Inf
%       for no progress bar.
%       default: 1
%   verbose : logical
%       Whether to display information at all. default: true
%   method : 'watershed' or 'threshold'
%       default: 'watershed'
%
% Output:
%   detections : the input struct array, with an additional field cluster
%                containing a clusterID > 0, or 0 if the detection did not
%                belong to any cluster
%   conflicts : a list of conflicting clusters (such as merging or
%               diverging)
%
% (c) Simon Grosse-Holz, 2020

function [detections, conflicts] = find_clusters(detections, acf, acfSpec, cluster_cutoff, varargin)
    % input parsing
    p = inputParser;
    p.addParameter('showProgress', 1, @isnumeric);
    p.addParameter('verbose', true, @islogical);
    p.addParameter('method', 'watershed', @(x) ismember(x, {'watershed', 'threshold'}));
    p.parse(varargin{:});
    params = p.Results;

    % Initialize / Setup
    mapSpec = get_mapSpec(detections, acfSpec.xres);
    detections = detections_addBins(detections, mapSpec.bins);
    clustermap = zeros(mapSpec.fullmap_size(1:2));
    N_clusters = 0;
    conflicts = {};
    
    % Run
    progressbar('init', 'what', 'Clustering', 'silent', ~params.verbose);
    for t = 1:length(detections)
        progressbar('update', t/length(detections));
        
        % Get acf map, find clusters and link them to last frame
        map = map4frame(t, detections, acf, mapSpec.fullmap_size);
        if strcmp(params.method, 'watershed')
            map(map < cluster_cutoff) = 0;
            new_clustermap = watershed(-map);
            new_clustermap(map < cluster_cutoff) = 0;
        else % method = threshold
            clusters = bwconncomp(imopen(map >= cluster_cutoff, ones(3)), 8);
            clusters = clusters.PixelIdxList;
            new_clustermap = zeros(size(map));
            for i = 1:length(clusters)
                new_clustermap(clusters{i}) = i;
            end
        end
        
        [clustermap, new_conflicts, N_clusters] = link_clusters(clustermap, new_clustermap, N_clusters);
        conflicts = [conflicts, new_conflicts];
        
%         % For debugging
%         showmap = mod(clustermap, 64)+1;
%         showmap(clustermap == 0) = 0;
%         showmap(1:64) = 1:64;
%         L = labeloverlay(map/max(map(:)), showmap);
%         imshow(L);
%         hold on;
%         scatter(2*detections(t).y-8.5, 2*detections(t).x-8.5, 'rx'); % adapt to data
%         title(sprintf('t = %d', t));
        
        % Add clusters to data structure
        detections(t).cluster = clustermap(detections(t).bin - (t-1)*numel(map));
    end % for t = 1:T
    progressbar('finalize');
end
