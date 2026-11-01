function R = rot_heading(psi)
%ROT_HEADING  Rotation about the vertical (z-down) axis by heading psi [rad].
    R = [cos(psi) -sin(psi) 0; sin(psi) cos(psi) 0; 0 0 1];
end
