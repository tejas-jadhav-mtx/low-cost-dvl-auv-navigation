function R = run_nav(sea, traj, m, seed, depth_sigma)
%RUN_NAV  Fly one survey with one DVL model: IMU + DVL EKF (same filter as
%   run_dvl_sea), fault check on, and collect seabed points for mapping.
%   Ground truth = traj (true path) and sea (true bottom), both known exactly.
    dvl_rng('seed', seed);
    imu_rate = 100; dt = 1/imu_rate; K = numel(traj.t);
    n_dvl = round(imu_rate/m.rate);
    sigma_acc = 0.02; sigma_bias = 0.005; head_err = deg2rad(0.5); k_sigma = 4;
    s = sind(m.theta); co = cosd(m.theta);
    Bbody = [ s 0 co; -s 0 co; 0 s co; 0 -s co];
    I3 = eye(3); Z3 = zeros(3);
    F = [I3, I3*dt, -0.5*I3*dt^2; Z3, I3, -I3*dt; Z3, Z3, I3];
    G = [0.5*I3*dt^2; I3*dt; Z3];
    Q = G*G'*sigma_acc^2; Q(7:9,7:9) = I3*1e-8*dt;
    b_true = sigma_bias*dvl_rng('randn',3,1);
    x = [traj.p(:,1); traj.v(:,1); zeros(3,1)];
    P = diag([1e-4*[1 1 1], 0.05^2*[1 1 1], sigma_bias^2*[1 1 1]]);
    E = floor((K-1)/n_dvl);
    R.t = zeros(1,E); R.err = zeros(1,E); R.p = zeros(3,E); R.lock = zeros(4,E);
    pts = zeros(3, 4*E); np = 0;
    sig_v_all = []; e = 0;
    for k = 2:K
        a_m = traj.a(:,k-1) + b_true + sigma_acc*dvl_rng('randn',3,1);
        acc = a_m - x(7:9);
        x(1:3) = x(1:3) + x(4:6)*dt + 0.5*acc*dt^2;
        x(4:6) = x(4:6) + acc*dt;
        P = F*P*F' + Q;
        if mod(k-1, n_dvl) ~= 0, continue; end
        e = e + 1;
        yaw = traj.yaw(k);
        Bt = (rot_heading(yaw)*Bbody')';  Be = (rot_heading(yaw + head_err)*Bbody')';
        z = nan(4,1); sr = nan(4,1); av = false(4,1); rng_m = nan(4,1);
        for i = 1:4
            Rr = beam_hit(sea, traj.p(:,k), Bt(i,:)');
            if Rr >= m.min_slant && Rr <= m.max_slant
                Tp = 2*Rr/m.c + m.guard;
                n_ping = max(1, (1/m.rate)/Tp/(4/m.rx));
                sr(i) = m.c*(m.single_ping_Hz/sqrt(n_ping))/(2*m.f0);
                z(i) = (1 + m.scale_err)*(Bt(i,:)*traj.v(:,k)) + sr(i)*dvl_rng('randn');
                rng_m(i) = Rr + m.range_sigma*dvl_rng('randn');
                av(i) = true;
            end
        end
        spike = (dvl_rng('rand',4,1) < 0.01) & av;
        z(spike) = z(spike) + 0.5*sign(dvl_rng('randn',sum(spike),1));
        Pv = P(4:6,4:6); use = av;
        for i = find(av)'
            S = Be(i,:)*Pv*Be(i,:)' + sr(i)^2;
            if abs((z(i) - Be(i,:)*x(4:6))/sqrt(S)) > k_sigma, use(i) = false; end
        end
        for i = find(use)'
            H = [0 0 0, Be(i,:), 0 0 0];
            Kg = P*H'/(H*P*H' + sr(i)^2);
            x = x + Kg*(z(i) - H*x); P = P - Kg*H*P;
        end
        P = 0.5*(P+P');
        % depth from the pressure sensor keeps the vertical channel honest
        Hd = [0 0 1 0 0 0 0 0 0]; zd = traj.p(3,k) + depth_sigma*dvl_rng('randn');
        Kg = P*Hd'/(Hd*P*Hd' + depth_sigma^2); x = x + Kg*(zd - Hd*x); P = P - Kg*Hd*P;
        % seabed points for the map: where the vehicle THINKS the beam landed
        for i = find(av)'
            np = np + 1;
            hit = [x(1); x(2); zd] + rng_m(i)*Be(i,:)';
            pts(:,np) = hit;
        end
        sig_v_all = [sig_v_all; sr(av)]; %#ok<AGROW>
        R.t(e) = traj.t(k); R.p(:,e) = x(1:3);
        R.err(e) = norm(x(1:2) - traj.p(1:2,k)); R.lock(:,e) = av;
    end
    R.t = R.t(1:e); R.err = R.err(1:e); R.p = R.p(:,1:e); R.lock = R.lock(:,1:e);
    R.pts = pts(:,1:np); R.name = m.name;
    R.lock_pct = 100*mean(R.lock(:));
    R.noise = median(sig_v_all);
    R.final = R.err(end); R.maxerr = max(R.err); R.rms = sqrt(mean(R.err.^2));
end
