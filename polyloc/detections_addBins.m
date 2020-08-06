% Add into the detection structure the number of the bin into which this
% detection would fall in the full 3d map
%
% Input:
%   detections : array of struct, such as returned by load_data
%   bins : struct with fields x, y. Both should be vectors specifying the
%          edges of the spatial bins in the map.
%
% Output:
%   detections : the input struct array, with the bins added
%
% (c) Simon Grosse-Holz, 2020

function detections = detections_addBins(detections, bins)
    fullmap_size = [length(bins.x)-1, length(bins.y)-1, length(detections)];
    for t = 1:length(detections)
        detections(t).bin = zeros(size(detections(t).x));
        for i = 1:length(detections(t).x)
            x = find(bins.x(1:(end-1)) <= detections(t).x(i) & bins.x(2:end) > detections(t).x(i));
            y = find(bins.y(1:(end-1)) <= detections(t).y(i) & bins.y(2:end) > detections(t).y(i));
            detections(t).bin(i) = sub2ind(fullmap_size, x, y, t);
        end
    end
end
