% A plotting routine for the standard detections structure (since it is a
% bit annoying to handle for this)
%
% Input:
%   detections : as usual, struct array with fields x, y
%   varargin : any other input will be forwarded to scatter3
%
% Output:
%   h : handle to the scatter plot

function h = scatter_detections(detections, varargin)
    % Assemble array structure from structure array
    data = struct();
    [~, catdim] = max(size(detections(1).x));
    data.x = cat(catdim, detections.x);
    data.y = cat(catdim, detections.y);
    data.t = zeros(size(data.x));
    lastind = 0;
    for t = 1:length(detections)
        newind = lastind + length(detections(t).x);
        data.t((lastind+1):newind) = t;
        lastind = newind;
    end

    h = scatter3(data.x, data.y, data.t, varargin{:});
end