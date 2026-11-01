function r = dvl_rng(kind, m, n)
%DVL_RNG  Portable random numbers: the same seed gives exactly the same
%   numbers in MATLAB and in Octave (their built-in rand/randn differ).
%   dvl_rng('seed', s)      start the stream
%   dvl_rng('rand', m, n)   uniform numbers in (0,1)
%   dvl_rng('randn', m, n)  standard normal numbers
%   Park-Miller generator (exact in double precision) + Box-Muller.
    persistent s spare
    if isempty(s), s = 12345; end
    if strcmp(kind, 'seed')
        s = mod(round(m)*7919 + 12345, 2147483646) + 1; spare = []; r = []; return;
    end
    if nargin < 2, m = 1; end
    if nargin < 3, n = 1; end
    N = m*n; r = zeros(m, n);
    if strcmp(kind, 'rand')
        for i = 1:N, s = mod(16807*s, 2147483647); r(i) = s/2147483647; end
    else
        for i = 1:N
            if ~isempty(spare), r(i) = spare; spare = []; continue; end
            s = mod(16807*s, 2147483647); u1 = s/2147483647;
            s = mod(16807*s, 2147483647); u2 = s/2147483647;
            rad = sqrt(-2*log(u1));
            r(i) = rad*cos(2*pi*u2); spare = rad*sin(2*pi*u2);
        end
    end
end
