% Calculate the voxel structure of the 3d map from the data
%
% Input:
%   detections : struct array, such as returned by load_data
%   xres : double, spatial resolution in pixels.
%
% Output:
%   mapSpec : struct with fields
%       bins : struct specifying bin edges in x and y
%       fullmap_size : size of the full 3d map (for use in sub2ind)
%
% (c) Simon Grosse-Holz, 2020

function mapSpec = get_mapSpec(detections, xres)
    dataExtent = [min(cat(1, detections(:).x)), max(cat(1, detections(:).x)); ...
                  min(cat(1, detections(:).y)), max(cat(1, detections(:).y))];
    bins.x = ((dataExtent(1, 1)-xres):xres:(dataExtent(1, 2)+2*xres))-xres/2;
    bins.y = ((dataExtent(2, 1)-xres):xres:(dataExtent(2, 2)+2*xres))-xres/2;
    fullmap_size = [length(bins.x)-1, length(bins.y)-1, length(detections)];
    
    mapSpec = struct('bins', bins, 'fullmap_size', fullmap_size);
end
