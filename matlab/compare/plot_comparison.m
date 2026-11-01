function plot_comparison(sea, traj, RR, c, area, dist)
%PLOT_COMPARISON  One results figure per water body.
    f = figure('Color','w','Position',[40 40 1500 860],'Name',['DVL comparison - ' c.kind]);
    try, theme(f,'light'); catch, end
    cm = seabed_colormap(); cmap = [1 1 1; flipud(cm)];
    lo = min(sea.D(:)); hi = max(sea.D(:)); sent = lo - (hi-lo)/size(cm,1)*1.5;
    xe = area(1):c.cell:area(2); ye = area(3):c.cell:area(4);
    xc = xe(1:end-1)+c.cell/2; yc = ye(1:end-1)+c.cell/2;
    % 1 truth
    a = subplot(2,3,1); imagesc(a, sea.x, sea.y, sea.D); set(a,'YDir','normal'); hold(a,'on');
    plot(a, traj.p(1,1:50:end), traj.p(2,1:50:end), 'k-', 'LineWidth', 1);
    colormap(a, flipud(cm)); caxis(a,[lo hi]); cb = colorbar(a); ylabel(cb,'depth (m)');
    axis(a,'equal'); axis(a,[sea.x(1) sea.x(end) sea.y(1) sea.y(end)]);
    title(a,'GROUND TRUTH: bottom + path'); xlabel(a,'East (m)'); ylabel(a,'North (m)');
    % 2-3 maps: ours calibrated (4 rx) and A50 performance
    pick = [2 6];
    for q = 1:2
        R = RR(pick(q)); M = R.Mz; M(isnan(M)) = sent;
        b = subplot(2,3,1+q); imagesc(b, xc, yc, M); set(b,'YDir','normal');
        colormap(b, cmap); caxis(b,[sent hi]); colorbar(b);
        axis(b,'equal'); axis(b,[sea.x(1) sea.x(end) sea.y(1) sea.y(end)]);
        title(b, sprintf('%s\nmap error %.2f m RMS, %.0f%% of cells mapped', R.name, R.rmse, R.cover),'FontSize',9);
        xlabel(b,'East (m)');
    end
    % 4 error vs time
    d = subplot(2,3,4); hold(d,'on'); grid(d,'on');
    col = [0.10 0.45 0.85; 0.00 0.60 0.30; 0.55 0.30 0.75; 0.45 0.45 0.45; 0.90 0.45 0.10; 0.80 0.10 0.10];
    sty = {'-','-','-','-','--','--'};
    for j = 1:numel(RR), plot(d, RR(j).t, RR(j).err, sty{j}, 'Color', col(j,:), 'LineWidth', 1.4); end
    title(d,'Horizontal position error vs ground truth'); xlabel(d,'time (s)'); ylabel(d,'metres');
    legend(d, {RR.name}, 'Location','northwest','FontSize',7);
    % 5 bars
    e = subplot(2,3,5);
    bar(e, [RR.lock_pct]); set(e,'XTickLabel',{'O-unc','O-cal','O-10k','O-damp','A50S','A50P'}); ylim(e,[0 105]); grid(e,'on');
    title(e,'Beam readings with bottom lock (%)'); 
    % 6 table
    g = subplot(2,3,6); axis(g,'off');
    txt = {sprintf('%s: %.0f m survey at %.1f m/s, vehicle %.1f m deep', upper(c.kind), dist, c.v, c.depth), ...
           sprintf('bottom %.1f-%.1f m deep', min(sea.D(:)), max(sea.D(:))), ''};
    for j = 1:numel(RR)
        txt{end+1} = sprintf('%s', RR(j).name); %#ok<AGROW>
        txt{end+1} = sprintf('    lock %.0f%%, final %.2f m, max %.2f m, map %.2f m RMS', RR(j).lock_pct, RR(j).final, RR(j).maxerr, RR(j).rmse); %#ok<AGROW>
    end
    text(g, 0, 1, txt, 'VerticalAlignment','top', 'FontSize', 8);
    title(g,'Results (all scored against ground truth)');
    drawnow;
    try, print(f, ['compare_' c.kind '.png'], '-dpng', '-r90'); catch, end
end
