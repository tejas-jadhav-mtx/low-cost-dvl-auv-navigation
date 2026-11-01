function sea = make_waterbody(kind)
%MAKE_WATERBODY  Ground-truth bottom for the comparison tests.
%   'pond' : 80 m x 50 m, 1-6 m deep, 1 m grid (small campus pond / tank-like)
%   'lake' : 300 m x 200 m, about 8-45 m deep, 2 m grid
%   Depth is positive downwards. The numbers are fixed, so every run and
%   every computer sees exactly the same bottom (this is the ground truth).
    switch kind
        case 'pond'
            sea.x = 0:1:80;  sea.y = 0:1:50;  [X,Y] = meshgrid(sea.x, sea.y);
            D = 1.0 + 5.0*exp(-((X-45).^2/(2*18^2) + (Y-25).^2/(2*11^2)));   % deep middle
            D = D - 1.2*exp(-((X-20).^2 + (Y-35).^2)/(2*5^2));                 % shallow mound
            D = D + 0.8*exp(-((X-62).^2 + (Y-12).^2)/(2*4^2));                 % small hole
            D = D + 0.05*sin(X/2.5).*cos(Y/3);                                  % ripples
            D = max(D, 0.6);
        case 'lake'
            sea.x = 0:2:300; sea.y = 0:2:200; [X,Y] = meshgrid(sea.x, sea.y);
            D = 14 + 0.06*(X-150) + 0.03*(Y-100);                               % sloping bed
            D = D + 22*exp(-((X-200).^2/(2*40^2) + (Y-120).^2/(2*30^2)));      % deep basin
            D = D - 6*exp(-((X-80).^2 + (Y-60).^2)/(2*25^2));                   % hill
            D = D - 4*exp(-((Y - 0.4*X - 120).^2)/(2*10^2));                    % ridge
            D = D + 0.3*sin(X/6).*cos(Y/8);
            D = max(D, 6);
        otherwise
            error('kind must be pond or lake');
    end
    sea.X = X; sea.Y = Y; sea.D = D; sea.kind = kind;
end
