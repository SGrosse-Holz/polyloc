% Links together the clusters detected in two consecutive frames. If there
% are conflicts (i.e. clusters merging, =>-, or diverging -<=, or anything
% more complicated), each leg into the vertex is labelled as one cluster
% and the vertex written into the conflicts list.
%
% Input:
%   clustermap : the current (i.e. last frame) map of clusters
%   new_clustermap : the new clustermap (haha)
%   N_clusters : the number of clusters already detected, i.e. up to
%                which id number we cannot assign to new clusters
% 
% Output:
%   clustermap : updated for current frame
%   conflicts : cell array of lists of clusterIDs, describing conflicting
%               vertices
%   N_clusters : the updated total number of clusters detected
%
% (c) Simon Grosse-Holz, 2020

function [clustermap, conflicts, N_clusters] = link_clusters(clustermap, new_clustermap, N_clusters)
    N_newclusters = max(new_clustermap(:)); % new_clustermap labels clusters from 1 to N
    new_clusterids = zeros(N_newclusters);
    conflicts = {};
    N_clusters_store = N_clusters; % store for later reference of what is a new cluster
    
    % The actual linking
    for i = 1:N_newclusters
        old_ids = unique(clustermap(new_clustermap == i));
        old_ids = old_ids(old_ids ~= 0); % Remove 0
        switch length(old_ids)
            case 0
                N_clusters = N_clusters + 1;
                new_clusterids(i) = N_clusters;
            case 1
                new_clusterids(i) = old_ids;
            otherwise
                N_clusters = N_clusters + 1;
                new_clusterids(i) = N_clusters;
                conflicts = [conflicts, [old_ids(:)', N_clusters]];
        end
    end
    
    % Check for divergence of clusters (i.e. -<=)
    [~, ind] = unique(new_clusterids);
    multip_ids = unique(new_clusterids(setdiff(1:length(new_clusterids), ind)));
    for i = 1:length(multip_ids)
        ind = find(new_clusterids == multip_ids(i));
        for j = 1:length(ind)
            N_clusters = N_clusters + 1;
            new_clusterids(ind(j)) = N_clusters;
        end
        conflicts = [conflicts, [multip_ids(i), (N_clusters-length(ind)+1):N_clusters]];
    end
    
    % Search for multiplicities
    % Below we assume that each cluster appears in at most one conflict
    conflict_ids = unique([conflicts{:}]);
    for i = 1:length(conflict_ids)
        ind = cellfun(@(c) any(c == conflict_ids(i)), conflicts);
        if sum(ind) > 1
            conflicts = [conflicts(~ind), unique([conflicts{ind}])]; % Concatenate everything that has the same cluster in it
        end
    end
    
    % Make sure that nothing is linked to a cluster involved in a conflict
    % Uses conflict_ids from above, should be the last post-proc step
    for i = 1:length(new_clusterids)
        cid = new_clusterids(i);
        if ismember(cid, conflict_ids) && cid <= N_clusters_store
            N_clusters = N_clusters + 1;
            new_clusterids(i) = N_clusters;
            ind = find(cellfun(@(c) ismember(cid, c), conflicts), 1, 'first');
            conflicts{ind} = [conflicts{ind}, N_clusters];
        end
    end
    
    % Generate new clustermap
    clustermap(:) = 0;
    for i = 1:N_newclusters
        clustermap(new_clustermap == i) = new_clusterids(i);
    end
end
