% Generate detections for a given conflict
%
% Input:
%   conf : the conflict for which to create the map, i.e. a list of
%       trajectory ids.
%   trajs : the list of trajectories
%   acfSpec : a struct with a field xres giving the spatial resolution to
%       use for the mapping
%
% Output:
%   detections : the detections belonging to this conflict
%   mapSpec : physical dimensions of the map, needed to match it up with
%             detections
%
% (c) Simon Grosse-Holz, 2020

function [detections, mapSpec] = detections_from_conflict(conf, trajs, acfSpec)
    trajs = trajs(ismember([trajs.id], conf));
    
    % Get the detections
    trajdata = struct();
    trajdata.x = cat(1, trajs.x);
    trajdata.y = cat(1, trajs.y);
    trajdata.t = cat(1, trajs.t);
    
    mint = min(trajdata.t);

    detections = struct('x', {}, 'y', {});
    for t = mint:max(trajdata.t)
        x = trajdata.x(trajdata.t == t);
        y = trajdata.y(trajdata.t == t);
        detections(t-mint+1) = struct('x', x, 'y', y);
    end
    
    % Determine the volume of interest
    mapSpec = get_mapSpec(detections, acfSpec.xres);
    mapSpec.mint = mint; % For later reconstruction of the trajectories
    
    % Add bin information
    detections = detections_addBins(detections, mapSpec.bins);
end
