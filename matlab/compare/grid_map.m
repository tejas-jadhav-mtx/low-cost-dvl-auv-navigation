function [Mz, cover, rmse, bias] = grid_map(sea, pts, cell, area)
%GRID_MAP  Average seabed points into cells and compare with the true bottom.
%   area = [xmin xmax ymin ymax] of the surveyed region.
    xe = area(1):cell:area(2); ye = area(3):cell:area(4);
    nx = numel(xe)-1; ny = numel(ye)-1;
    S = zeros(ny,nx); N = zeros(ny,nx);
    ix = floor((pts(1,:)-area(1))/cell) + 1; iy = floor((pts(2,:)-area(3))/cell) + 1;
    ok = ix>=1 & ix<=nx & iy>=1 & iy<=ny;
    for j = find(ok)
        S(iy(j),ix(j)) = S(iy(j),ix(j)) + pts(3,j); N(iy(j),ix(j)) = N(iy(j),ix(j)) + 1;
    end
    Mz = S./N; Mz(N==0) = NaN;
    xc = xe(1:end-1)+cell/2; yc = ye(1:end-1)+cell/2; T = zeros(ny,nx);
    for a = 1:ny, for b = 1:nx, T(a,b) = seabed_depth(sea, xc(b), yc(a)); end, end
    d = Mz - T; good = ~isnan(d);
    cover = 100*mean(good(:)); rmse = sqrt(mean(d(good).^2)); bias = mean(d(good));
end
