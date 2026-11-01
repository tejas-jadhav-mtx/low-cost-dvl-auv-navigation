%% COMPARE_POND - pond-only test: our DVL vs Water Linked A50 (simulation)
% Pond: 80 m x 50 m, 0.9-6 m deep. Vehicle (small ROV / boat) 0.3 m below
% the surface, 1 m/s, lawnmower lines 4 m apart. Same pond, same path, same
% IMU and compass for every DVL - only the DVL changes.
% GROUND TRUTH = the true path and true pond bottom made by the simulator.
% Runs in about 1-3 minutes. Run from the 'compare' folder.
clear; close all; clc;
addpath('..');
models = dvl_models();
c = struct('kind','pond','x0',8,'x1',72,'ys',6:4:42,'v',1.0,'depth',0.3,'cell',2);
sea  = make_waterbody('pond');
traj = make_survey(c.x0, c.x1, c.ys, c.v, c.depth, 100);
dist = sum(sqrt(sum(diff(traj.p(1:2,:),1,2).^2,1)));
area = [c.x0-4 c.x1+4 c.ys(1)-4 c.ys(end)+4];

% How deep must the water be for each DVL? (minimum slant range -> minimum depth)
fprintf('Minimum water depth needed under the vehicle (vehicle at %.1f m):\n', c.depth);
for j = 1:numel(models)
    m = models{j}; hmin = m.min_slant*cosd(m.theta);
    fprintf('  %-55s %.2f m above bottom  ->  water deeper than %.2f m\n', m.name, hmin, hmin + c.depth);
end
fprintf('Pond bottom here: %.1f-%.1f m. Pond area shallower than 2.3 m: %.0f%%\n\n', ...
    min(sea.D(:)), max(sea.D(:)), 100*mean(sea.D(:) < 2.3));

fprintf('%-55s %6s %7s %7s %7s %7s %8s\n','DVL','lock%','final','max','rms','cover%','mapRMSE');
for j = 1:numel(models)
    Rj = run_nav(sea, traj, models{j}, 7, 0.02);
    [Mz, cov, rmse, bias] = grid_map(sea, Rj.pts, c.cell, area);
    Rj.Mz = Mz; Rj.cover = cov; Rj.rmse = rmse; Rj.bias = bias; RR(j) = Rj; %#ok<SAGROW>
    fprintf('%-55s %6.1f %7.2f %7.2f %7.2f %7.1f %8.3f\n', Rj.name, Rj.lock_pct, Rj.final, Rj.maxerr, Rj.rms, cov, rmse);
end
plot_comparison(sea, traj, RR, c, area, dist);     % same 6-panel figure as before
plot_pond_detail(sea, traj, RR, c, area);          % 3-D maps + error maps
fprintf('\nSaved compare_pond.png and pond_detail.png\n');
