% A little helper function that displays a progress bar in a for loop.
%
% Usage:
%   progressbar('init', ...);
%   for i = 1:imax
%       progressbar('update', i/imax);
%       ... % Do stuff
%   end
%   progressbar('finalize');
%
% Parameters:
%   what : short string describing what's happening
%       default: ''
%   barlength : length of the progressbar, in characters
%       default: 50
%   updateEvery : maximal update frequency, in seconds (if the loop runs
%       slower than that, of course there's nothing to do here. In that
%       case call progressbar('update', ...) more often). This is just to
%       prevent constant output from fast loops
%       default: 0.5
%   silent : an easy way to switch off the bar, without having to change
%       more than one thing in the code
%       default: false (obviously)
%
% (c) Simon Grosse-Holz, 2020

function progressbar(cmd, varargin)
    persistent L
    persistent mytic
    persistent lasttoc
    persistent params
    persistent started
    persistent vprintf
    
    switch cmd
        case 'init'
            p = inputParser;
            p.addParameter('what', '');
            p.addParameter('barlength', 50);
            p.addParameter('updateEvery', 0.5);
            p.addParameter('silent', false);
            p.parse(varargin{:});
            params = p.Results;
            
            L = 0;
            mytic = tic;
            lasttoc = -Inf; % Such that the first call to update will actually draw
            started = false;
            
            vprintf = @fprintf;
            if params.silent
                vprintf = @(varargin) 0;
            end
            
        case 'update'
            if ~started && ~isempty(params.what)
                vprintf('*** %s ***\n', params.what);
                started = true;
            end
            
            newtoc = toc(mytic);
            if newtoc >= lasttoc + params.updateEvery
                lasttoc = newtoc;
                
                fprog = varargin{1};
                progress = round(fprog*params.barlength);
                outstr = sprintf(['[', repmat('=', 1, progress), ...
                                       repmat(' ', 1, params.barlength-progress), ...
                                  '] ( %3.0f%%%% ), t = %.0fs\n', ... % Double escape % sign
                                  'expected time remaining: %.1fmin\n' ...
                                 ], fprog*100, lasttoc, lasttoc*(1/fprog-1)/60);
                vprintf([repmat('\b', 1, L), outstr]);
                L = length(outstr)-1; % -1 for (singly) escaped % sign
            end
            
        case 'finalize'
            vprintf(repmat('\b', 1, L));
            vprintf(['[', repmat('=', 1, params.barlength), ...
                     '] ( 100%% ), t = %.0fs\n'], lasttoc);
            vprintf('total time: %.1fmin\n', toc(mytic)/60);
    end
end
