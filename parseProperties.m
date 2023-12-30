function values = parseProperties(values, properties, varargin)
% @brief Parse a property-value list
%
% Parse a property-value list and assign the appropriate values
% in the given struct.
% @param values A structure whose fields will be assigned with the values
% found in the properties-value list
% @param properties A Nx1 structure array whose lines represent a property.
% The stuctures must have the following fields:
%   - <tt>'name'</tt> The name of the property (corresponding to the name of the field
% in the handle structure.
%   - <tt>'type'</tt> The type of the property. Currently supported types are:
%     * <tt>flag</tt> A property with no value. When set call the parsing function.
%     * <tt>cell</tt> A property associated with a cell-array value (content
% type is not checked by this function.
%     * <tt>char</tt> A property associated with a character array.
%     * <tt>integer</tt> A property associated with an integer value.
%     * <tt>logical</tt> A property associated with a logical value.
%     * <tt>numeric</tt> A property associated with a numeric value.
%     * <tt>struct</tt> A property associated with a structure value.
%     * <tt>int8</tt> A property associated with a 8-bit integer value. Value
% must be between <tt>-2^7</tt> and <tt>2^7 - 1</tt> included.
%     * <tt>uint8</tt> A property associated with a 8-bit unsigned integer
% value. Value must be between <tt>0</tt> and <tt>2^8 - 1</tt> included.
%     * <tt>int16</tt> A property associated with a 16-bit integer value. Value
% must be between <tt>-2^15</tt> and <tt>2^15 - 1</tt> included.
%     * <tt>uint16</tt> A property associated with a 16-bit unsigned integer
% value. Value must be between <tt>0</tt> and <tt>2^16 - 1</tt> included.
%     * <tt>int32</tt> A property associated with a 32-bit integer value. Value
% must be between <tt>-2^31</tt> and <tt>2^31 - 1</tt> included.
%     * <tt>uint32</tt> A property associated with a 32-bit unsigned integer
% value. Value must be between <tt>0</tt> and <tt>2^32 - 1</tt> included.
%     * <tt>int64</tt> A property associated with a 64-bit integer value. Value
% must be between <tt>-2^63</tt> and <tt>2^63 - 1</tt> included.
%     * <tt>uint64</tt> A property associated with a 64-bit unsigned integer
% value. Value must be between <tt>0</tt> and <tt>2^64 - 1</tt> included.
%   - <tt>'size'</tt> The size of the value associated with this property.
% Use <tt>0</tt> to remove a constraint on one dimension.
%   - <tt>'parse'</tt> A handle to the function in charge of parsing the property.
% There is a default parsing function. It simmply assigns the value to the
% field whose name corresponds to the property name in lower case.
%   - <tt>'min'</tt> The minimum value for this property.
% Use <tt>[]</tt> to remove the constraint.
%   - <tt>'max'</tt> The maximum value for this property.
% Use <tt>[]</tt> to remove the constraint.
% @param varargin The property-value list (Use <tt>vararagin{:}</tt> to forward).
% @return A structure whose fields have been assigned with the values
% found in the properties-value list
%
% \par Examples
% This example is taken from mosaicFigure()
% \code{.m}
%   values = struct;
%   % Default settings
%   values.title = [];
%   values.dealStrategy = @dealFigures3;
%   values.layoutStrategy = @computeLayout4;
%   % Defined properties
%   props = struct(                                                   ...
%       'name',  {    'DealStrategy';     'LayoutStrategy'; 'Title'}, ...
%       'type',  {         'integer';            'integer';  'char'}, ...
%       'size',  {            [1, 1];               [1, 1];  [1, 0]}, ...
%       'parse', {@parseDealStrategy; @parseLayoutStrategy;      []}, ...
%       'min' ,  {                 1;                    1;      []}, ...
%       'max' ,  {                 3;                    4;      []}  ...
%   );
%   % Parse arguments (from the 3rd)
%   values = parseProperties(values, props, varargin{3:end});
% \endcode
%
% % Copyright:  2015-2023 Pascal COMBES <pascom@orange.fr>
% % Author:     Pascal COMBES <pascom@orange.fr>
% % Date:       December 30th, 2023
% % Version:    1.0
% % License:    GPLv3
% % Requires:

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
