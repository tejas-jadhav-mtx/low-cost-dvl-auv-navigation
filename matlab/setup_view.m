function V = setup_view(sea, traj, cfg)
%SETUP_VIEW  Create the live window: 3-D sea on the left, plots on the right.
    V.fig = figure('Color','w','Position',[40 40 1500 820],'Name','DVL Virtual Sea','NumberTitle','off');
    force_light(V.fig);                    % MATLAB R2025+ dark theme makes the plots hard to read

    % ---------- 3-D sea ----------
    V.ax = axes('Parent',V.fig,'Position',[0.04 0.06 0.56 0.82]); hold(V.ax,'on');
    surf(V.ax, sea.X, sea.Y, -sea.D, 'EdgeColor','none', 'FaceColor','interp');
    colormap(V.ax, seabed_colormap());
    [WX, WY] = meshgrid([sea.x(1) sea.x(end)], [sea.y(1) sea.y(end)]);
    if exist('OCTAVE_VERSION','builtin')   % Octave mishandles transparency: draw the surface as an outline
        plot3(V.ax, [sea.x(1) sea.x(end) sea.x(end) sea.x(1) sea.x(1)], [sea.y(1) sea.y(1) sea.y(end) sea.y(end) sea.y(1)], zeros(1,5), '-', 'Color',[0.25 0.55 0.9], 'LineWidth',1.5);
    else                                   % MATLAB: translucent sea surface
        surf(V.ax, WX, WY, zeros(2), 'FaceColor',[0.25 0.55 0.9], 'FaceAlpha',0.15, 'EdgeColor','none');
    end
    light(V.ax,'Position',[300 -400 300]); lighting(V.ax,'gouraud'); material(V.ax,'dull');
    % small dot markers keep the tracks visible on every renderer (Octave's software OpenGL can drop plain lines)
    V.tr_true = plot3(V.ax, nan, nan, nan, 'k-',  'LineWidth',2, 'Marker','.', 'MarkerSize',6);
    V.tr_ekf  = plot3(V.ax, nan, nan, nan, '-',   'Color',[0.10 0.45 0.85], 'LineWidth',2, 'Marker','.', 'MarkerSize',6);
    V.tr_imu  = plot3(V.ax, nan, nan, nan, '--',  'Color',[0.92 0.45 0.15], 'LineWidth',1.5);
    for i = 1:4
        V.beam(i) = plot3(V.ax, nan(1,2), nan(1,2), nan(1,2), '-', 'LineWidth',2);
        V.spot(i) = plot3(V.ax, nan, nan, nan, 'o', 'MarkerSize',5, 'MarkerFaceColor','w');
    end
    [ex, ey, ez] = ellipsoid(0,0,0, 6, 1.5, 1.5, 20);       % AUV body (drawn larger than life)
    V.body0 = [ex(:) ey(:) ez(:)]'; V.bsz = size(ex);
    V.auv = surf(V.ax, ex, ey, ez, 'FaceColor',[1 0.85 0.1], 'EdgeColor','none');
    axis(V.ax, [sea.x(1) sea.x(end) sea.y(1) sea.y(end) -max(sea.D(:))-5 2]);
    daspect(V.ax, [1 1 0.5]); view(V.ax, -38, 24); grid(V.ax,'on');
    caxis(V.ax, [-max(sea.D(:)) -min(sea.D(:))]);
    xlabel(V.ax,'East (m)'); ylabel(V.ax,'North (m)'); zlabel(V.ax,'Depth (m)');
    V.title = title(V.ax, 'Starting...', 'FontSize', 11);
    legend(V.ax, [V.tr_true V.tr_ekf V.tr_imu], {'True path','DVL + IMU filter','IMU only'}, 'Location','northeast');

    % ---------- position error ----------
    V.a1 = axes('Parent',V.fig,'Position',[0.66 0.71 0.32 0.22]); hold(V.a1,'on'); grid(V.a1,'on');
    V.l_ekf = plot(V.a1, nan, nan, '-', 'Color',[0.10 0.45 0.85], 'LineWidth',1.5);
    V.l_imu = plot(V.a1, nan, nan, '--','Color',[0.92 0.45 0.15], 'LineWidth',1.5);
    set(V.a1,'YScale','log'); xlim(V.a1,[0 traj.t(end)]); ylim(V.a1,[0.01 1e4]);
    title(V.a1,'Horizontal position error'); ylabel(V.a1,'metres (log)');
    legend(V.a1,{'DVL + IMU','IMU only'},'Location','northwest');

    % ---------- fault scores ----------
    V.a2 = axes('Parent',V.fig,'Position',[0.66 0.40 0.32 0.22]); hold(V.a2,'on'); grid(V.a2,'on');
    bc = beam_colors();
    for i = 1:4, V.l_z(i) = plot(V.a2, nan, nan, '.', 'Color', bc(i,:), 'MarkerSize',6); end
    plot(V.a2, [0 traj.t(end)], cfg.k_sigma*[1 1], 'r--');
    xlim(V.a2,[0 traj.t(end)]); ylim(V.a2,[0 12]);
    title(V.a2, sprintf('Beam fault score |z| (red line = %g\\sigma threshold)', cfg.k_sigma));
    legend(V.a2, V.l_z, {'Beam 1 fwd','Beam 2 aft','Beam 3 stbd','Beam 4 port'}, 'Location','northwest','NumColumns',2);

    % ---------- beam ranges ----------
    V.a3 = axes('Parent',V.fig,'Position',[0.66 0.09 0.32 0.22]); hold(V.a3,'on'); grid(V.a3,'on');
    for i = 1:4, V.l_r(i) = plot(V.a3, nan, nan, '-', 'Color', bc(i,:)); end
    plot(V.a3, [0 traj.t(end)], cfg.max_slant*[1 1], 'k--');
    xlim(V.a3,[0 traj.t(end)]); ylim(V.a3,[0 70]);
    title(V.a3,'Beam slant range to seabed (dashed = bottom-lock limit)');
    xlabel(V.a3,'time (s)'); ylabel(V.a3,'metres');
    drawnow;
end

function force_light(f)
%FORCE_LIGHT  Use the light theme even if MATLAB is set to dark mode (R2025a+).
    try, theme(f, 'light'); catch, end    % older MATLAB and Octave: nothing to do
end
