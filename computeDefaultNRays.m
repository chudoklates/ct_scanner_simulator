function N = computeDefaultNRays(im)
%COMPUTEDEFAULTNRAYS compute the default N of rays in a projection for
% radon function
    N = 2*ceil(norm(size(im)- ...
            floor((size(im)-1)/2)-1))+3;
end