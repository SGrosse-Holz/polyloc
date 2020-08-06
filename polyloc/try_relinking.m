% Attempt to link two trajectories together. This might fail if the
% trajectories are not in a reasonable temporal order
%
% Input:
%   conflicts, trajs as always
%   id1, id2 : ids of the trajectories to merge
%
% Output:
%   conflicts, trajs updated
%
% (c) Simon Grosse-Holz, 2020

function [conflicts, trajs] = try_relinking(conflicts, trajs, id1, id2)
    ind1 = find([trajs.id] == id1);
    ind2 = find([trajs.id] == id2);
    
    % Sort by time
    if min(trajs(ind1).t) > min(trajs(ind2).t)
        tmp = ind1;
        ind1 = ind2;
        ind2 = tmp;
    end
    
    % Only link if they are in good temporal order
    if max(trajs(ind1).t) < min(trajs(ind2).t)
        trajs(ind1).x = cat(1, trajs(ind1).x, trajs(ind2).x);
        trajs(ind1).y = cat(1, trajs(ind1).y, trajs(ind2).y);
        trajs(ind1).t = cat(1, trajs(ind1).t, trajs(ind2).t);
        % id stays whatever it is
        
        % Now just need to replace id2 with id1 everywhere
        for i = 1:length(conflicts)
            conflicts{i}(conflicts{i} == id2) = id1;
        end
        
        % and finally remove the merged trajectory
        trajs = trajs([trajs.id] ~= id2);
    end
end
