function c = seabed_colormap()
%SEABED_COLORMAP  Deep blue-grey to sand colour map for the seabed.
    t = linspace(0,1,64)';
    c = [0.10+0.75*t, 0.15+0.62*t, 0.30+0.30*t];
end
