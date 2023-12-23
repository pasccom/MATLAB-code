classdef XLSFile < handle
% @brief MATLAB-sytle Excel workbook abstraction
%
% Allow to access an Excel workbook as a MATLAB cell array
%
% \par Examples
%   - `xlsFile(l, c)` Access cell at (l, c) in active sheet as a cell array
%   - `xlsFile{l, c}` Access cell at (l, c) in active sheet as a double
%   - `xlsFile(bl:el, bc:ec)` Access range at (bl, bc):(el, ec) in active sheet as a cell array
%   - `xlsFile{bl:el, bc:ec}` Access range at (bl, bc):(el, ec) in active sheet as a matrix
%   - `xlsFile.otherSheet(l, c)` Access cell at (l, c) in sheet *otherSheet* as a cell array
%   - `xlsFile.otherSheet{l, c}` Access cell at (l, c) in sheet *otherSheet* as a double
%   - `xlsFile.otherSheet(bl:el, bc:ec)` Access range at (bl, bc):(el, ec) in sheet *otherSheet* as a cell array
%   - `xlsFile.otherSheet{bl:el, bc:ec}` Access range at (bl, bc):(el, ec) in sheet *otherSheet* as a matrix
%
% @note Line and column numbering starts at 1
%
% % Copyright:  2023 Pascal COMBES <pascom@orange.fr>
% % Author:     Pascal COMBES <pascom@orange.fr>
% % Date:       December 22nd, 2023
% % Version:    1.0
% % License:    GPLv3
% % Requires:

    properties(Dependent)
        IsOpen      %< Whether an XLS workbook is open
        ActiveSheet %< The name of the active sheet (empty if no workbook is opened)
        Sheets      %< A cell-array listing all the sheets in the opened workbook (empty otherwise)
        Path        %< The path to the opened workbook (empty otherwise)
    end
    properties(Access=private)
        mExcel      %< COM handle to the Excel application
        mWorkBook   %< COM handle to the opened workbook
    end
    methods(Static, Access=public)
        function labelNames = getSensitivityLabelNames()
        % @brief List of sensitivity label names
        %
        % Return the list of allowed names for sensitivity labels. The
        % names in this list may not reflect exactly the actual label names,
        % but are mnemonics internal to the plugin
        % @return The list of allowed names for sensitivity labels
        % @sa organizationSensitivities()
            labelNames = {};
            try
                labelNames = fieldnames(organizationSensitivities());
            catch anyErr
                if ~strcmp(anyErr.identifier, 'MATLAB:UndefinedFunction')
                    rethrow(anyErr);
                end
            end
        end

        function xlsLine = toXLSLine(line)
        % @brief Convert a line number from MATLAB to Excel
        %
        % Convert a MATLAB line number into an Excel line number [1-9][0-9]*
        % @param line A MATLAB line number
        % @return An Excel line number
            xlsLine = sprintf('%d', line);
        end
        function xlsCol = toXLSColumn(col)
        % @brief Convert a column number from MATLAB to Excel
        %
        % Convert a MATLAB column number into an Excel column number [A-Z]+
        % @param col A MATLAB column number
        % @return An Excel column number
            % Notice that the total number of column indexes coded with N
            % letters in Excel is
            % \sum_{n=1}^N 26^n = (26^(N + 1) - 1)/(26 - 1)
            xlsCol = char(zeros(1, floor(log(col*25 + 1)/log(26))));
            c = size(xlsCol, 2);
            while (col ~= 0)
                xlsCol(c) = char(mod(col - 1, 26) + 'A');
                col = floor((col - 1)/26);
                c = c - 1;
            end
        end
    end
    methods
        function self = XLSFile(varargin)
        % @brief Constructor
        %
        % Initialize the class and, optionally,
        % open an Excel spreadsheet through ActiveX interface
        % or create one if it does not exists yet.
        % @param varargin Up to 3 parameters
        %   - **filePath** Path to the Excel spreadsheet
        % (may be relative or absoulute)
        %   - **allowCreation** Whether to create a new file
        % if it does not exist yet
        %   - **sensitivityLabelName** The name of the sensitivity label
        % to be applied to the document (see getSensitivityLabelNames())
        % @return The new Excel spreadsheet abstraction

            % Initialize properties
            self.mExcel = [];
            self.mWorkBook = [];
            if (nargin > 0)
                self.open(varargin{:});
            end
        end
        function delete(self)
        % @brief Destructor
        %
        % Closes the workbook and the connection to Excel.
            self.close();
            % Quit Excel
            if ~isempty(self.mExcel)
                self.mExcel.Quit();
                delete(self.mExcel);
            end
        end
        function open(self, filePath, allowCreation, sensitivityLabelName)
        % @brief Open an Excel spreadsheet
        %
        % Open an Excel spreadsheet through ActiveX interface
        % or create one if it does not exists yet.
        % @param filePath Path to the Excel spreadsheet (may be relative or absoulute)
        % @param allowCreation Whether to create a new file if it does not exist yet
        % (defaults to true)
        % @param sensitivityLabelName The name of the sensitivity label to
        % be applied to the document (see getSensitivityLabelNames())
        % @return The new Excel spreadsheet abstraction
            if ~isempty(self.mWorkBook)
                self.close();
            end
            % Make path absoloute
            parts = strsplit(filePath, filesep);
            if (~isempty(parts{1}) && (parts{1}(end) ~= ':'))
                filePath = fullfile(pwd, filePath);
            end
            % Open file if it exists else create it
            if (exist(filePath, 'file') == 2)
                self.setupExcel();
                self.mWorkBook = self.mExcel.Workbooks.Open(filePath);
            elseif ((nargin < 2) || (allowCreation))
                self.setupExcel();
                sheetsInNewWorkbook = self.mExcel.SheetsInNewWorkbook;
                self.mExcel.SheetsInNewWorkbook = 1;
                % Create new workbook
                self.mWorkBook = self.mExcel.Workbooks.Add();
                if (nargin >= 3)
                    % Get the list of organization-defined sensitivity labels
                    labelNames = struct;
                    try
                        labelNames = organizationSensitivities();
                    catch anyErr
                        if ~strcmp(anyErr.identifier, 'MATLAB:UndefinedFunction')
                            rethrow(anyErr);
                        end
                    end
                    % Apply selected sensitivity label
                    if isfield(labelNames, sensitivityLabelName)
                        label = self.mWorkBook.SensitivityLabel.CreateLabelInfo();
                        for field = transpose(fieldnames(labelNames.(sensitivityLabelName)))
                            if ~strcmp(field{:}, 'Test')
                                label.(field{:}) = labelNames.(sensitivityLabelName).(field{:});
                            end
                        end
                        label.Justification = 'Automatically set by MATLAB XLSFile';
                        self.mWorkBook.SensitivityLabel.SetLabel(label, []);
                    else
                        warning('XLSFile:NoSuchName', 'Sensitivity label "%s" does not exist.', sensitivityLabelName);
                    end
                end
                % Save new workbook
                self.mWorkBook.SaveAs(filePath);
                self.mExcel.SheetsInNewWorkbook = sheetsInNewWorkbook;
            else
                error('XLSFile:FileDoesNotExist', 'File "%s" does not exist', filePath);
            end
        end
        function isOpen = get.IsOpen(self)
        % @brief Whether a file is open
        %
        % Tell whether a file is really open
        % @return Whether a file is open
            isOpen = ~isempty(self.mWorkBook);
        end
        function name = get.Path(self)
        % @brief Excel file path
        %
        % Return the path to the Excel file
        % @return The path to the Excel file
            if ~isempty(self.mWorkBook)
                name = fullfile(self.mWorkBook.Path, self.mWorkBook.Name);
            else
                name = '';
            end
        end
        function save(self, filePath)
        % @brief Save the Excel file
        %
        % Save the workbook. If the optional argument is given, the file
        % can be saved in another place.
        % @param filePath The path where to save the file.
            if (nargin < 2)
                self.mWorkBook.Save();
            else
                % Make path absoloute
                parts = strsplit(filePath, filesep);
                if (~isempty(parts{1}) && (parts{1}(end) ~= ':'))
                    filePath = fullfile(pwd, filePath);
                end
                if (exist(filePath, 'file') == 0)
                    self.mWorkBook.SaveAs(filePath);
                elseif strcmp(filePath, self.Path)
                    self.mWorkBook.Save();
                else
                    error('XLSFile:FileExists', 'File "%s" already exists', filePath);
                end
            end
        end
        function close(self, save)
        % @brief Close the Excel file
        %
        % Close the workbook and the connection to Excel.
        % @param save Whether to save the file before closing it
            if (nargin < 2)
                save = true;
            end
            if ~isempty(self.mWorkBook)
                self.mWorkBook.Close(save);
            end
            self.mWorkBook = [];
        end

        function name = get.ActiveSheet(self)
        % @brief Get active sheet name
        %
        % Return the name of the active sheet in the workbook
        % @return The name of the active sheet
            if ~isempty(self.mWorkBook)
                name = self.mWorkBook.ActiveSheet.Name;
            else
                name = '';
            end
        end
        function set.ActiveSheet(self, name)
        % @brief Set active sheet name
        %
        % Change the active sheet in the workbook
        % @note If the sheet does not exist, the function will raise a
        % warning.
        % @param name The name of the active sheet
            sheet = getSheet(self, name);
            if isempty(sheet)
                warning('XLSFile:NoSuchName', 'Sheet "%s" does not exist', name);
            else
                sheet.Activate;
            end
        end
        function S = get.Sheets(self)
        % @brief Excel file sheets
        %
        % Return a cell-array containing the names of the sheets in an
        % Excel file
        % @return A cell-array containg the names of the sheets
            if ~isempty(self.mWorkBook)
                sheets = self.mWorkBook.Sheets;
            else
                sheets = struct('Count', 0);
            end
            S = arrayfun(@(s) sheets.Item(s).Name, 1:sheets.Count, 'UniformOutput', false);
        end
        function ret = addSheet(self, name, at, visible)
        % @brief Add a sheet
        %
        % Add a new sheet to the workbook.
        % @param name The name of the new sheet
        % @param at Place where the sheet should be added (0-based)
        % @param visible Whether the sheet should be visible
        % @return Whether a sheet was successfully added to the workbook
            if (nargin < 4)
                visible = true;
            end
            if ~isempty(self.mWorkBook)
                if ((nargin < 3) || (at >= self.mWorkBook.Sheets.Count) || (at == -1))
                    s = self.mWorkBook.Sheets.Add(self.mWorkBook.Sheets.Item(self.mWorkBook.Sheets.Count));
                    self.mWorkBook.Sheets.Item(self.mWorkBook.Sheets.Count).Move(s);
                elseif (at >= 0)
                    s = self.mWorkBook.Sheets.Add(self.mWorkBook.Sheets.Item(at + 1));
                elseif (at < -self.mWorkBook.Sheets.Count)
                    s = self.mWorkBook.Sheets.Add(self.mWorkBook.Sheets.Item(1));
                else
                    s = self.mWorkBook.Sheets.Add(self.mWorkBook.Sheets.Item(self.mWorkBook.Sheets.Count + at + 2));
                end
                s.Name = name;
                s.Visible = visible;
                ret = true;
            else
                ret = false;
            end
        end
        function ret = removeSheet(self, name)
        % @brief Remove a sheet
        %
        % Remove a sheet from a workbook
        % @param name The name of the sheet to remove
        % @return Whether a sheet was really removed
            if ~isempty(self.mWorkBook)
                sheet = getSheet(self, name);
                if ~isempty(sheet)
                    sheet.Delete();
                else
                    warning('XLSFile:NoSuchName', 'Sheet "%s" does not exist', name);
                end
                ret = ~isempty(sheet);
            else
                ret = false;
            end
        end

        function varargout = subsref(self, S)
        % @brief Implement magical index access
        %
        % The following indexing methods are currently supported:
        %   - Single cell indexing: xlsFile[.sheet](l, c): Get the data in
        % the cell (l, c) in a cell
        %   - Multilple cell indexing: xlsFile[.sheet](bl:el, bc:ec): Get
        % the data in the cell range (bl, bc) to (el, ec) inclusive in a
        % cell array.
        %   - Single value indexing: xlsFile[.sheet]{l, c): Get the data in
        % the cell (l, c)
        %   - Matrix indexing: xlsFile[.sheet]{l, c): Get the data in
        % the cell range (bl, bc) to (el, ec) inclusive in a matrix
        % @param S Subs structure array (see MATLAB help on subsref)
        % @return A single value, a matrix or a cell array depending on the
        % indexing type.
        % @sa subsasgn
            varargout = cell(1, nargout);
            % Get the desired sheet
            if strcmp(S(1).type, '.')
                if (length(S) < 2)
                    % Maybe the user wants to access a property
                    [varargout{1:nargout}] = builtin('subsref', self, S);
                    return;
                end

                sheet = getSheet(self, S(1).subs);
                if isempty(sheet)
                    try
                        % Maybe the user wants to access a method
                        [varargout{1:nargout}] = builtin('subsref', self, S);
                        return;
                    catch anyErr
                        if strcmp(anyErr.identifier, 'MATLAB:noSuchMethodOrField')
                            if isempty(self.mWorkBook)
                                error('XLSFile:NoWorkbook', 'No workbook opened');
                            else
                                error('XLSFile:NoSuchName', 'Sheet "%s" not found', S(1).subs());
                            end
                        end
                        rethrow(anyErr);
                    end
                end
                S = S(2:end);
            else
                if ~isempty(self.mWorkBook)
                    sheet = self.mWorkBook.ActiveSheet;
                else
                    error('XLSFile:NoWorkbook', 'No workbook opened');
                end
            end

            % Check the provided indexing method
            if (length(S) > 1)
                error('Unsupported indexing');
            end
            if (length(S(1).subs) ~= 2)
                error('Unsupported indexing');
            end
            if any(cellfun(@(s) ischar(s), S(1).subs))
                error('Unsupported indexing');
            end
            if strcmp(S(1).type, '.')
                error('Unsupported indexing');
            end

            % Get data from Excel
            [ranges, rows, cols] = XLSFile.toXLSRanges(S(1).subs);
            data = cell(rows, cols);
            for range = ranges
                datum = sheet.Range(range.excel).Value;
                if iscell(datum)
                    data(range.rows, range.cols) = datum;
                else
                    data(range.rows, range.cols) = {datum};
                end
            end

            % Data post-processing
            if strcmp(S(1).type, '{}')
                if ((rows == 1) && (cols == 1))
                    data = data{:};
                    if (isnan(data))
                        data = '';
                    end
                else
                    data = cellfun(@XLSFile.processArrayRef, data);
                end
            else
                data = cellfun(@XLSFile.processCellRef, data, 'UniformOutput', false);
            end
            varargout = {data};
        end

        function self = subsasgn(self, S, data)
        % @brief Implement magical index assignation
        %
        % The following indexing methods are currently supported:
        %   - Single cell indexing: xlsFile[.sheet](l, c): Set the data in
        % the cell (l, c) in a cell
        %   - Multilple cell indexing: xlsFile[.sheet](bl:el, bc:ec): Set
        % the data in the cell range (bl, bc) to (el, ec) inclusive in a
        % cell array.
        %   - Single value indexing: xlsFile[.sheet]{l, c): Set the data in
        % the cell (l, c)
        %   - Matrix indexing: xlsFile[.sheet]{l, c): Set the data in
        % the cell range (bl, bc) to (el, ec) inclusive in a matrix
        % @param S Subs structure array (see MATLAB help on subsasgn)
        % @param data The data to be written into the specified range
        % @return The instance
        % @sa subsref
            % Get the desired sheet
            if strcmp(S(1).type, '.')
                if (length(S) < 2)
                    % Maybe the user wants to access a property
                    self = builtin('subsasgn', self, S, data);
                    return;
                end

                sheet = getSheet(self, S(1).subs);
                if isempty(sheet)
                    try
                        % Maybe the user wants to access a method
                        % (even though I don't think that it is possible)
                        self = builtin('subsasgn', self, S, data);
                        return;
                    catch anyErr
                        if strcmp(anyErr.identifier, 'MATLAB:noSuchMethodOrField')
                            if isempty(self.mWorkBook)
                                error('XLSFile:NoWorkbook', 'No workbook opened');
                            else
                                error('XLSFile:NoSuchName', 'Sheet "%s" not found', S(1).subs());
                            end
                        end
                        rethrow(anyErr);
                    end
                end
                S = S(2:end);
            else
                if ~isempty(self.mWorkBook)
                    sheet = self.mWorkBook.ActiveSheet;
                else
                    error('XLSFile:NoWorkbook', 'No workbook opened');
                end
            end

            % Check the provided indexing method
            if (length(S) > 1)
                error('Unsupported indexing');
            end
            if (length(S(1).subs) ~= 2)
                error('Unsupported indexing');
            end
            if any(cellfun(@(s) ischar(s), S(1).subs))
                error('Unsupported indexing');
            end
            if strcmp(S(1).type, '.')
                error('Unsupported indexing');
            end

            % Set data in Excel
            ranges = XLSFile.toXLSRanges(S(1).subs);
            for range = ranges
                sheet.Range(range.excel).Value = data(range.rows, range.cols);
            end
         end
    end

    methods(Static, Access=private)
        function datum = processCellRef(datum)
        % @brief Convert data for cell reference
        %
        % Process the data returned by the COM function to put it in a cell
        % arrey. Currently the following modifications are applied:
        %  - Replace \c NaN by empty cell
        %
        % @param datum Data from the COM function
        % @return The datum converted for use in MATLAB
            if isnan(datum)
                datum = [];
            end
        end
        function datum = processArrayRef(datum)
        % @brief Convert data for array reference
        %
        %  Process the data returned by the COM function to put it in a
        %  matrix. All non numeric data is replaced by \c NaN.
        % @param datum Data from the COM function
        % @return The datum converted for use in MATLAB
            if isnumeric(datum)
                datum = double(datum);
            else
                datum = nan;
            end
        end

        function varargout = toXLSRanges(subs)
        % @brief Convert MATLAB subs into Excel ranges
        %
        % Transform a MATLAB subs specification (logical indexing is not supported)
        % into (maybe many) Excel ranges.
        % @param subs Indexes from MATLAB subs array (see MATLAB help on subsref and subsasgn)
        % @return One, two or three values:
        %   - The Excel ranges corresponding to the given MATLAB subs array
        %   - The number of lines in total
        %   - The number of columns in total
            lineRanges = XLSFile.splitRange(subs{1});
            columnRanges = XLSFile.splitRange(subs{2});

            ranges = struct('excel', nan(size(lineRanges, 2)*size(columnRanges, 2), 1), ...
                            'rows',  nan(size(lineRanges, 2)*size(columnRanges, 2), 1), ...
                            'cols',  nan(size(lineRanges, 2)*size(columnRanges, 2), 1));

            r = 1;
            for lineRange = lineRanges
                for columnRange = columnRanges
                    ranges(r).excel = XLSFile.toXLSRange({lineRange.excel, columnRange.excel});
                    ranges(r).rows = lineRange.matlab;
                    ranges(r).cols = columnRange.matlab;

                    r = r + 1;
                end
            end

            varargout = {ranges};
            if (nargout >= 2)
                varargout = [varargout, {sum(arrayfun(@(r) size(r.matlab, 2), lineRanges))}];
            end
            if (nargout >= 3)
                varargout = [varargout, {sum(arrayfun(@(r) size(r.matlab, 2), columnRanges))}];
            end
        end
        function ranges = splitRange(subs)
        % @brief Split the subs into connected ranges
        %
        % Split the give MATLAB subs structure into connected ranges
        % @param subs Indexes from MATLAB subs array (see MATLAB help on subsref and subsasgn)
        % @return Connected ranges as structure with the following fields:
        %   - **excel** Line or column number in Excel
        %   - **matlab** Line or column number in the MATLAB array
            b = 1;
            ranges = struct('excel', {}, 'matlab', {});
            for i = 1:size(subs, 2)
                if ((i == size(subs, 2)) || (subs(i) ~= subs(i + 1) - 1))
                    range.excel = subs(b):subs(i);
                    range.matlab = b:i;
                    ranges = [ranges, range]; %#ok<AGROW> No way to forecast

                    b = i + 1;
                end
            end
        end
        function range = toXLSRange(subs)
        % @brief Convert a MATLAB range into an Excel range
        %
        % Convert a connected MATLAB range into an Excel range (in the
        % format [A-Z]+[1-9][0-9]* or [A-Z]+[1-9][0-9]*:[A-Z]+[1-9][0-9]*
        % @param subs Connected range indexes in MATLAB
        % @return Excel range
            if ((length(subs{1}) == 1) && (length(subs{2}) == 1))
                range = [XLSFile.toXLSColumn(subs{2}), XLSFile.toXLSLine(subs{1})];
            else
                range = [XLSFile.toXLSColumn(min(subs{2})), XLSFile.toXLSLine(min(subs{1})), ':', XLSFile.toXLSColumn(max(subs{2})), XLSFile.toXLSLine(max(subs{1})),];
            end
        end
    end

    methods(Access=private)
        function setupExcel(self)
        % @brief Initialize Excel
        %
        % Initialize the COM connection to Excel
            if isempty(self.mExcel)
                % Get an ActiveX handle to excel
                self.mExcel = actxserver('Excel.Application');
                %file.mExcel.visible = false;
                self.mExcel.DisplayAlerts = false;
            end
        end
        function sheet = getSheet(self, name)
        % @brief Get a sheet by name
        %
        % Return the first sheet matching the given name
        % @param name The name of the desired sheet
        % @return A COM object representing the Excel sheet
            sheet = [];
            if ~isempty(self.mWorkBook)
                sheets = self.mWorkBook.Sheets;
                for s = 1:sheets.Count
                    if strcmp(sheets.Item(s).Name, name)
                        sheet = sheets.Item(s);
                    end
                end
            end
        end
    end
end