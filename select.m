function [container] = select(fun, container, varargin)
%% SELECT Select elements of a container matching a criterium.
% Removes the elements which don't match a criterium given by some
% function from a container.
%   @param fun The criterium function. It will be applied to subcontainers
%   of the given container along the dimension i.
%   @param container The container where elements will be selected.
%   @param dim The dimension along which the container will be parsed.
%   @return The container where the non-selected elements have been
%   removed.
%
% Examples:
%   % Test if argument is even
%   even = @(X) all(mod(X, 2) == 0);
%
%   select(even, [1, 2, 3, 4]); % returns [2, 4]
%   select(even, [1, 2, 3, 4], 2); % equivalent to previous.
%   select(even, [1, 2, 3, 4], 1); % returns empty([0, 4])
%
%   select(even, [1; 2; 3; 4]); % returns [2; 4]
%   select(even, [1; 2; 3; 4], 1); % equivalent to previous.
%   select(even, [1; 2; 3; 4], 2); % returns empty([4, 0])
%
%   select(even, [1, 2; 4, 8], 1); % returns [4, 8]
%   select(even, [1, 2; 4, 8], 2); % returns [2; 8]
%
% Copyright 2015 Pascal COMBES <pascom@orange.fr>
%
% Author:   Pascal COMBES <pascom@orange.fr>
% Date:     May 1st, 2015
% Version:  1.0.0
% License:  GPLv3
% Requires: 

    %% Checks arguments
    % Check container type
    if (~iscell(container) && ~isnumeric(container) && ~isstruct(container) && ~ischar(container))
        error('MATLAB:BadArgument', 'This function supports only numeric, cell, struct or char arrays');
    end
    % Check argument number
    if (nargin == 2)
        dim = find(size(container) ~= 1);
        if (any(size(dim) ~= [1 1]))
            error('MATLAB:BadArgument', 'When 2 arguments are passed the container should be essentialy of dimension one.');
        end
    elseif (nargin == 3)
        dim = varargin{1};
    else
        error('MATLAB:BadArgumentNumber', 'This function accepts 2 or three arguments. %d were passed.', nargin);
    end
    
    %% Initialisation of output container and type
    S = struct;
    if (iscell(container))
        S.type = '{}';
    else
        S.type = '()';
    end
    
    %% Initialisation of subs
    S.subs = cell(size(size(container)));
    for m = 1:size(S.subs, 2)
        S.subs{m} = ':';
    end
    
    %% Selection
    j = 1;
    for i = 1:size(container, dim)
        S.subs{dim} = i;
        item = subsref(container, S);
        if (fun(item))
            if (j ~= i)
                S.subs{dim} = j;
                container = subsasgn(container, S, item);
            end
            j = j + 1;
        end
    end
    
    %% Crop the useless part of array
    if (j <= size(container, dim))
        S.type = '()';
        S.subs{dim} = j:size(container, dim);
        container = subsasgn(container, S, []);
    end
end