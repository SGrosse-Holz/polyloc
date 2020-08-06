% This is the main starting point of the algorithm, packed into a function
% for easy use. It's based off the code in scan_clustering.m which does the
% same things as a script and will be phased out when this one grows far
% enough
%
% Input:
%   can be given in the order specfied here, or as everything packed into
%   one single struct. If called without inputs, the function asks the user
%   for everything it needs. This behavior can be controlled with the
%   switches 'askFilename' and 'confirmParameters'. List of inputs:
%   filename : detections to track. Should be one of the recognized file
%       formats for load_data. Can be empty, in which case the user will be
%       asked to select a file.
%       default: ''
%   acfX : the spatial extent of the autocorrelation function. Gives the
%       scale for the detections and should be adapted to the expected
%       diffusivity / speed (such that there's negligible chances for
%       particles to diffuse out of the correlation volume). Should be
%       adapted such that the acf decays within its volume, which can be
%       done by using the switch 'checkACF'.
%       default: 5
%   acfT : the maximum lag time up to which to calculate the
%       autocorrelation function. Performance critical, i.e. larger values
%       are better, but slow everything down.
%       default: 20
%   acfxres : spatial resolution of the grid on which the acf and clusters
%       are calculated. Assuming coordinates are in pixels, a value of 0.5
%       appears reasonable.
%       default: 0.5
%   clusterThreshold : the minimum threshold to use in clustering. This is
%       normalized to the dominant region in the acf, so acf(dx=0, dt=1) is
%       of order 1.
%       default: 1
% Parameters:
%   askFilename : always ask for the filename
%       default: false
%   confirmParameters : show a dialog that asks the user to confirm the set
%       parameters / adapt them. Can be used to run the algorithm fully
%       interactively, without having to modify code.
%       default: false
%   checkACF : show the calculated acf and ask for confirmation /
%       adaptation of parameters
%       default: false
%   saveTo : file to save the calculated trajectories to.
%       default: '' (no saving)
%   varsToSave : cell array containing variable names to write to file.
%       Mostly used for debugging.
%       default: {'trajs'}
%   saveConflictingTo : filename for saving conflicting trajectories.
%       Mostly relevant when post-processing doesn't work properly.
%       default : 'conflicting_trajectories'
%   verbose : show some progress information
%       default: true
% Parameters that mostly don't have to be thought about:
%   maxPPiterations : maximum number of iterations for post-processing.
%       default: 20
%   acfCleanBackgroundPercentile : percentile to use for identifying a
%       threshold for the acf from the background signal.
%       default: 99
%   acfCleanNormalizationSizePx : size of the square of voxels at dt=1 that
%       the acf is normalized to. This parameter is given in pixels, i.e.
%       the coordinates of the detections. This makes it possible to tune
%       up the spatial resolution without having to touch anything else.
%       (Whether that's a good idea is another question).
%       default: 0.5 (roughly the localization accuracy)
%
% Output:
%   trajs : an array containing the found trajectories, each
%       being a struct with fields x, y, t, id.
%
% (c) Simon Grosse-Holz, 2020

function trajs = find_trajs(varargin)
    params = struct();
    % default algorithm parameter values
    params.filename = '';
    params.acfX = 5;
    params.acfT = 20;
    params.acfxres = 0.5;
    params.clusterThreshold = 1;
    % stuff controling execution of this function
    params.askFilename = false;
    params.confirmParameters = false;
    params.checkACF = false;
    params.saveTo = '';
    params.saveConflictingTo = 'conflicting_trajs';
    params.varsToSave = {'trajs'};
    params.verbose = true;
    % some more stuff, mostly to be kept the same
    params.maxPPiterations = 20;
    params.acfCleanBackgroundPercentile = 99;
    params.acfCleanNormalizationSizePx = 0.5;
    
    % process given inputs
    params = update_params_from_inputs(params, varargin);
    
    % verbosity aware print function
    vprintf = @fprintf;
    if ~params.verbose
        vprintf = @(varargin) 0;
    end
    
    % Read detections
    if isempty(params.filename) || params.askFilename
        detections = load_data;
    else
        detections = load_data(params.filename);
    end
    if ischar(detections)
        clear trajs
        return;
    end

    % Calculate & clean acf, possibly interactive
    if ischar(params.acfData) % i.e. acfData not directly given
        acfData = acfDataStorage();
        acfData.detections = detections;
        acfData.params = params;
        app = acf_interactive(acfData);
        waitfor(app);

        % Get the data that the app generated
        acf = acfData.acf;
        params = acfData.params;
    else
        acf = params.acfData.acf;
    end

    % Clustering!
    [detections, conflicts] = find_clusters(detections, acf, params.acfSpec, params.clusterThreshold, 'method', 'threshold');

    % Get trajectories                                     </detectionland>
    trajs = clusters2trajs(detections); %==================================
    %                                                      <trajectoryland>

    % Some obvious cleaning up of the conflicts, also adding trajectories that
    % have duplicate times
    [conflicts, trajs] = clean_conflicts(conflicts, trajs);
    vprintf('raw: %d trajectories, %d conflicts\n', length(trajs), length(conflicts));

    % Now do the actual post-processing of conflicts: just switch the
    % algorithms back and forth, until we reach a stationary state or a
    % maximum number of iterations
    nConflicts = Inf;
    maxToDo = params.maxPPiterations;
    while ~isempty(conflicts) && length(conflicts) < nConflicts && maxToDo > 0
        nConflicts = length(conflicts);
        maxToDo = maxToDo - 1;
        
        methods = {'watershed', 'threshold'};
        for i = 1:length(methods)
            vprintf('Post-processing %d conflicts\n', length(conflicts));
            [conflicts, trajs] = postprocess_conflicts(conflicts, trajs, acf, params.acfSpec, params.clusterThreshold, methods{i});
            [conflicts, trajs] = clean_conflicts(conflicts, trajs);
        end
    end
    if maxToDo == 0
        fprintf('reached maximum number (%d) of post-proc iterations. Check %s.mat', params.maxPPiterations, params.saveConflictingTo);
    end
    
    vprintf('after post-proc: %d trajectories, %d conflicts\n', length(trajs), length(conflicts));

    % Put trajectories that are still conflicting aside. Write them to
    % file, because this might be relevant when reaching max iterations,
    % but noone is gonna ask for this as an output argument
    ind_valid = ~ismember([trajs.id], [conflicts{:}]);
    trajs_conf = trajs(~ind_valid);
    trajs = trajs(ind_valid);
    vprintf('finally: found %d trajectories\n', length(trajs));
    
    % If noone has told us what to do with the trajectories, ask
    if isempty(params.saveTo) && nargout < 1
        [file, path] = uiputfile('trajs.mat', 'Select file to save trajectories');
        if ischar(file) % 'Cancel' makes uiputfile return 0
            params.saveTo = fullfile(path, file);
        end
    end

    % Save to file
    if ~isempty(params.saveTo)
        save(params.saveTo, params.varsToSave{:});
    end
    if ~isempty(params.saveConflictingTo)
        save(params.saveConflictingTo, 'trajs_conf');
    end
    
    % Stop return value, if not wanted
    if nargout == 0
        clear trajs
    end
end

% Do all the input processing and formatting
%
% Input:
%   params : a struct containing all the fields we want to have values for
%   toParse : the inputs to the main function, as a cell array. Usually
%       this should just be varargin (without {:} dereferencing)
%   confirm : should we ask the user for confirmation by default?
%       default: false
%
% Output:
%   params : the parameter structure, updated with new information

function params = update_params_from_inputs(params, toParse, confirm)
    if nargin < 3
        confirm = false;
    end
    
    % Check first argument by hand, since otherwise this logic is not
    % well-defined
    if ~isempty(toParse) && ischar(toParse{1}) && contains(toParse{1}, '.')
        % This looks like a filename, instead of a parameter
        % Note to self: don't have parameter names with dots
        params.filename = toParse{1};
        toParse(1) = [];
    end
    
    % the variables that can be specified as optional inputs. Everything
    % else is a parameter, which makes it easy to read in here, because we
    % can just react to whatever we're asked for by the default values
    % given in params
    optionals = {'filename', 'acfT', 'acfX', 'acfxres', 'clusterThreshold'};
    bareDefaults = {'', 20, 5, 0.5, 1}; % last resort default values
    
    % Get names
    askedFor = fieldnames(params);
    
    % Add optional arguments
    p = inputParser;
    for i = 1:length(optionals)
        def = bareDefaults{i};
        [~, ind] = ismember(optionals{i}, askedFor);
        if ind > 0
            def = params.(optionals{i});
            askedFor(ind) = [];
        end
        p.addOptional(optionals{i}, def);
    end
    
    % Add remaining ones as parameters
    for i = 1:length(askedFor)
        p.addParameter(askedFor{i}, params.(askedFor{i}));
    end
    
    % Add some specific functionality
    p.addParameter('acfData', '');
    
    % Parse
    p.parse(toParse{:});
    params = p.Results;

    % Check parameter values with the user / let them set the values
    if confirm || (isfield(params, 'confirmParameters') && params.confirmParameters)
        toConfirm = {'acfX', 'acfxres', 'acfT', 'clusterThreshold'};
        descs = {'acf, spatial extent (px)', ...
                 'acf, spatial resolution (px)', ...
                 'acf, max lag (frames)', ...
                 'factor for cluster detection'...
                };
        vals = cell(1, length(toConfirm));
        for i = 1:length(toConfirm)
            vals{i} = num2str(params.(toConfirm{i}));
        end
        
        % actual dialog
        input = inputdlg(descs, 'Parameters', 1, vals);
        
        % Update params
        for i = 1:length(toConfirm)
            params.(toConfirm{i}) = str2double(input{i});
        end
    end

    % Restructuring
    params = postProc(params);
end

% Post-process params: subsume acf related things into a struct
function params = postProc(params)
    if ischar(params.acfData)
        params.acfSpec = struct('xdim', params.acfX, 'tdim', params.acfT, 'xres', params.acfxres);
    else
        params.acfSpec = params.acfData.params.acfSpec;
        params.acfX = params.acfSpec.xdim;
        params.acfT = params.acfSpec.tdim;
        params.acfxres = params.acfSpec.xres;
%         params.acfCleanBackgroundPercentile = params.acfData.params.acfCleanBackgroundPercentile;
%         params.acfCleanNormalizationSizePx = params.acfData.params.acfCleanNormalizationSizePx;
    end
end
