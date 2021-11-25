function openHistogram(im)
%OPENHISTOGRAM Open histogram of image in new window for more detail
%   
    figure('Name', 'Histogram', 'NumberTitle', 'off')
    h = histogram(im, 'EdgeColor', 'none');
    axes = h.Parent;
    xlabel(axes, 'Values')
    ylabel(axes, 'Pixels')
end

