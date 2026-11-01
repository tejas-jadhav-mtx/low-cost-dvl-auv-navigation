function plot_pond_detail(sea, traj, RR, c, area)
%PLOT_POND_DETAIL  3-D view of mapped vs true pond bottom, and where the map is wrong.
    f = figure('Color','w','Position',[60 60 1500 820],'Name','Pond detail');
    try, theme(f,'light'); catch, end
    xe = area(1):c.cell:area(2); ye = area(3):c.cell:area(4);
    xc = xe(1:end-1)+c.cell/2; yc = ye(1:end-1)+c.cell/2; [XC,YC] = meshgrid(xc,yc);
    T = zeros(size(XC)); for a = 1:numel(XC), T(a) = seabed_depth(sea, XC(a), YC(a)); end
    cm = flipud(seabed_colormap()); lo = min(sea.D(:)); hi = max(sea.D(:));
    pick = [2 4 6];   % ours calibrated, ours better damping, A50 performance
    % row 1: 3-D surfaces
    ax = subplot(2,4,1); surf(ax, XC, YC, -T, 'EdgeColor','none'); hold(ax,'on');
    plot3(ax, traj.p(1,1:50:end), traj.p(2,1:50:end), -traj.p(3,1:50:end), 'k-');
    colormap(ax, cm); caxis(ax,[-hi -lo]); view(ax,-35,35); zlim(ax,[-hi-0.5 0.5]);
    title(ax,'GROUND TRUTH bottom'); xlabel(ax,'E (m)'); ylabel(ax,'N (m)'); zlabel(ax,'depth (m)');
    for q = 1:3
        R = RR(pick(q));
        ax = subplot(2,4,1+q); surf(ax, XC, YC, -R.Mz, 'EdgeColor','none');
        colormap(ax, cm); caxis(ax,[-hi -lo]); view(ax,-35,35); zlim(ax,[-hi-0.5 0.5]);
        title(ax, sprintf('%s\n%.0f%% mapped', short(R.name), R.cover), 'FontSize', 9);
        xlabel(ax,'E (m)'); ylabel(ax,'N (m)');
    end
    % row 2: error maps (mapped minus true)
    ecm = [linspace(0.15,1,32)', linspace(0.35,1,32)', ones(32,1); ones(32,1), linspace(1,0.3,32)', linspace(1,0.2,32)'];
    ax = subplot(2,4,5); axis(ax,'off');
    text(ax, 0, 0.95, {'Error maps (bottom row):', '', 'colour = mapped depth minus', 'true depth', '', 'blue = map too shallow', 'red  = map too deep', 'white = correct', 'grey = not mapped', '', 'Shallow edges are grey for', 'our current DVL: under ~2 m', 'of water it cannot hear the', 'echo (3 ms ring-down).'}, ...
        'VerticalAlignment','top','FontSize',9);
    for q = 1:3
        R = RR(pick(q)); Dm = R.Mz - T;
        ax = subplot(2,4,5+q);
        img = Dm; img(isnan(img)) = 0;
        imagesc(ax, xc, yc, img); set(ax,'YDir','normal'); hold(ax,'on');
        [ny,nx] = size(Dm); [I,J] = find(isnan(Dm));
        if ~isempty(I)
            plot(ax, xc(J), yc(I), 's', 'MarkerSize', 6, 'MarkerFaceColor',[0.75 0.75 0.75], 'MarkerEdgeColor','none');
        end
        colormap(ax, ecm); caxis(ax,[-0.5 0.5]); cb = colorbar(ax); ylabel(cb,'error (m)');
        axis(ax,'equal'); axis(ax,[area(1) area(2) area(3) area(4)]);
        title(ax, sprintf('%s\nRMS error %.2f m', short(R.name), R.rmse), 'FontSize', 9);
        xlabel(ax,'East (m)');
    end
    drawnow;
    try, print(f, 'pond_detail.png', '-dpng', '-r90'); catch, end
end
function s = short(n)
    s = strrep(n, ', calibrated', ''); s = strrep(s, ' (0.5 ms ring-down)', ' 0.5 ms');
end
