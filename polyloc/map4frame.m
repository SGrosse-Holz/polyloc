% Calculate the convolution of acf and detections for one frame
%
% Input:
%   fr : the frame number for which to calculate the map
%   detections : struct-array of detections such as returned by load_data,
%       with an additional field bin, such as created by detections_addBins
%   acf : 3d array containing the acf, centered around the zero voxel. Such
%       as returned by acf3d
%   fullmap_size : 1x3 int specifying the extent of the full 3d map. This
%       is necessary for ind2sub
% Parameters:
%   goByFrame : logical
%       if true, calculate the contribution for each frame individually
%       if false, do one 3d convolution. This might be memory intensive
%       default: true
%       Note: this was implemented because it could be a bit faster, at the
%             expense of more memory. Quick benchmarking reveals that this
%             is not true though, so there is no real use case for this
%             option.
%
% Output:
%   map : the 2d matrix containing the wanted convolution
%
% (c) Simon Grosse-Holz, 2020

function map = map4frame(fr, detections, acf, fullmap_size, varargin)
    % Input parsing
    p = inputParser;
    p.addParameter('goByFrame', true, @islogical);
    p.parse(varargin{:});
    
    acf_tsize = (size(acf, 3)-1)/2;
    
    if p.Results.goByFrame
        map = zeros(fullmap_size(1:2));
        convbase = zeros(fullmap_size(1:2));
        for fr2 = max(1, fr-acf_tsize):min(fullmap_size(3), fr+acf_tsize)
            if isempty(detections(fr2).x)
                continue;
            end
            
            acfind = fr - fr2 + acf_tsize + 1;
            indoffset = (fr2-1)*fullmap_size(1)*fullmap_size(2);
            convbase(detections(fr2).bin - indoffset) = 1;
            map = map + conv2(convbase, acf(:, :, acfind), 'same');
            convbase(detections(fr2).bin - indoffset) = 0; % Explicitly resetting gives performance (a bit)
        end
    else
        framerange = [max(1, fr-acf_tsize), min(fullmap_size(3), fr+acf_tsize)];
        minframeoffset = (framerange(1)-1)*fullmap_size(1)*fullmap_size(2);
        map3d = zeros([fullmap_size(1), fullmap_size(2), ...
                       framerange(2)-framerange(1) + 1]);
        for i = framerange(1):framerange(2)
            map3d(detections(i).bin - minframeoffset) = 1;
        end
        map3d = convn(map3d, acf, 'same');
        map = map3d(:, :, fr-framerange(1)+1);
    end
end
        
