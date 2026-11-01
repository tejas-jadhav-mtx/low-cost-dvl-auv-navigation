function sea = make_seabed()
%MAKE_SEABED  Build a smooth, realistic seabed on a 2 m grid.
%   Depth is positive downwards (metres). The seabed has a gentle slope,
%   rolling hills, a ridge and a small trench, so the DVL beams see real
%   terrain and sometimes lose bottom lock over the deeper parts.
%   The hills are fixed numbers, so the seabed is identical in MATLAB and Octave.
    sea.x = 0:2:600;  sea.y = 0:2:400;
    [X, Y] = meshgrid(sea.x, sea.y);
    D = 50 + 0.012*(X - 300);                            % base depth + slope
    %        x (m)     y (m)    radius   height (+ = hill, - = hollow)
    H = [ 147.8892  232.5160  88.3369   1.5091
          289.5121  123.5935  38.2690   6.2824
          452.5979  100.0462  65.6639   2.2228
          544.0673  112.1393  48.8076  -5.0780
          353.8618  368.7928  74.0717  -5.7459
          223.2542   30.6039  39.6552  -0.7981
           92.0173  108.2293  44.5871  -1.7857
          513.4321   94.1908  66.7814  -2.0993
          174.9064  119.3874  76.7327   4.0978
          439.4471  355.5489  73.7024  -3.5194
          140.3160  226.6881  66.5481   3.2872
          543.7307  319.1209  88.5614   1.7389
          409.5025  319.7108  59.8168   3.4724
          525.1739  204.9181  50.5754  -2.3655 ];
    for h = 1:size(H,1)
        D = D - H(h,4)*exp(-((X-H(h,1)).^2 + (Y-H(h,2)).^2)/(2*H(h,3)^2));
    end
    D = D - 7*exp(-((Y - 0.35*X - 40).^2)/(2*18^2)) .* (X > 120 & X < 520);  % ridge
    D = D + 8*exp(-((X-470).^2/(2*25^2) + (Y-300).^2/(2*60^2)));             % trench
    D = D + 0.4*sin(X/7).*cos(Y/9);                      % sand ripples
    sea.X = X; sea.Y = Y; sea.D = D;
end
