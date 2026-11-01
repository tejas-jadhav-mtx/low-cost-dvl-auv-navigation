function M = dvl_models()
%DVL_MODELS  Sensor models compared in the same virtual water.
%   Our DVL  : numbers from the project design (notebook / paper).
%   A50      : numbers from the Water Linked DVL A50 public datasheet.
%   The A50's random (per-ping) noise is NOT published, so it is given the
%   same 1 MHz physics noise as ours. Differences therefore come only from
%   published specs: beam angle, range limits, update rate and accuracy class.
    base = struct('f0',1e6,'c',1500,'single_ping_Hz',94,'range_sigma',0.02);
    g = 3e-3;                                   % our pulse + ring-down guard (s)
    M = {};
    M{end+1} = mk(base,'Ours – 4 receivers, uncalibrated', 30, 5, 4, 1500*g/2, 37, g, 0.015);
    M{end+1} = mk(base,'Ours – 4 receivers, GPS-calibrated', 30, 5, 4, 1500*g/2, 37, g, 0.003);
    M{end+1} = mk(base,'Ours – Rs 10k (1 receiver), calibrated', 30, 5, 1, 1500*g/2, 37, g, 0.003);
    M{end+1} = mk(base,'Ours – better damping (0.5 ms ring-down), calibrated', 30, 5, 4, 1500*0.5e-3/2, 37, 0.5e-3, 0.003);
    M{end+1} = mk(base,'Water Linked A50 – Standard', 22.5, 10, 4, 0.05/cosd(22.5), 50/cosd(22.5), 0.2e-3, 0.0101);
    M{end+1} = mk(base,'Water Linked A50 – Performance', 22.5, 10, 4, 0.05/cosd(22.5), 50/cosd(22.5), 0.2e-3, 0.001);
end
function m = mk(b, name, th, rate, rx, rmin, rmax, guard, sf)
    m = b; m.name = name; m.theta = th; m.rate = rate; m.rx = rx;
    m.min_slant = rmin; m.max_slant = rmax; m.guard = guard; m.scale_err = sf;
end
