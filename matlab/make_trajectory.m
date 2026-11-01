function traj = make_trajectory(cfg)
%MAKE_TRAJECTORY  Lawnmower survey at constant depth: three 300 m legs
%   joined by 30 m-radius turns. Truth velocity and acceleration are
%   derived from the path, and the truth is re-integrated from the
%   acceleration with the same scheme the IMU uses, so all navigation
%   error comes from sensor error.
    dt = 1/cfg.imu_rate;  v = cfg.auv_speed;  r = 30;
    x0 = 150; x1 = 450; ys = [100 160 220];
    % Build the path as a dense list of points
    pts = []; hd = [];
    for leg = 1:3
        y = ys(leg);
        if mod(leg,2) == 1, xs = x0:0.05:x1; h = 0; else, xs = x1:-0.05:x0; h = pi; end
        pts = [pts, [xs; y*ones(size(xs))]]; hd = [hd, h*ones(size(xs))]; %#ok<AGROW>
        if leg < 3
            if mod(leg,2) == 1, cx = x1; sgn = 1; else, cx = x0; sgn = -1; end
            ang = linspace(-pi/2, pi/2, round(pi*r/0.05));
            px = cx + sgn*r*cos(ang); py = y + r + r*sin(ang);
            pts = [pts, [px; py]]; hd = [hd, mod(h + (ang + pi/2), 2*pi)]; %#ok<AGROW>
        end
    end
    seg = sqrt(sum(diff(pts,1,2).^2,1));
    keep = [true, seg > 1e-9];                           % drop repeated points where legs meet turns
    pts = pts(:,keep); seg = seg(seg > 1e-9);            % (MATLAB's interp1 needs unique samples)
    s = [0, cumsum(seg)];
    t = 0:dt:s(end)/v;
    sq = min(v*t, s(end));                               % guard against round-off past the end
    px = interp1(s, pts(1,:), sq); py = interp1(s, pts(2,:), sq);
    yaw = unwrap(atan2(gradient(py), gradient(px)));
    vx = gradient(px, dt); vy = gradient(py, dt);
    ax = gradient(vx, dt); ay = gradient(vy, dt);
    ax = movavg(ax, 25); ay = movavg(ay, 25);           % remove numeric jitter
    a = [ax; ay; zeros(size(ax))];
    % Re-integrate truth from acceleration (same discrete model as the INS)
    p = zeros(3, numel(t)); vv = zeros(3, numel(t));
    p(:,1) = [px(1); py(1); cfg.auv_depth]; vv(:,1) = [vx(1); vy(1); 0];
    for k = 1:numel(t)-1
        p(:,k+1)  = p(:,k) + vv(:,k)*dt + 0.5*a(:,k)*dt^2;
        vv(:,k+1) = vv(:,k) + a(:,k)*dt;
    end
    traj.t = t; traj.p = p; traj.v = vv; traj.a = a; traj.yaw = yaw;
end

function y = movavg(x, n)
    k = ones(1,n)/n; y = conv(x, k, 'same');
end
