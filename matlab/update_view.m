function update_view(V, sea, traj, k, Bt, L, e, x, cfg)
%UPDATE_VIEW  Redraw the AUV, beams, tracks and live plots for this instant.
    p = traj.p(:,k);
    % AUV body, rotated to its heading
    Rb = rot_heading(traj.yaw(k)); B = Rb*V.body0; B(1,:) = B(1,:) + p(1); B(2,:) = B(2,:) + p(2); B(3,:) = B(3,:) - p(3);
    set(V.auv, 'XData', reshape(B(1,:),V.bsz), 'YData', reshape(B(2,:),V.bsz), 'ZData', reshape(B(3,:),V.bsz));
    % Beams: green used, red rejected, grey no bottom lock
    col = {[0.6 0.6 0.6], [0.10 0.75 0.25], [0.90 0.10 0.10]};
    for i = 1:4
        R = L.range(i,e); st = L.state(i,e);
        if ~isfinite(R) || st == 0, R = min(cfg.max_slant, 60); end
        q = p + R*Bt(i,:)';
        set(V.beam(i), 'XData',[p(1) q(1)], 'YData',[p(2) q(2)], 'ZData',[-p(3) -q(3)], 'Color', col{st+1});
        if st > 0, set(V.spot(i), 'XData',q(1), 'YData',q(2), 'ZData',-q(3), 'MarkerEdgeColor', col{st+1});
        else,      set(V.spot(i), 'XData',nan, 'YData',nan, 'ZData',nan); end
    end
    % Camera follows the AUV
    if cfg.follow_camera
        axis(V.ax, [p(1)-110 p(1)+110 p(2)-80 p(2)+80 -max(sea.D(:))-5 2]);
    end
    % Tracks
    idx = 1:20:k;                                            % true path thinned to 5 Hz for drawing
    set(V.tr_true, 'XData', traj.p(1,idx), 'YData', traj.p(2,idx), 'ZData', -traj.p(3,idx));
    set(V.tr_ekf,  'XData', L.p_ekf(1,1:e), 'YData', L.p_ekf(2,1:e), 'ZData', -L.p_ekf(3,1:e));
    set(V.tr_imu,  'XData', L.p_imu(1,1:e), 'YData', L.p_imu(2,1:e), 'ZData', -L.p_imu(3,1:e));
    % Live plots
    t = L.t(1:e);
    set(V.l_ekf, 'XData', t, 'YData', max(L.err_ekf(1:e), 1e-3));
    set(V.l_imu, 'XData', t, 'YData', max(L.err_imu(1:e), 1e-3));
    for i = 1:4
        zz = abs(L.z(i,1:e)); zz(zz > 12) = 12;            % NaN (no lock) stays a gap
        rr = L.range(i,1:e);  rr(rr > 70) = 70;
        set(V.l_z(i), 'XData', t, 'YData', zz);
        set(V.l_r(i), 'XData', t, 'YData', rr);
    end
    % Status line
    alt = seabed_depth(sea, p(1), p(2)) - p(3);
    nm = {'none','used','REJECTED'}; s = '';
    for i = 1:4, s = [s sprintf('B%d:%s  ', i, nm{L.state(i,e)+1})]; end %#ok<AGROW>
    set(V.title, 'String', sprintf('t = %5.0f s   altitude %4.1f m   speed true %.2f / est %.2f m/s\nDVL error %.2f m   IMU-only error %.1f m   |   %s', ...
        traj.t(k), alt, norm(traj.v(1:2,k)), norm(x(4:5)), L.err_ekf(e), L.err_imu(e), s));
    drawnow;
end
