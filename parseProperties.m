function values = parseProperties(values, properties, varargin)
%% PARSEPROPERTIES This function parses a property list.
% This function is in charge of parsing a property-value list and assigning the
% appropriate values in the handles struct.
%	@param values A structure whose fields will be assigned with the values
% found in the properties-value list.
%	@param properties A Nx1 structure array whose lines represent a property.
% The stuctures must have the following fields:
%		-name: The name of the property (corresponding to the name of the field
% in the handle structure.
%		-type: The type of the property. Currently supported types are:
%			*flag: A property with no value. When set call the parsing function.
%           *cell: A property associated with a cell-array value (content
% type is not checked by this function.
%			*char: A property associated with a character string.
%			*integer: A property associated with an integer value.
%           *logical: A property associated with a logical value.
%           *numeric: A property associated with a numeric value.
%           *struct: A property associated with a struct value.
%           *int8: A property associated with a 8-bit integer value. Value
% must be between -2^7 and 2^7 - 1 included.
%           *uint8: A property associated with a 8-bit unsigned integer 
% value. Value must be between 0 and 2^8 - 1 included.
%           *int16: A property associated with a 16-bit integer value. Value
% must be between -2^15 and 2^15 - 1 included.
%           *uint16: A property associated with a 16-bit unsigned integer 
% value. Value must be between 0 and 2^16 - 1 included.
%           *int32: A property associated with a 32-bit integer value. Value
% must be between -2^31 and 2^31 - 1 included.
%           *uint32: A property associated with a 32-bit unsigned integer 
% value. Value must be between 0 and 2^32 - 1 included.
%           *int64: A property associated with a 64-bit integer value. Value
% must be between -2^63 and 2^63 - 1 included.
%           *uint64: A property associated with a 64-bit unsigned integer 
% value. Value must be between 0 and 2^64 - 1 included.
%		-size: The size of the value associated with this property. Use 0 to
% remove a constraint on one dimension.
%		-parse: A handle to the function in charge of parsing the property.
% There is a default parsing function.
%		-min: The minimum value for this property. Use [] to remove the 
% constraint.
%		-max: The maximum value for this property. Use [] to remove the 
% constraint.
%		-...: The property-value list (Use vararagin{:} to forward).
%
% Examples:
%   % From mosaicFigure (see <a href="https://github.com/pasccom/MATLAB-code/blob/master/mosaicFigure.m">mosaicFigure</a>)
%   properties = struct( ...
%       'name', {'DealStrategy'; 'LayoutStrategy'; 'Title'}, ...
%       'type', {'integer'; 'integer'; 'char'}, ...
%       'size', {[1, 1]; [1, 1]; [1, 0]}, ...
%       'parse', {@parseDealStrategy; @parseLayoutStrategy; []}, ...
%       'min' , {1; 1; []}, ...
%       'max' , {3; 4; []} ...
%   );
%   values = parseProperties(values, properties, varargin{3:end});
%
% Copyright 2015 Pascal COMBES <pascom@orange.fr>
%
% Author:   Pascal COMBES <pascom@orange.fr>
% Date:     February 15th, 2015
% Version:  1.0.0
% License:  GPLv3
% Requires: 

    a = 3;
    while (a <= nargin)
        for p = 1:(size(properties, 1) + 1)
            if (p == size(properties, 1) + 1)
                error('Unknown property "%s"', varargin{a - 2});
            end
            if (~strcmp(varargin{a - 2}, properties(p).name))
                continue;
            end
            % The properties name match.
            if (strcmp(properties(p).type, 'flag'))
                if (isa(properties(p).parse, 'function_handle'))
                    values = properties(p).parse(values);
                else
                    % By default toogles the value, if present and
                    % otherwise set it (to true).
                    if (~isfield(values, lower(properties(p).name)) || ...
                        isempty(values.(lower(properties(p).name))))
                        values.(lower(properties(p).name)) = true;
                    else
                        values.(lower(properties(p).name)) = ~values.(lower(properties(p).name));
                    end
                end
                a = a + 1;
                break;
            end
            % Cheking value is present (for non flag types):
            if (a ==  nargin)
                error('Missing property value for property "%s"', properties(p).name);
            end
            value = varargin{a - 1};
            % Size checking:
            if (~all((size(value) == properties(p).size) | (properties(p).size == 0)) ...
                && ~(isempty(value) && any(properties(p).size == 0)))
                error('Bad size for property "%s"', properties(p).name);
            end
            % Type checking:
            switch(properties(p).type)
            case 'char'
                if (~ischar(value))
                    error('Bad string value for property "%s"', properties{p}.name);
                end
            case 'integer'
                if (~isnumeric(value) || ~all(value == round(value)))
                    error('Bad integer value for property "%s"', properties(p).name);
                end
                value = int64(round(value));
            case 'numeric'
                if (~isnumeric(value))
                    error('Bad numeric value for property "%s"', properties(p).name);
                end
            case 'logical'
                if (~islogical(value) && any(value ~= 0) && any(value ~= 1))
                    error('Bad logical value for property "%s"', properties(p).name);
                end
            case 'cell'
                if (~iscell(value))
                    error('Bad cell value for property "%s"', properties(p).name);
                end
            case 'struct'
                if (~isstruct(value))
                    error('Bad struct value for property "%s"', properties(p).name);
                end
            case 'int8'
                if (~isnumeric(value) || ~all(value == round(value)) ...
                || ~all(value >= -128) || ~all(value <= 127))
                    error('Bad 8-bit integer value for property "%s"', properties(p).name);
                end
                value = int8(round(value));
            case 'uint8'
                if (~isnumeric(value) || ~all(value == round(value)) ...
                || ~all(value >= 0) || ~all(value <= 255))
                    error('Bad 8-bit unsigned integer value for property "%s"', properties(p).name);
                end
                value = uint8(round(value));
            case 'int16'
                if (~isnumeric(value) || ~all(value == round(value)) ...
                || ~all(value >= -32768) || ~all(value <= 32767))
                    error('Bad 16-bit integer value for property "%s"', properties(p).name);
                end
                value = int16(round(value));
            case 'uint16'
                if (~isnumeric(value) || ~all(value == round(value)) ...
                || ~all(value >= 0) || ~all(value <= 65535))
                    error('Bad 16-bit unsigned integer value for property "%s"', properties(p).name);
                end
                value = uint16(round(value));
            case 'int32'
                if (~isnumeric(value) || ~all(value == round(value)) ...
                || ~all(value >= -2147483648) || ~all(value <= 2147483647))
                    error('Bad 32-bit integer value for property "%s"', properties(p).name);
                end
                value = int32(round(value));
            case 'uint32'
                if (~isnumeric(value) || ~all(value == round(value)) ...
                || ~all(value >= 0) || ~all(value <= 4294967295))
                    error('Bad 32-bit unsigned integer value for property "%s"', properties(p).name);
                end
                value = uint32(round(value));
            case 'int64'
                if (~isnumeric(value) || ~all(value == round(value)) ...
                || ~all(value >= -9223372036854775808) || ~all(value <= 9223372036854775807))
                    error('Bad 64-bit integer value for property "%s"', properties(p).name);
                end
                value = int64(round(value));
            case 'uint64'
                if (~isnumeric(value) || ~all(value == round(value)) ...
                || ~all(value >= 0) || ~all(value <= 18446744073709551615))
                    error('Bad 64-bit unsigned integer value for property "%s"', properties(p).name);
                end
                value = uint64(round(value));
            otherwise
                error('Unknown type (%s) for property "%s"', properties(p).type, properties(p).name);
            end
            if (~isempty(properties(p).min) && any(value < properties(p).min))
                error('Too small value for property "%s"', properties(p).name);
            end
            if (~isempty(properties(p).max) && any(value > properties(p).max))
                error('Too big value for property "%s"', properties(p).name);
            end
            if (isa(properties(p).parse, 'function_handle'))
                values = properties(p).parse(values, value);
            else
                values.(lower(properties(p).name)) = value;
            end
            a = a + 2;
            break;
        end
    end
end
