% Calculate pairwise differences of detections for given time lag
%
% Input:
%   detections : the usual detections array
%   tau : the time lag (in frames)
%%% Parameters: (not implemented)
%%%   direction : 'xy', 'r2'
%%%       'xy' gives two dimensional difference vector
%%%       'r2' gives radial distance squared
%%%       default: r2
%%%   drift : 1x2 double, 'mode' or 'none'
%%%       expected drift over one frame. The drift that will be subtracted
%%%       from the differences is then given by tau*drift.
%%%       Set to 'mode' to determine the drift from the data as the mode of
%%%       the distribution.
%%%       default: 'none'
%
% Output:
%   dif : the distances. For direction = 'xy' this is Nx2, for direction =
%         'r2' it's 1xN
%%%   mu : the drift that was subtracted

function dif = pairwise_diff(detections, tau, varargin)
%     p = inputParser;
%     p.addParameter('direction', 'r2', @(dir) ismember(dir, {'xy', 'r2'}));
%     p.addParameter('drift', 'none');
%     p.parse(varargin{:});
%     params = p.Results;
    
    % Setup
    Ls = arrayfun(@(fr) length(fr.x), detections);
    nel = sum(Ls((tau+1):end).*Ls(1:(end-tau)));
    dif = nan(nel, 2);
%     dify = nan(1, nel);

    % Get raw differences
    ptr = 0;
    for t = (tau+1):length(detections)
        mydx = detections(t).x - detections(t-tau).x';
        mydy = detections(t).y - detections(t-tau).y';
        
        inc = numel(mydx);
        dif(ptr+(1:inc), 1) = mydx(:);
        dif(ptr+(1:inc), 2) = mydy(:);
        ptr = ptr + inc;
    end

%%% These are nice features in principle, but actually shouldn't be in here
%%% for code structural reasons (is a separate task). Also it doesn't work
%%% as well
%     % Set up drift correction
%     if ischar(params.drift)
%         if strcmp(params.drift, 'mode')
%             mu = [halfSampleMode(difx), halfSampleMode(dify)];
%         else
%             mu = [0, 0];
%         end
%     else
%         mu = tau*params.drift;
%     end
%     
%     % Give appropriate return value
%     switch params.direction
%         case 'xy'
%             dif = [difx', dify'];% - mu;
%         case 'r2'
%             dif = (difx - mu(1)).^2 + (dify - mu(2)).^2;
%     end
end