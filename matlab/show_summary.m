function show_summary(sea, traj, L, cfg, dist)
%SHOW_SUMMARY  Final results window: map of tracks, errors, beam usage.
    f = figure('Color','w','Position',[80 80 1400 700],'Name','DVL mission summary','NumberTitle','off');
    try, theme(f, 'light'); catch, end    % ignore MATLAB R2025+ dark mode
    e = numel(L.t);

    a = axes('Parent',f,'Position',[0.05 0.22 0.26 0.68]); hold(a,'on');   % large top-view map
    contourf(a, sea.X, sea.Y, -sea.D, 20, 'LineColor','none'); colormap(a, seabed_colormap());
    cb = colorbar(a); ylabel(cb, 'Seabed height (m)');
    plot(a, traj.p(1,:), traj.p(2,:), 'k-', 'LineWidth',2);
    plot(a, L.p_ekf(1,1:e), L.p_ekf(2,1:e), '-', 'Color',[0.10 0.45 0.85], 'LineWidth',2);
    plot(a, L.p_imu(1,1:e), L.p_imu(2,1:e), '--', 'Color',[0.92 0.45 0.15], 'LineWidth',1.5);
    axis(a,'equal'); axis(a,[sea.x(1) sea.x(end) sea.y(1) sea.y(end)]);
    title(a,'Top view: true path vs estimates'); xlabel(a,'East (m)'); ylabel(a,'North (m)');
    legend(a,{'Seabed','True','DVL + IMU','IMU only'},'Location','southoutside','Orientation','horizontal');

    b = subplot(2,3,2); semilogy(b, L.t, max(L.err_ekf,1e-3), 'Color',[0.10 0.45 0.85], 'LineWidth',1.5); hold(b,'on');
    semilogy(b, L.t, max(L.err_imu,1e-3), '--', 'Color',[0.92 0.45 0.15], 'LineWidth',1.5); grid(b,'on');
    title(b, sprintf('Horizontal error: DVL %.2f m vs IMU %.0f m at end', L.err_ekf(end), L.err_imu(end)));
    xlabel(b,'time (s)'); ylabel(b,'metres (log)'); legend(b,{'DVL + IMU','IMU only'},'Location','northwest');
    shade_faults(b, cfg);

    c = subplot(2,3,3); hold(c,'on'); grid(c,'on'); bc = beam_colors();
    for i = 1:4, zz = abs(L.z(i,1:e)); zz(zz > 12) = 12; plot(c, L.t, zz, '.', 'Color', bc(i,:), 'MarkerSize',5); end
    plot(c, [0 L.t(end)], cfg.k_sigma*[1 1], 'r--'); ylim(c,[0 12]);
    title(c,'Beam fault scores |z|'); xlabel(c,'time (s)'); shade_faults(c, cfg);
    legend(c,{'B1','B2','B3','B4'},'Location','northwest','NumColumns',4);

    d = subplot(2,3,5); st = L.state(:,1:e);
    imagesc(d, L.t, 1:4, st); colormap(d, [0.75 0.75 0.75; 0.10 0.75 0.25; 0.90 0.10 0.10]); caxis(d,[0 2]);
    set(d,'YTick',1:4,'YTickLabel',{'B1 fwd','B2 aft','B3 stbd','B4 port'});
    title(d,'Beam status: grey no lock, green used, red rejected'); xlabel(d,'time (s)');

    g = subplot(2,3,6); axis(g,'off');
    txt = {sprintf('Distance travelled: %.0f m in %.0f s', dist, traj.t(end)), ...
           sprintf('Receiver channels: %d', cfg.rx_channels), ...
           sprintf('Median beam noise: %.3f m/s', median(L.sig(~isnan(L.sig)))), ...
           sprintf('Final error, DVL + IMU: %.2f m (%.2f%% of distance)', L.err_ekf(end), 100*L.err_ekf(end)/dist), ...
           sprintf('Final error, IMU only: %.0f m', L.err_imu(end)), ...
           sprintf('Heading error assumed: %.1f deg', cfg.heading_err_deg), ...
           sprintf('Random spikes: %.0f%% of readings, %.1f m/s', 100*cfg.outlier_p, cfg.outlier_mag)};
    for f = 1:size(cfg.faults,1)
        txt{end+1} = sprintf('Injected fault %d: beam %d, %+.2f m/s, %g-%g s', f, cfg.faults(f,1), cfg.faults(f,4), cfg.faults(f,2), cfg.faults(f,3)); %#ok<AGROW>
    end
    text(g, 0, 0.9, txt, 'VerticalAlignment','top', 'FontSize',11);
    title(g,'Mission summary');
    drawnow;
end

function shade_faults(ax, cfg)
    yl = ylim(ax);
    for f = 1:size(cfg.faults,1)
        patch(ax, [cfg.faults(f,2) cfg.faults(f,3) cfg.faults(f,3) cfg.faults(f,2)], [yl(1) yl(1) yl(2) yl(2)], ...
              [1 0.85 0.85], 'EdgeColor','none', 'FaceAlpha',0.4, 'HandleVisibility','off');
    end
    ylim(ax, yl);
end
