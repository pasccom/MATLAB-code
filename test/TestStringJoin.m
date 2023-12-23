classdef TestStringJoin < matlab.unittest.TestCase
    properties(TestParameter)
        dataNoGlue = {                                               ...
            struct('strings', {{'1'}},           'result', {'1'}  ); ...
            struct('strings', {{'1', '2'}},      'result', {'12'} ); ...
            struct('strings', {{'1', '2', '3'}}, 'result', {'123'}); ...
            struct('strings', {{'11', '2'}},     'result', {'112'}); ...
            struct('strings', {{'1', '22'}},     'result', {'122'})  ...
        }
        dataGlue = {                                                                   ...
            struct('strings', {{'1'}},           'glue', '',   'result', {'1'}      ); ...
            struct('strings', {{'1', '2'}},      'glue', '',   'result', {'12'}     ); ...
            struct('strings', {{'1', '2', '3'}}, 'glue', '',   'result', {'123'}    ); ...
            struct('strings', {{'11', '2'}},     'glue', '',   'result', {'112'}    ); ...
            struct('strings', {{'1', '22'}},     'glue', '',   'result', {'122'}    ); ...
            struct('strings', {{'1'}},           'glue', ' ',  'result', {'1'}      ); ...
            struct('strings', {{'1', '2'}},      'glue', ' ',  'result', {'1 2'}    ); ...
            struct('strings', {{'1', '2', '3'}}, 'glue', ' ',  'result', {'1 2 3'}  ); ...
            struct('strings', {{'11', '2'}},     'glue', ' ',  'result', {'11 2'}   ); ...
            struct('strings', {{'1', '22'}},     'glue', ' ',  'result', {'1 22'}   ); ...
            struct('strings', {{'1'}},           'glue', ',',  'result', {'1'}      ); ...
            struct('strings', {{'1', '2'}},      'glue', ',',  'result', {'1,2'}    ); ...
            struct('strings', {{'1', '2', '3'}}, 'glue', ',',  'result', {'1,2,3'}  ); ...
            struct('strings', {{'11', '2'}},     'glue', ',',  'result', {'11,2'}   ); ...
            struct('strings', {{'1', '22'}},     'glue', ',',  'result', {'1,22'}   ); ...
            struct('strings', {{'1'}},           'glue', '  ', 'result', {'1'}      ); ...
            struct('strings', {{'1', '2'}},      'glue', '  ', 'result', {'1  2'}   ); ...
            struct('strings', {{'1', '2', '3'}}, 'glue', '  ', 'result', {'1  2  3'}); ...
            struct('strings', {{'11', '2'}},     'glue', '  ', 'result', {'11  2'}  ); ...
            struct('strings', {{'1', '22'}},     'glue', '  ', 'result', {'1  22'}  ); ...
        }
        glue = {'', ' ', ',', '  '};
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
        function testNoGlue(self, dataNoGlue)
            self.verifyEqual(stringJoin(dataNoGlue.strings), dataNoGlue.result);
        end
        function testGlue(self, dataGlue)
            self.verifyEqual(stringJoin(dataGlue.strings, dataGlue.glue), dataGlue.result);
        end
        function testEmpty(self)
            self.verifyEqual(stringJoin({}), '');
        end
        function testEmptyGlue(self, glue)
            self.verifyEqual(stringJoin({}, glue), '');
        end
        function testChar(self)
            self.verifyEqual(stringJoin('a'), 'a');
        end
        function testCharGlue(self, glue)
            self.verifyEqual(stringJoin('a', glue), 'a');
        end
        function testErrorSquare(self)
            self.verifyError(@() stringJoin({'11', '12'; '21', '22'}), 'StringJoin:InvalidArgument');
        end
        function testErrorDouble(self)
            self.verifyError(@() stringJoin(1), 'StringJoin:InvalidArgument');
        end
        function testErrorDoubleArray(self)
            self.verifyError(@() stringJoin([1, 2, 3]), 'StringJoin:InvalidArgument');
        end
        function testErrorDoubleCell(self)
            self.verifyError(@() stringJoin({1, 2, 3}), 'StringJoin:InvalidArgument');
        end
        function testErrorGlue(self)
            self.verifyError(@() stringJoin('a', 1), 'StringJoin:InvalidArgument');
        end
    end

    methods(TestClassTeardown)
        function teardownPath(self)
            rmpath(self.mBasePath);
            rehash;
        end
    end
end