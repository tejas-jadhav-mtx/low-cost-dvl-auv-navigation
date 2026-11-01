%% DVL VIRTUAL SEA - live 3-D simulation of a low-cost DVL on an AUV
% Author: Tejas Jadhav, Symbiosis Skills and Professional University
%
% What you see:
%   Left : 3-D sea with a real seabed, the AUV, its 4 DVL beams hitting the
%          seabed (green = used, red = rejected by fault check,
%          grey = no bottom lock), and three tracks:
%          true path (black), DVL+IMU filter (blue), IMU only (orange).
%   Right: live plots of position error, beam fault scores and beam ranges.
%
% Everything below the CONFIGURATION block runs automatically.
% Needs only base MATLAB (no toolboxes). Also runs in GNU Octave.

clear; close all; clc;

%% ======================= CONFIGURATION =================================
cfg.seed          = 7;        % noise seed (same seed = same run, in MATLAB and Octave)
cfg.f0            = 1e6;      % DVL carrier frequency [Hz]
cfg.c             = 1500;     % sound speed used by the DVL [m/s]
cfg.theta_deg     = 30;       % Janus beam angle from vertical [deg]
cfg.dvl_rate      = 5;        % DVL updates per second [Hz]
cfg.imu_rate      = 100;      % IMU rate [Hz]
cfg.single_ping_Hz= 94;       % single-ping Doppler noise (from echo study) [Hz]
cfg.rx_channels   = 4;        % 4 = parallel receivers, 1 = one shared receiver
cfg.max_slant     = 37;       % max bottom-lock slant range at 1 MHz [m]
cfg.pulse_guard   = 3e-3;     % pulse length + guard time per ping [s]

cfg.sigma_acc     = 0.02;     % accelerometer white noise per sample [m/s^2]
cfg.sigma_bias    = 0.005;    % accelerometer bias 1-sigma per axis [m/s^2]
cfg.heading_err_deg = 0.5;    % constant AHRS heading error [deg]

cfg.auv_depth     = 18;       % AUV cruising depth [m]
cfg.auv_speed     = 1.5;      % AUV speed [m/s]

cfg.k_sigma       = 4;        % fault-check threshold [standard deviations]
cfg.hold_s        = 2;        % quarantine hold time [s]
cfg.use_fdi       = true;     % fault detection on/off

% Injected faults: [beam, start time (s), end time (s), bias (m/s)]
cfg.faults        = [3,  60, 120, 0.25;     % beam 3 biased
                     1, 560, 620, 0.15];    % beam 1 biased later
cfg.outlier_p     = 0.01;     % chance of a random spike per beam reading
cfg.outlier_mag   = 0.5;      % spike size [m/s]

cfg.animate       = true;     % false = run fast, show only final results
cfg.frame_every   = 2;        % redraw every N DVL updates
cfg.follow_camera = true;     % 3-D view follows the AUV (false = whole area)
cfg.record_video  = false;    % true = save DVL_Virtual_Sea.mp4 (MATLAB only)
%% =======================================================================

dvl_rng('seed', cfg.seed);   % portable generator: identical numbers in MATLAB and Octave
fprintf('Building seabed and trajectory...\n');
sea  = make_seabed();
traj = make_trajectory(cfg);

% Beam directions in the vehicle frame (x forward, y starboard, z down)
s = sind(cfg.theta_deg); co = cosd(cfg.theta_deg);
Bbody = [ s 0 co; -s 0 co; 0 s co; 0 -s co];

%% ---------------- Navigation filter set-up (9 states) ------------------
dt  = 1/cfg.imu_rate;  K = numel(traj.t);  n_dvl = round(cfg.imu_rate/cfg.dvl_rate);
I3  = eye(3);  Z3 = zeros(3);
F   = [I3, I3*dt, -0.5*I3*dt^2; Z3, I3, -I3*dt; Z3, Z3, I3];
G   = [0.5*I3*dt^2; I3*dt; Z3];
Q   = G*G'*cfg.sigma_acc^2;  Q(7:9,7:9) = I3*1e-8*dt;
b_true = cfg.sigma_bias*dvl_rng('randn',3,1);
x   = [traj.p(:,1) + 0.01*dvl_rng('randn',3,1); traj.v(:,1) + 0.05*dvl_rng('randn',3,1); zeros(3,1)];
P   = diag([1e-4*[1 1 1], 0.05^2*[1 1 1], cfg.sigma_bias^2*[1 1 1]]);
p_imu = x(1:3); v_imu = x(4:6);                    % IMU-only dead reckoning
hold_n = round(cfg.hold_s*cfg.dvl_rate);
quar = zeros(4,1); hist = zeros(4,3);              % quarantine state

% Logs (one entry per DVL update)
E = floor((K-1)/n_dvl);
L.t = zeros(1,E); L.err_ekf = L.t; L.err_imu = L.t;
L.z = nan(4,E); L.range = nan(4,E); L.state = zeros(4,E); L.sig = nan(4,E);
L.faulty = false(4,E);
L.p_ekf = nan(3,E); L.p_imu = nan(3,E);

%% ---------------- Figure ------------------------------------------------
if cfg.animate
    V = setup_view(sea, traj, cfg);
    if cfg.record_video && exist('VideoWriter','class')
        vw = VideoWriter('DVL_Virtual_Sea.mp4','MPEG-4'); vw.FrameRate = 15; open(vw);
    else
        vw = [];
    end
end

%% ---------------- Main loop ---------------------------------------------
fprintf('Running %d s mission...\n', round(traj.t(end)));
e = 0;
for k = 2:K
    % --- IMU reading and prediction ---
    a_m = traj.a(:,k-1) + b_true + cfg.sigma_acc*dvl_rng('randn',3,1);
    acc = a_m - x(7:9);
    x(1:3) = x(1:3) + x(4:6)*dt + 0.5*acc*dt^2;
    x(4:6) = x(4:6) + acc*dt;
    P = F*P*F' + Q;
    p_imu = p_imu + v_imu*dt + 0.5*a_m*dt^2;  v_imu = v_imu + a_m*dt;

    if mod(k-1, n_dvl) ~= 0, continue; end
    e = e + 1;  tk = traj.t(k);

    % --- DVL measurement from the virtual sea ---
    yaw  = traj.yaw(k);
    Rt   = rot_heading(yaw);                                % true attitude
    Re   = rot_heading(yaw + deg2rad(cfg.heading_err_deg)); % what the AHRS reports
    Bt = (Rt*Bbody')';   Be = (Re*Bbody')';           % beam directions (nav frame)
    z_meas = nan(4,1); sig_r = nan(4,1); avail = false(4,1); faulty = false(4,1);
    for i = 1:4
        R = beam_hit(sea, traj.p(:,k), Bt(i,:)');
        L.range(i,e) = R;
        if R <= cfg.max_slant
            Tp = 2*R/cfg.c + cfg.pulse_guard;
            n_ping = max(1, (1/cfg.dvl_rate)/Tp/(4/cfg.rx_channels));
            sig_f  = cfg.single_ping_Hz/sqrt(n_ping);
            sig_r(i) = cfg.c*sig_f/(2*cfg.f0);
            z_meas(i) = Bt(i,:)*traj.v(:,k) + sig_r(i)*dvl_rng('randn');
            avail(i) = true;
        end
    end
    for f = 1:size(cfg.faults,1)
        b = cfg.faults(f,1);
        if tk >= cfg.faults(f,2) && tk < cfg.faults(f,3) && avail(b)
            z_meas(b) = z_meas(b) + cfg.faults(f,4); faulty(b) = true;
        end
    end
    spike = (dvl_rng('rand',4,1) < cfg.outlier_p) & avail;
    z_meas(spike) = z_meas(spike) + cfg.outlier_mag*sign(dvl_rng('randn',sum(spike),1));
    faulty = faulty | spike;

    % --- Fault check: normalised residual with the full innovation covariance ---
    Pv = P(4:6,4:6);  zsc = nan(4,1);
    for i = find(avail)'
        S = Be(i,:)*Pv*Be(i,:)' + sig_r(i)^2;
        zsc(i) = (z_meas(i) - Be(i,:)*x(4:6))/sqrt(S);
    end
    flag = false(4,1);
    if cfg.use_fdi, flag = avail & abs(zsc) > cfg.k_sigma; end
    excl = flag | (avail & quar > 0);
    hist = [flag, hist(:,1:2)];
    persistent_fault = flag & (sum(hist,2) >= 2);
    quar(persistent_fault) = hold_n;
    dec = ~flag & ~persistent_fault;  quar(dec) = max(quar(dec)-1, 0);
    use = avail & ~excl;

    % --- Sequential beam updates ---
    for i = find(use)'
        H = [0 0 0, Be(i,:), 0 0 0];
        Sv = H*P*H' + sig_r(i)^2;
        Kg = P*H'/Sv;
        x = x + Kg*(z_meas(i) - H*x);
        P = P - Kg*H*P;
    end
    P = 0.5*(P+P');

    % --- Logs ---
    L.t(e) = tk;
    L.err_ekf(e) = norm(x(1:2) - traj.p(1:2,k));
    L.err_imu(e) = norm(p_imu(1:2) - traj.p(1:2,k));
    L.z(:,e) = zsc;  L.sig(:,e) = sig_r;  L.faulty(:,e) = faulty;
    L.state(:,e) = avail + excl;      % 0 no lock, 1 used, 2 rejected
    L.p_ekf(:,e) = x(1:3);  L.p_imu(:,e) = p_imu;

    if cfg.animate && mod(e, cfg.frame_every) == 0
        update_view(V, sea, traj, k, Bt, L, e, x, cfg);
        if ~isempty(vw), writeVideo(vw, getframe(V.fig)); end
    end
end
if cfg.animate && ~isempty(vw), close(vw); end

%% ---------------- Results -----------------------------------------------
L.t = L.t(1:e); fn = {'err_ekf','err_imu'}; for j = 1:2, L.(fn{j}) = L.(fn{j})(1:e); end
used   = L.state == 1;  rejected = L.state == 2;  locked = L.state > 0;
fa  = sum(rejected(:) & ~L.faulty(:)) / max(1, sum(locked(:) & ~L.faulty(:)));
det = sum(rejected(:) &  L.faulty(:)) / max(1, sum(locked(:) &  L.faulty(:)));
dist = sum(sqrt(sum(diff(traj.p(1:2,:),1,2).^2,1)));

fprintf('\n================ MISSION SUMMARY ================\n');
fprintf('Mission time                 : %.0f s, distance %.0f m\n', traj.t(end), dist);
fprintf('Receiver channels            : %d\n', cfg.rx_channels);
fprintf('Typical beam noise           : %.3f m/s\n', median(L.sig(~isnan(L.sig))));
fprintf('Final horizontal error, DVL  : %.2f m (%.2f%% of distance)\n', L.err_ekf(end), 100*L.err_ekf(end)/dist);
fprintf('Final horizontal error, IMU  : %.1f m\n', L.err_imu(end));
fprintf('Beam readings with no lock   : %.1f %%\n', 100*mean(~locked(:)));
fprintf('Faulty readings caught       : %.1f %%\n', 100*det);
fprintf('Healthy readings rejected    : %.2f %%\n', 100*fa);
fprintf('=================================================\n');

show_summary(sea, traj, L, cfg, dist);
