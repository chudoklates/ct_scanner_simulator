function [score, differenceMap, x, y] = accuracyScoreWithShift(P, T, d)
%ACCURACYSCOREWITHSHIFT Return a matrix of score differences 
% for a maximum shift of d
    s = -d:1:d;
    
    l = length(s);

    [X, Y] = meshgrid(s);
    
    S = zeros(l);
    D = cell(l, l);

    for i = 1:1:l
        for j = 1:1:l
            shifted = circshift(T,[X(j, j) Y(i, i)]);
            [k, m] = computeAccuracyScore(P, shifted);
            S(i, j) = k;
            D{i, j} = m;
        end
    end
    
    score = min(S, [], 'all');
    
    [a, b] = find(S == score);
    
    differenceMap = D{a, b};
    
    x = X(a, a);
    y = Y(b, b);
end