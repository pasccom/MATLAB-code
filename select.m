function [container] = select(fun, container, dim)
% @brief Select elements of a container matching a criterium.
%
% Removes from a container the elements which don't match a criterium
% given by some function handle.
% @param fun The criterium function. It will be applied to subcontainers
% of the given container along the given dimension.
% @param container The container where elements will be selected.
% Matrices, char arrays, structure arrays and cell arrays are supported.
% @param dim The dimension along which the container will be parsed.
% @return The container where the non-selected elements have been removed.
%
% @note
% When the container essentially has a single dimension, the **dim**
% argument is optional
%
% \par Examples
% Given the following funtion
% \code{.m}
%   % Test if argument is even
%   even = @(X) all(mod(X, 2) == 0);
% \endcode
% These two calls will return <tt>[2, 4]</tt>. In the first case, the
% second (column) dimension has been selected automatically as there is
% only one line.
% \code{.m}
%   select(even, [1, 2, 3, 4]);
%   select(even, [1, 2, 3, 4], 2);
% \endcode
% In this case, the function will return an empty matrix of size 0x4 as some
% the elements in the line are odd, hence it has not been selected.
% \code{.m}
%   select(even, [1, 2, 3, 4], 1);
% \endcode
% These two calls will return <tt>[2; 4]</tt>. In the first case, the
% first (line) dimension has been selected automatically as there is
% only one column.
% \code{.m}
%   select(even, [1; 2; 3; 4]);
%   select(even, [1; 2; 3; 4], 1);
% \endcode
% In this case, the function will return an empty matrix of size 4x0 as some
% the elements in the column are odd, hence it has not been selected.
% \code{.m}
%   select(even, [1; 2; 3; 4], 2);
% \endcode
% Here, the function will return <tt>[4, 8]</tt> as the function will be
% applied line-wise and the second line is the only one containing only
% even numbers.
% \code{.m}
%   select(even, [1, 2; 4, 8], 1);
% \endcode
% Here, the function will return <tt>[2; 8]</tt> as the function will be
% applied column-wise and the second column is the only one containing only
% even numbers.
% \code{.m}
%   select(even, [1, 2; 4, 8], 2);
% \endcode
%
% % Copyright:  2015-2023 Pascal COMBES <pascom@orange.fr>
% % Author:     Pascal COMBES <pascom@orange.fr>
% % Date:       December 29th, 2023
% % Version:    1.0
% % License:    GPLv3
% % Requires:

    %% Checks arguments
    % Check container type
    if (~iscell(container) && ~isnumeric(container) && ~isstruct(container) && ~ischar(container))
        error('select:BadArgument', 'This function supports only numeric, cell, struct or char arrays');
    end
    % Check argument number
    if (nargin < 3)
        dim = find(size(container) > 1);
        if (any(size(dim) > [1 1]))
            error('select:BadArgument', 'When 2 arguments are passed the container should be essentialy of dimension one.');
        elseif (isempty(dim))
            dim = 1;
        end
    end
    
    %% Initialisation of subs
    S = struct;
    S.type = '()';
    S.subs = cell(size(size(container)));
    for m = 1:size(S.subs, 2)
        S.subs{m} = ':';
    end
    
    %% Selection
    j = 1;
    for i = 1:size(container, dim)
        S.subs{dim} = i;
        item = subsref(container, S);
        if (~isempty(item) && fun(item))
            if (j ~= i)
                S.subs{dim} = j;
                container = subsasgn(container, S, item);
            end
            j = j + 1;
        end
    end
    
    %% Crop the useless part of array
    if (j <= size(container, dim))
        S.subs{dim} = j:size(container, dim);
        container = subsasgn(container, S, []);
    end
end