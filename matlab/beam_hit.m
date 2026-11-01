function R = beam_hit(sea, p, d)
%BEAM_HIT  Slant range from the transducer at p along unit direction d to
%   the seabed (ray marching + bisection). Returns Inf if no hit within 150 m.
    step = 2.0; s0 = 0; R = Inf;
    for s1 = step:step:150
        q = p + s1*d;
        if q(3) >= seabed_depth(sea, q(1), q(2))
            for it = 1:14                                % bisection refine
                sm = 0.5*(s0 + s1); q = p + sm*d;
                if q(3) >= seabed_depth(sea, q(1), q(2)), s1 = sm; else, s0 = sm; end
            end
            R = 0.5*(s0 + s1); return;
        end
        s0 = s1;
    end
end
