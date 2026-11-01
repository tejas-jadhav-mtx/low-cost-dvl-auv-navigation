function d = seabed_depth(sea, x, y)
%SEABED_DEPTH  Seabed depth (m, positive down) at horizontal position (x, y).
%   Fast bilinear interpolation on the uniform seabed grid.
    dx = sea.x(2) - sea.x(1);  nx = numel(sea.x);  ny = numel(sea.y);
    fx = (x - sea.x(1))/dx + 1;  fy = (y - sea.y(1))/dx + 1;
    fx = min(max(fx, 1), nx - 1e-9);  fy = min(max(fy, 1), ny - 1e-9);
    i = floor(fx); j = floor(fy); u = fx - i; w = fy - j;
    d = (1-u).*(1-w).*sea.D(j,i) + u.*(1-w).*sea.D(j,i+1) + (1-u).*w.*sea.D(j+1,i) + u.*w.*sea.D(j+1,i+1);
end
