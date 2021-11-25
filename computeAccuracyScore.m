function [score, C] = computeAccuracyScore(P, T)
%COMPUTEACCURACYSCORE Compute accuracy between reconstruction and phantom
%   Return score based on differences in pixel values between original
%   phantom image and reconstruction created by performing radon
%   transformation and inverse radon transformation
    
    if size(P) ~= size(T)
        disp('Not equal')
        score = 0;
        return
    end
    
    C = abs(abs(T) - abs(P));
    
    D = sum(sum(C));
    
    if sum(sum(abs(P))) > 0
        score = D/sum(sum(abs(P)));
    else
        score = D;
    end
    
%     nominal_score = 2000;
    
%     score = sum(sum(abs(D)));
end