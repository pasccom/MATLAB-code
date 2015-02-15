function [parts] = stringSplit(string, delimiter)
%% STRINGSPLIT Splits a string into parts according to delimiter.
%   @param string The string to split.
%   @param delimiter The delimiter for parts of the splitted string.
%   @return parts A column cell array containing the string splitted
% according to the delimiter.
%
% Examples:
%   str = '1,2,3';
%   parts = stringSplit(str, ',')
%   parts =
%       '1'
%       '2'
%       '3'
%
%   str = '(a;1),(b;2),(c;3)';
%   parts = stringSplit(str, ',')
%   parts =
%       '(a;1)'
%       '(b;2)'
%       '(c;3)'
%
% Copyright 2015 Pascal COMBES <pascom@orange.fr>
%
% Author:   Pascal COMBES <pascom@orange.fr>
% Date:     February 15th, 2015
% Version:  1.0.0
% License:  GPLv3
% Requires: 


    % Checks the size of the delimiter:
    if(any(size(delimiter) ~= [1, 1]))
        error('The delimiter is expected to be 1x1');
    end
    
    splits = find(string==delimiter);
    splits = [0, splits, size(string, 2) + 1];
    
    parts = cell(size(splits, 2) - 1, 1);
    for s=2:size(splits, 2)
        parts{s - 1} = string((splits(s - 1) + 1):(splits(s) - 1));
    end
end

