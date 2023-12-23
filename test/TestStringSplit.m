classdef TestStringSplit < matlab.unittest.TestCase
    properties(TestParameter)
        dataTest = {                                                                ...
            struct('string', {''},      'delim', ' ', 'result', {{''}}           ); ...
            struct('string', {'1'},     'delim', ' ', 'result', {{'1'}}          ); ...
            struct('string', {'11'},    'delim', ' ', 'result', {{'11'}}         ); ...
            struct('string', {'1 2'},   'delim', ' ', 'result', {{'1'; '2'}}     ); ...
            struct('string', {'1 2 3'}, 'delim', ' ', 'result', {{'1'; '2'; '3'}}); ...
            struct('string', {'11 2'},  'delim', ' ', 'result', {{'11'; '2'}}    ); ...
            struct('string', {'1 22'},  'delim', ' ', 'result', {{'1'; '22'}}    ); ...
            struct('string', {'1  2'},  'delim', ' ', 'result', {{'1'; ''; '2'}} ); ...
            struct('string', {''},      'delim', ',', 'result', {{''}}           ); ...
            struct('string', {'1'},     'delim', ',', 'result', {{'1'}}          ); ...
            struct('string', {'11'},    'delim', ',', 'result', {{'11'}}         ); ...
            struct('string', {'1,2'},   'delim', ',', 'result', {{'1'; '2'}}     ); ...
            struct('string', {'1,2,3'}, 'delim', ',', 'result', {{'1'; '2'; '3'}}); ...
            struct('string', {'11,2'},  'delim', ',', 'result', {{'11'; '2'}}    ); ...
            struct('string', {'1,22'},  'delim', ',', 'result', {{'1'; '22'}}    ); ...
            struct('string', {'1,,2'},  'delim', ',', 'result', {{'1'; ''; '2'}} ); ...
        }
    end

    properties(Access=private)
        mBasePath;
    end

    methods(TestClassSetup)
        function setupPath(self)
            self.mBasePath = fileparts(fileparts(mfilename('fullpath')));
            addpath(self.mBasePath);
            rehash;
        end
    end

    methods(Test)
        function testSuccess(self, dataTest)
            self.verifyEqual(stringSplit(dataTest.string, dataTest.delim), dataTest.result);
        end
        function testErrorDouble(self)
            self.verifyError(@() stringSplit(1, ','), 'StringSplit:InvalidArgument');
        end
        function testErrorDoubleArray(self)
            self.verifyError(@() stringSplit([1, 2, 3], ','), 'StringSplit:InvalidArgument');
        end
        function testErrorDelimiterDouble(self)
            self.verifyError(@() stringSplit('123', 2), 'StringSplit:InvalidArgument');
        end
        function testErrorDelimiterTooLong(self)
            self.verifyError(@() stringSplit('1, 2', ', '), 'StringSplit:InvalidArgument');
        end
    end

    methods(TestClassTeardown)
        function teardownPath(self)
            rmpath(self.mBasePath);
            rehash;
        end
    end
end