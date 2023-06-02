function [output] = normalize(input)
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here
Max = max(max(input));
Min = min(min(input));
output = (input - Min) ./ (Max - Min);
end