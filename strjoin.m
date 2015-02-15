function [str] = strjoin(varargin)
%% STRJOIN Glue all string in cell with glue.
% This function can handle one or two arguments. The first one is the parts
% of strings and the second which is optional is the glue. It the second
% argument is not provided the parts will be glued with the empty string.
%   @param parts Parts of the string as a cell array of strings or a
% string.
%   @param glue Optionnal. The glue to use to glue the parts together.
%   @return str A string composed of all the parts gued together using the
% provided glue string.
%
% Examples:
%   parts = 'a';
%   str = strjoin(parts)
%   str = 'a'
%
%   parts = 'a';
%   str = strjoin(parts, ',')
%   str = 'a'
%
%   parts = {'a', 'b', 'c', 'd', 'e', 'f'};
%   str = strjoin(parts, ',')
%   str = 'a,b,c,d,e,f'
%   parts = {'a', 'b', 'c', 'd', 'e', 'f'};
%   str = strjoin(parts, ', ')
%   str = 'a, b, c, d, e, f'
%
% Copyright 2015 Pascal COMBES <pascom@orange.fr>
%
% Author:   Pascal COMBES <pascom@orange.fr>
% Date:     February 15th, 2015
% Version:  1.0.0
% License:  GPLv3
% Requires: 
    
    if(nargin == 0)
        error('strjoin needs at least one argument');
    end
    cell = varargin{1};
    glue = '';
    if(nargin > 1)
        glue = varargin{2};
    end
    if(nargin > 2)
        warning('This function needs only 2 arguments other will be ignored');
    end

    totalLength = 0;
    if(ischar(cell))
        cell = {cell};
    end
    if(isempty(cell))
        str = '';
        return;
    end
    if((size(cell, 1) ~= 1) && (size(cell, 2) ~= 1))
        error('Cell should be either a row or a column cell array');
    end
    for i = 1:max(size(cell))
        if(~ischar(cell{i}))
            error('Cell should be a cell array of strings');
        end
        totalLength = totalLength + size(cell{i}, 2);
    end
    
    if (~ischar(glue))
        error('Glue is expected to be of type char');
    end
    
    totalLength = totalLength + (max(size(cell)) - 1)*size(glue, 2);

    str = zeros(1, totalLength);
    
    j = 1;
    for i = 1:(max(size(cell)) - 1)
        str(j:(j + size(cell{i}, 2) - 1)) = cell{i};
        j = j + size(cell{i}, 2);
        str(j:(j + size(glue, 2) - 1)) = glue;
        j = j + size(glue, 2);
    end
    str(j:(j + size(cell{end}, 2) - 1)) = cell{end};
    
    str = char(str);
end

