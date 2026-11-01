%% COMPARE_POND_LAKE - our low-cost DVL vs a Water Linked A50 model
% Same water, same survey path, same IMU and heading sensor for every DVL.
% Only the DVL model changes, so differences come from the DVL alone.
% GROUND TRUTH: the true path (traj) and true bottom (sea) are known exactly
% because the simulator creates them - every estimate is scored against them.
% Run from this folder (it uses helper files from the parent folder).
clear; close all; clc;
addpath('..');
models = dvl_models();
S(1) = struct('kind','pond','x0',8,'x1',72,'ys',6:4:42,'v',1.0,'depth',0.3,'cell',2);
S(2) = struct('kind','lake','x0',30,'x1',270,'ys',20:20:180,'v',1.5,'depth',3,'cell',10);
fid = fopen('comparison_results.csv','w');
fprintf(fid,'scenario,dvl,bottom_lock_pct,beam_noise_mps,final_err_m,max_err_m,rms_err_m,map_cover_pct,map_rmse_m,map_bias_m\n');
for sc = 1:numel(S)
    c = S(sc); sea = make_waterbody(c.kind);
    traj = make_survey(c.x0, c.x1, c.ys, c.v, c.depth, 100);
    dist = sum(sqrt(sum(diff(traj.p(1:2,:),1,2).^2,1)));
    area = [c.x0-4 c.x1+4 c.ys(1)-4 c.ys(end)+4];
    fprintf('\n=== %s: %.0f m survey, %.0f s, vehicle at %.1f m depth, bottom %.1f-%.1f m ===\n', ...
        upper(c.kind), dist, traj.t(end), c.depth, min(sea.D(:)), max(sea.D(:)));
    fprintf('%-42s %6s %7s %8s %8s %8s %7s %8s\n','DVL','lock%','noise','final','max','rms','cover%','mapRMSE');
    clear RR
    for j = 1:numel(models)
        Rj = run_nav(sea, traj, models{j}, 7, 0.02);
        [Mz, cov, rmse, bias] = grid_map(sea, Rj.pts, c.cell, area);
        Rj.Mz = Mz; Rj.cover = cov; Rj.rmse = rmse; Rj.bias = bias; RR(j) = Rj; %#ok<SAGROW>
        fprintf('%-42s %6.1f %7.3f %8.2f %8.2f %8.2f %7.1f %8.3f\n', Rj.name, Rj.lock_pct, Rj.noise, Rj.final, Rj.maxerr, Rj.rms, cov, rmse);
        fprintf(fid,'%s,%s,%.1f,%.4f,%.2f,%.2f,%.2f,%.1f,%.3f,%.3f\n', c.kind, Rj.name, Rj.lock_pct, Rj.noise, Rj.final, Rj.maxerr, Rj.rms, cov, rmse, bias);
    end
    save(['results_' c.kind '.mat'], 'RR', 'c', 'area', 'dist');
    plot_comparison(sea, traj, RR, c, area, dist);
end
fclose(fid);
fprintf('\nSaved comparison_results.csv and the figures compare_pond.png / compare_lake.png\n');
