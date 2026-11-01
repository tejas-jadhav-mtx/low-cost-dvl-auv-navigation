function traj = make_survey(x0, x1, ys, v, depth, imu_rate)
%MAKE_SURVEY  Lawnmower survey: straight legs at the y values in ys,
%   joined by half-circle turns (radius = half the line spacing).
%   Truth is re-integrated from acceleration (same scheme the INS uses).
    dt = 1/imu_rate; r = (ys(2)-ys(1))/2; ds = 0.02;
    pts = [];
    for leg = 1:numel(ys)
        y = ys(leg);
        if mod(leg,2) == 1, xs = x0:ds:x1; else, xs = x1:-ds:x0; end
        pts = [pts, [xs; y*ones(size(xs))]]; %#ok<AGROW>
        if leg < numel(ys)
            if mod(leg,2) == 1, cx = x1; sgn = 1; else, cx = x0; sgn = -1; end
            ang = linspace(-pi/2, pi/2, max(20, round(pi*r/ds)));
            pts = [pts, [cx + sgn*r*cos(ang); y + r + r*sin(ang)]]; %#ok<AGROW>
        end
    end
    seg = sqrt(sum(diff(pts,1,2).^2,1)); keep = [true, seg > 1e-9];
    pts = pts(:,keep); seg = seg(seg > 1e-9); s = [0, cumsum(seg)];
    t = 0:dt:s(end)/v; sq = min(v*t, s(end));
    px = interp1(s, pts(1,:), sq); py = interp1(s, pts(2,:), sq);
    yaw = unwrap(atan2(gradient(py), gradient(px)));
    vx = gradient(px, dt); vy = gradient(py, dt);
    ax = gradient(vx, dt); ay = gradient(vy, dt);
    k = ones(1,25)/25; ax = conv(ax, k, 'same'); ay = conv(ay, k, 'same');
    a = [ax; ay; zeros(size(ax))];
    p = zeros(3, numel(t)); vv = zeros(3, numel(t));
    p(:,1) = [px(1); py(1); depth]; vv(:,1) = [vx(1); vy(1); 0];
    for n = 1:numel(t)-1
        p(:,n+1) = p(:,n) + vv(:,n)*dt + 0.5*a(:,n)*dt^2;
        vv(:,n+1) = vv(:,n) + a(:,n)*dt;
    end
    traj.t = t; traj.p = p; traj.v = vv; traj.a = a; traj.yaw = yaw;
end
