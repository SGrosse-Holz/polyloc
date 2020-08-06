% Idea: in the fbn2 data, there are only few trajectories per movie and a lot
% of noise, so we want to aggregate many sets of detections into one
% structure for estimation of the acf.
%
% Note: another approach might be to just use a Rouse acf. To be explored.

files = {...
    'Dot_predictions_2020_07_10_Fbn2_C36_488nm_0p5_561nm_0p07_SC8_2X_30z_250nm_780V_300t_I20_directprocessingfiltering5p5_Sample_movie1-01_processed.csv'
    'Dot_predictions_2020_07_10_Fbn2_C36_488nm_0p5_561nm_0p07_SC8_2X_30z_250nm_780V_300t_I20_directprocessingfiltering5p5_movie1-01_processed.csv'
    'Dot_predictions_2020_07_13_Fbn2_C36_488nm_0p5_561nm_0p05_SC8_2X_30z_250nm_780V_300T_20s_prochigh_Sample_movie1-02_processed.csv'
    'Dot_predictions_2020_07_13_Fbn2_C36_488nm_0p5_561nm_0p05_SC8_2X_30z_250nm_780V_300T_20s_prochigh_Sample_movie2-03_processed.csv'
    'Dot_predictions_2020_07_14_Fbn2_C36_488nm_0p4_561nm_0p07_SC8_2X_30z_250nm_780V_300T_20s_prochigh_SAMPLE_movie1-01_processed.csv'
    'Dot_predictions_2020_07_14_Fbn2_C36_488nm_0p4_561nm_0p07_SC8_2X_30z_250nm_780V_300T_20s_prochigh_SAMPLE_movie2-01_processed.csv'
    'Dot_predictions_2020_07_17_Fbn2_C36_488nm_0p4_561nm_0p07_SC8_2X_30z_250nm_780V_300T_20s_prochigh_SAMPLE_movie1-01_processed.csv'
    'Dot_predictions_2020_07_27_Fbn2_C27_488nm_0p5_561nm_0p05_SC8_2X_30z_250nm_780V_300T_20s_prochigh_SAMPLE_movie1-02_processed.csv'
    'Dot_predictions_2020_07_27_Fbn2_C27_488nm_0p5_561nm_0p05_SC8_2X_30z_250nm_780V_300T_20s_prochigh_SAMPLE_movie2-01_processed.csv'
    'Dot_predictions_2020_07_27_Fbn2_C27_488nm_0p5_561nm_0p05_SC8_2X_30z_250nm_780V_300T_20s_prochigh_SAMPLE_movie3-01_processed.csv'
    'Dot_predictions_2020_07_28_Fbn2_C27_488nm_0p5_561nm_0p05_SC8_2X_30z_250nm_780V_300T_20s_prochigh_SAMPLE_movie1-01_processed.csv'
    'Dot_predictions_2020_07_28_Fbn2_C27_488nm_0p5_561nm_0p05_SC8_2X_30z_250nm_780V_300T_20s_prochigh_SAMPLE_movie2-02_processed.csv'
    'Dot_predictions_2020_07_28_Fbn2_C27_488nm_0p5_561nm_0p05_SC8_2X_30z_250nm_780V_300T_20s_prochigh_SAMPLE_movie3-01_processed.csv'
    'Dot_predictions_2020_07_29_Fbn2_C27_488nm_0p5_561nm_0p5_SC8_2X_30z_250nm_780V_300T_20s_prochigh_SAMPLE_movie1-02_processed.csv'
    'Dot_predictions_2020_07_29_Fbn2_C27_488nm_0p5_561nm_0p5_SC8_2X_30z_250nm_780V_300T_20s_prochigh_SAMPLE_movie2-02_processed.csv'
    'Dot_predictions_2020_07_29_Fbn2_C27_488nm_0p5_561nm_0p5_SC8_2X_30z_250nm_780V_300T_20s_prochigh_SAMPLE_movie3-01_processed.csv'
    'Dot_predictions_2020_07_30_Fbn2_C65_488nm_0p5_561nm_0p05_SC8_2X_30z_250nm_780V_300T_20s_prochigh_SMPLE_movie1-01_processed.csv'
    'Dot_predictions_2020_07_30_Fbn2_C65_488nm_0p5_561nm_0p05_SC8_2X_30z_250nm_780V_300T_20s_prochigh_SMPLE_movie2-01_processed.csv'
    'Dot_predictions_2020_07_30_Fbn2_C65_488nm_0p5_561nm_0p05_SC8_2X_30z_250nm_780V_300T_20s_prochigh_SMPLE_movie3-01_processed.csv'
    'Dot_predictions_2020_07_30_Fbn2_C65_488nm_0p5_561nm_0p05_SC8_2X_30z_250nm_780V_300T_20s_prochigh_SMPLE_movie4-02_processed.csv'
    'Dot_predictions_2020_07_30_Fbn2_C65_488nm_0p5_561nm_0p05_SC8_2X_30z_250nm_780V_300T_20s_prochigh_SMPLE_movie5-01_processed.csv'
    'Dot_predictions_2020_07_31_Fbn2_C65_488nm_0p5_561nm_0p05_SC8_2X_30z_250nm_780V_300T_20s_prochigh_SMPLE_movie1-01_processed.csv'
    'Dot_predictions_2020_07_31_Fbn2_C65_488nm_0p5_561nm_0p05_SC8_2X_30z_250nm_780V_300T_20s_prochigh_SMPLE_movie2-02_processed.csv'
    'Dot_predictions_2020_07_31_Fbn2_C65_488nm_0p5_561nm_0p05_SC8_2X_30z_250nm_780V_300T_20s_prochigh_SMPLE_movie3-01_processed.csv'
    'Dot_predictions_2020_07_31_Fbn2_C65_488nm_0p5_561nm_0p05_SC8_2X_30z_250nm_780V_300T_20s_prochigh_SMPLE_movie4-03_processed.csv'
    'Dot_predictions_2020_07_31_Fbn2_C65_488nm_0p5_561nm_0p05_SC8_2X_30z_250nm_780V_300T_20s_prochigh_SMPLE_movie5-01_processed.csv'
    'Dot_predictions_2020_08_01_Fbn2_C65_488nm_0p5_561nm_0p05_SC8_2X_30z_250nm_780V_300T_20s_prochigh_SAMPLE_movie2-01_processed.csv'
    'Dot_predictions_2020_08_01_Fbn2_C65_488nm_0p5_561nm_0p05_SC8_2X_30z_250nm_780V_300T_20s_prochigh_SAMPLE_movie3-01_processed.csv'
    'Dot_predictions_2020_08_01_Fbn2_C65_488nm_0p5_561nm_0p05_SC8_2X_30z_250nm_780V_300T_20s_prochigh_SAMPLE_movie4-01_processed.csv'
    'Dot_predictions_2020_08_02_Fbn2_C27_488nm_0p5_561nm_0p05_SC8_2X_30z_250nm_780V_300T_20s_prochigh_SAMPLE_movie1-01_processed.csv'
    'Dot_predictions_2020_08_02_Fbn2_C27_488nm_0p5_561nm_0p05_SC8_2X_30z_250nm_780V_300T_20s_prochigh_SAMPLE_movie2-01_processed.csv'
    'Dot_predictions_2020_08_02_Fbn2_C27_488nm_0p5_561nm_0p05_SC8_2X_30z_250nm_780V_300T_20s_prochigh_SAMPLE_movie3-02_processed.csv'
};

det_agg = struct('x', {}, 'y', {});

for i = 1:length(files)
    det = load_data(fullfile('D:\Dropbox (MIT)\Hugo\tracks', files{i}), 'format', 'csv_fbn');
    if ischar(det) % If user cancels file selection, load_data returns 'cancelled'
        break;
    end
    
    if length(det) > length(det_agg)
        det_agg(length(det)) = struct('x', [], 'y', []);
    end
    for fr = 1:length(det)
        det_agg(fr).x = [det_agg(fr).x; det(fr).x];
        det_agg(fr).y = [det_agg(fr).y; det(fr).y];
    end
end

% figure;
% scatter_detections(det_agg, '.');

acfData = acfDataStorage();
acfData.detections = det_agg;
acfData.params.acfSpec.xdim = 10;
acfData.params.acfSpec.xres = 1;
acfData.params.acfSpec.tdim = 20;
acfData.params.acfCleanBackgroundPercentile = 99;
acfData.params.acfCleanNormalizationSizePx = 1;
acfData.params.verbose = true;
acfData.params.checkACF = true;
app = acf_interactive(acfData);
waitfor(app);