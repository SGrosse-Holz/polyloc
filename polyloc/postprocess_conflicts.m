% Revisit all the conflicts and resolve them if possible. If not possible,
% delete the corresponding trajectories
%
% Input:
%   conflicts : cell of lists of trajectory ids
%   trajs : array of struct, such as generated by clusters2trajs
%   acf : the acf to use for convolutions
%   acfSpec : struct containing a field xres specifying the spatial
%             resolution of the acf
%   threshold : the clustering threshold
%
% Output:
%   trajs : the trajectory array, cleaned up
%
% (c) Simon Grosse-Holz, 2020

function [conflicts, trajs] = postprocess_conflicts(conflicts, trajs, acf, acfSpec, threshold, method)
    newtrajs = cell(1, length(conflicts));
    newconflicts = cell(1, length(conflicts));
    maxID = max([trajs.id]);
    for i = 1:length(conflicts)
        [detections, mapSpec] = detections_from_conflict(conflicts{i}, trajs, acfSpec);

        % Clustering!
        [detections, newconflicts{i}] = find_clusters(detections, acf, acfSpec, threshold, 'verbose', false, 'method', method);

        % Get trajectories
        newtrajs{i} = clusters2trajs(detections);
        [newconflicts{i}, newtrajs{i}] = clean_conflicts(newconflicts{i}, newtrajs{i});
        
        % Adapt ids to be compatible with the big array
        if ~isempty(newtrajs{i})
            for j = 1:length(newtrajs{i})
                newtrajs{i}(j).t = newtrajs{i}(j).t + mapSpec.mint - 1;
                newtrajs{i}(j).id = newtrajs{i}(j).id + maxID;
            end
            for j = 1:length(newconflicts{i})
                newconflicts{i}{j} = newconflicts{i}{j} + maxID;
            end
            maxID = max([newtrajs{i}.id]);
        end
    end
    
    trajs = trajs(~ismember([trajs.id], [conflicts{:}]));
    trajs = [trajs, newtrajs{:}];
    conflicts = [newconflicts{:}];
end
