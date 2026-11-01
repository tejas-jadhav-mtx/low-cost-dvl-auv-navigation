# DVL Virtual Sea (MATLAB / Octave)

A 3-D virtual sea where an AUV flies a survey over a seabed. A 4-beam DVL pings the
seabed and an IMU + DVL navigation filter estimates the AUV's position. Faults are
injected into the beams and the fault checker has to catch them. You watch it all live.

Author: Tejas Jadhav. Needs base MATLAB only (R2018b or newer, no toolboxes) or GNU Octave 6+.

## How to run
1. Unzip the folder and open it in MATLAB (set it as the Current Folder).
2. Type `run_dvl_sea` and press Enter.
3. A live window opens and the mission plays (about 1–3 minutes). When it ends, a
   summary window opens and the results are printed in the Command Window.

## What you see in the live window
**Left: the 3-D sea**
- The coloured surface is the seabed (hills, a ridge, a trench). Lighter = shallower.
- Yellow body = the AUV, flying 18 m below the surface.
- The 4 lines below it are the DVL beams (30° from vertical: forward, aft, starboard, port).
  - **Green** – beam reached the seabed and its reading was used.
  - **Red** – beam reading was rejected by the fault checker.
  - **Grey** – no bottom lock (the seabed is further than 37 m along the beam).
- Black line = true path. Blue line = DVL + IMU filter estimate. Orange dashed = IMU alone.
- The title shows time, altitude above the seabed, true and estimated speed, both
  position errors, and the state of each beam.

**Right: live plots**
- *Horizontal position error* (log scale): blue stays near 1–3 m; orange (IMU only) grows to kilometres.
- *Beam fault score |z|*: each dot is one beam reading. Above the red line (4σ) = rejected.
- *Beam slant range*: distance along each beam to the seabed. Above the dashed line = no lock.

## Summary window
Top view of the paths, error against time (shaded = injected fault windows), fault scores,
a beam-status map (grey/green/red over time) and a text summary.

## Expected results (default settings, seed 7)
The seabed is fixed and the simulation uses its own random-number generator (`dvl_rng.m`),
so MATLAB and Octave give exactly the same numbers.

| Quantity | Value |
|---|---|
| Mission | 726 s, 1088 m |
| Final error, DVL + IMU | 2.71 m (0.25 % of distance) |
| Final error, IMU only | 1,474 m |
| Beam readings with no lock | 24.2 % (deep parts of the seabed) |
| Faulty readings caught | 99.4 % |
| Healthy readings rejected | 0.50 % |

## Settings you can change (top of `run_dvl_sea.m`)
| Setting | Meaning |
|---|---|
| `cfg.auv_depth` | AUV depth (m). Deeper = closer to seabed = more beams locked |
| `cfg.max_slant` | Bottom-lock limit along a beam (m) |
| `cfg.rx_channels` | 4 = all beams received together; 1 = one at a time (noisier) |
| `cfg.faults` | Rows of `[beam, start s, end s, bias m/s]` |
| `cfg.outlier_p`, `cfg.outlier_mag` | Random spike rate and size |
| `cfg.heading_err_deg` | Compass/AHRS heading error |
| `cfg.use_fdi` | `false` = turn the fault checker off and see the faults leak in |
| `cfg.k_sigma` | Fault threshold (σ) |
| `cfg.animate` | `false` = no animation, just results (fast) |
| `cfg.frame_every` | Redraw every N DVL updates (raise it if the animation is slow) |
| `cfg.follow_camera` | `true` = camera follows the AUV; `false` = whole sea |
| `cfg.record_video` | `true` = save `DVL_Virtual_Sea.mp4` (MATLAB only) |
| `cfg.seed` | Change for a different run of sensor noise (the seabed stays the same) |

You can rotate and zoom the 3-D view with the mouse at any time.

## Files
| File | Role |
|---|---|
| `run_dvl_sea.m` | Main script: settings, sensors, filter, fault checks, results |
| `make_seabed.m`, `seabed_depth.m` | Build the seabed and read its depth anywhere |
| `make_trajectory.m` | Lawnmower survey path (three 300 m legs) |
| `beam_hit.m` | Traces each beam to the seabed (slant range) |
| `setup_view.m`, `update_view.m` | Live 3-D window and plots |
| `show_summary.m` | Final results window |
| `dvl_rng.m` | Random numbers that are identical in MATLAB and Octave |
| `rot_heading.m`, `beam_colors.m`, `seabed_colormap.m` | Helpers |

## Notes
- This is a simulation of the design. The sensor numbers (1 MHz, 94 Hz single-ping noise,
  37 m lock range) come from the project notebook, not from built hardware.
- In Octave the sea surface is drawn as a blue outline; in MATLAB it is a see-through layer.
