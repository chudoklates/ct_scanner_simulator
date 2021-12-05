function [error, C] = computeAccuracyScore(P, T)
%COMPUTEACCURACYSCORE Compute accuracy between reconstruction and phantom
%   Return error based on differences in pixel values between original
%   phantom image and reconstruction created by performing radon
%   transformation and inverse radon transformation
    
    if size(P) ~= size(T)
        disp('Not equal')
        error = 1;
        return
    end
    
    C = abs(abs(T) - abs(P));
    
    D = sum(sum(C));
    
    if sum(sum(abs(P))) > 0
        error = D/sum(sum(abs(P)));
    else
        error = D;
    end
end