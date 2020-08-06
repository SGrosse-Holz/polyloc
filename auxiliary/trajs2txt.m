function trajs2txt(trajs, file)
    fid = fopen(file, 'w');
    for itraj = 1:length(trajs)
        for ii = 1:length(trajs(itraj).t)
            fprintf(fid, "%f\t%f\t%d\t%d\n", trajs(itraj).x(ii), trajs(itraj).y(ii), trajs(itraj).t(ii), itraj);
        end
    end
    fclose(fid);