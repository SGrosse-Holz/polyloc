% Loading module
% Specification of the data structure: this is a 1x(number of frames) array
% of structs with fields x and y. The length of detections(t).x is the
% number of detections in this frame
%
% Input:
%   filename : string (optional)
%       if omitted, will show file selection dialog
% Parameters:
%   format : string specifying the fileformat. Supported as of now:
%       'SLIMfast' in this case filename should be the .frame file, the
%                  corresponding .ctrsX and .ctrsY files are expected
%       'artificial' used to load synthetic data for testing
%       'csv_fbn' loads csv files like the ones Hugo gave me
%       default: 'SLIMfast'
%   channel : number of the channel to use for multi-channel data formats.
%       So far this just applies to Hugo's data
%
% Output:
%   detections : array of struct, following the above specification
%
% (c) Simon Grosse-Holz, 2020

function detections = load_data(varargin)
    % The supported formats and their file extensions
    formats = struct('name', {}, 'extensions', {});
    formats(1).name = 'SLIMfast';
    formats(1).extensions = {'.frame'};
    formats(2).name = 'artificial';
    formats(2).extensions = {'.mat'};
    formats(3).name = 'csv_fbn';
    formats(3).extensions = {'.csv', '.txt'};

    % Input handling
    p = inputParser;
    p.addOptional('filename', '', @ischar);
    p.addParameter('format', formats(1).name, @(f) ismember(f, {formats(:).name}));
    p.addParameter('channel', 0);
    p.parse(varargin{:});
    params = p.Results;

    % If filename is not given, get file name and format from user
    if ismember('filename', p.UsingDefaults) || isfolder(params.filename)
        filefilters = {};
        for i = 1:length(formats)
            filterspec = '';
            for iex = 1:length(formats(i).extensions)
                filterspec = [filterspec, '*', formats(i).extensions{iex}, ';'];
            end
            filterspec = filterspec(1:(end-1));
            filefilters = [filefilters; {filterspec, formats(i).name}];
        end
        ind_def_filter = strcmp(filefilters(:, 2), params.format);
        filefilters = [filefilters(ind_def_filter, :); filefilters(~ind_def_filter, :)];
        [file, path, formatid] = uigetfile(filefilters, 'Select data (and format) to load', params.filename);
        if formatid == 0
            detections = 'cancelled';
            return;
        end
        params.filename = fullfile(path, file);
        params.format = filefilters{formatid, 2};
    else
        % We have a file name given, try to infer the format from the file
        % extension (if we didn't get it explicitly)
        if ismember('format', p.UsingDefaults)
            for i = length(formats):-1:1 % Get priorities right
                for iex = 1:length(formats(i).extensions)
                    if endsWith(params.filename, formats(i).extensions{iex})
                        params.format = formats(i).name;
                    end % if extension
                end % for extension
            end % for format
        end % if no format
    end % whether filename

    detections = feval(['load_', params.format], params.filename);
end % function load_data

function detections = load_SLIMfast(filename)
    if endsWith(filename, '.frame') || ...
       endsWith(filename, '.ctrsX') || ...
       endsWith(filename, '.ctrsY')
        filename = filename(1:(end-6));
    end
    
    varNames = {'ctrsX', 'ctrsY', 'frame'};
    data = struct();
    for value = 1:length(varNames)
        varFilename = [filename, '.', varNames{value}];
        fid = fopen(varFilename, 'r');
        if fid < 0
            fprintf(2, 'Could not read file %s\n', varFilename);
            detections = 'noread';
            return
        end
        data.(varNames{value}) = fread(fid,inf,'real*8');
        fclose(fid);
    end
    
    minframe = min(data.frame)-1;
    detections = struct('x', {}, 'y', {});
    for fr = 1:(max(data.frame)-minframe)
        detections(fr).x = data.ctrsX(data.frame == fr+minframe);
        detections(fr).y = data.ctrsY(data.frame == fr+minframe);
    end
end

function detections = load_artificial(filename)
    detections = load(filename, 'detections');
    detections = detections.detections;
end

function detections = load_csv_fbn(filename, channel)
    if nargin < 2
        channel = 0;
    end
    
    % columns: id, frame, channel, x, y, z, ...
    data = readmatrix(filename);
    
    % Similar to load_SLIMfast()
    minframe = min(data(:, 2))-1;
    detections = struct('x', {}, 'y', {});
    for fr = 1:(max(data(:, 2))-minframe)
        ind = data(:, 2) == fr+minframe & data(:, 3) == channel;
        detections(fr).x = data(ind, 4);
        detections(fr).y = data(ind, 5);
    end
end