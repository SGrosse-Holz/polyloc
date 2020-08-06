% Assuming a zero mean Gaussian process, the acf we need for linking is
% given by Gaussians at each time with variance equal to the corresponding
% MSD. This is straight-forward to generate manually.

function acfData = synthetic_acfData(varargin)
    p = inputParser;
    p.addOptional('Gamma', 1);
    p.addOptional('alpha', 0.5);
    p.addOptional('MSD', []);
    p.addOptional('xdim', 10);
    p.addOptional('tdim', 20);
    p.addOptional('xres', 1);
    
    p.parse(varargin{:});
    params = p.Results;
    
    if isempty(params.MSD) % MSD not given or invalid
        params.MSD = params.Gamma * (1:params.tdim).^params.alpha;
    else
        params.tdim = length(params.MSD);
    end
    
    xvec = 0 : params.xres : params.xdim;
    xvec = [flip(xvec), xvec(2:end)];
    halfacf = zeros(length(xvec), length(xvec), params.tdim);
    [x, y] = meshgrid(xvec);
    tmp = x; % array of correct shape for transfer of data
    for i = 1:length(params.MSD)
        tmp(:) = mvnpdf([x(:), y(:)], [0, 0], params.MSD(i).*eye(2));
        halfacf(:, :, i) = tmp;
    end
    
    acf = zeros(length(xvec), length(xvec), 2*params.tdim + 1);
    acf(:, :, (params.tdim+2):end) = halfacf;
    acf(:, :, 1:params.tdim) = halfacf(:, :, params.tdim:-1:1);
    acf = clean_acf(acf, 'NormalizationSize', 1/params.xres);
    
    acfData = acfDataStorage();
    acfData.acf = acf;
    acfData.params.acfSpec.xdim = params.xdim;
    acfData.params.acfSpec.xres = params.xres;
    acfData.params.acfSpec.tdim = params.tdim;
end
    