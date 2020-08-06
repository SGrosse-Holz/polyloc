% Generate trajectories from the clustered data. The detections can either
% have a field 'cluster' with an id, or we give the full 3d clusters as a
% cell array of bin lists. In that case, also give a list of ids to use.
%
% Input:
%   detections : struct array such as returned by find_clusters
% Optional:
%   clusters : cell of lists of bins, forming the clusters
%   clusterIDs : list of IDs for the given clusters
%
% Output:
%   trajs : struct array with fields x, y, t, id
%           id is the id of the cluster the trajectory was assembled from
%
% (c) Simon Grosse-Holz, 2020

function trajs = clusters2trajs(detections, clusters, clusterIDs)
    % Assemble array structure from structure array
    data = struct();
    data.x = cat(1, detections(:).x);
    data.y = cat(1, detections(:).y);
    
    if nargin < 2
        data.cluster = cat(1, detections(:).cluster);
    else
        data.bin = cat(1, detections(:).bin);
        clustermap = zeros(1, max(data.bin));
        for i = 1:length(clusters)
            clustermap(clusters{i}) = clusterIDs(i);
        end
        data.cluster = clustermap(data.bin);
    end
    
    
    data.t = zeros(size(data.x));
    lastind = 0;
    for t = 1:length(detections)
        newind = lastind + length(detections(t).x);
        data.t((lastind+1):newind) = t;
        lastind = newind;
    end

    % Get clusters
    N_cluster = max(data.cluster);
    trajs = struct('x', {}, 'y', {}, 't', {}, 'id', {});
    n_traj = 0;
    for i = 1:N_cluster
        ind = (data.cluster == i);
        if sum(ind) < 1
            continue;
        end
        
        t = data.t(ind);
        x = data.x(ind);
        y = data.y(ind);
        
        n_traj = n_traj + 1;
        trajs(n_traj) = struct('x', x, 'y', y, 't', t, 'id', i);
    end
end
