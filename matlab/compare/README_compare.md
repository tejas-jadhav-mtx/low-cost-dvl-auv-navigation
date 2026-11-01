# Pond / lake comparison: our DVL vs Water Linked A50 (simulation)

## How to run
**Pond only (recommended, about 2–4 minutes):** in the `compare` folder type `compare_pond`.
It also makes `pond_detail.png`: 3-D mapped bottoms vs the true bottom, and error maps.

**Pond + lake (about 10–15 minutes):**
1. Open MATLAB in the `compare` folder (inside `DVL_Virtual_Sea`).
2. Type `compare_pond_lake` and press Enter. It takes about 5–15 minutes (no animation).
3. Output: two figures (`compare_pond.png`, `compare_lake.png`), a table in the
   Command Window and `comparison_results.csv` (opens in Excel).

## What "ground truth" means here
The simulator creates the world itself, so it knows the exact answer:
- **True path** – where the vehicle really was at every instant (`traj`).
- **True bottom** – the real depth everywhere in the pond/lake (`make_waterbody.m`).
Every DVL estimate (path and map) is compared against these. No recorded dataset is used.
This proves the method under the modelled conditions; it does not prove the hardware.
Real ground truth needs field tests (see the project notes: GPS on a surface boat,
known-speed rail in a tank, measured depths at marked points).

## Fair-test rules
- Same water, same survey path, same IMU, same heading sensor (0.5° error), same depth sensor.
- Only the DVL model changes (`dvl_models.m`).
- Water Linked A50 numbers come from its public datasheet: 22.5° beams, 0.05–50 m altitude,
  4–15 Hz updates (10 Hz used), long-term accuracy ±1.01 % (Standard) / ±0.1 % (Performance).
- The A50's per-ping random noise is not published, so it gets the same 1 MHz physics noise as ours.
  Results that depend on that assumption are not a claim that our DVL beats the A50.

## DVL models
| Model | Beam | Min / max slant range | Rate | Receivers | Scale-factor error |
|---|---|---|---|---|---|
| Ours, uncalibrated | 30° | 2.25 / 37 m | 5 Hz | 4 | 1.5 % (≈0.5° beam-angle tolerance of a hand-built head) |
| Ours, GPS-calibrated | 30° | 2.25 / 37 m | 5 Hz | 4 | 0.3 % (target after calibration) |
| Ours, Rs 10k | 30° | 2.25 / 37 m | 5 Hz | 1 | 0.3 % |
| Ours, better damping | 30° | 0.38 / 37 m | 5 Hz | 4 | 0.3 % (ring-down cut from 3 ms to 0.5 ms) |
| A50 Standard | 22.5° | 0.05 / 54 m | 10 Hz | 4 | 1.01 % |
| A50 Performance | 22.5° | 0.05 / 54 m | 10 Hz | 4 | 0.1 % |

## Metrics
- **Bottom lock %** – share of beam readings that reached the bottom inside the DVL's range limits.
- **Final / max / RMS error** – horizontal distance between estimated and true path.
- **Map cover %** – share of map cells (2 m pond, 10 m lake) that got at least one depth point.
- **Map RMSE** – depth error of the mapped cells vs the true bottom.
