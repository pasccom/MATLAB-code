classdef TestIff < matlab.unittest.TestCase
    properties(TestParameter)
        dataTypes = struct(                                                                         ...
            'double',  struct('OK',              1, 'KO',              2, 'default',            0), ...
            'single',  struct('OK',      single(1), 'KO',      single(2), 'default',    single(0)), ...
            'logical', struct('OK',           true, 'KO',          false, 'default',        false), ...
            'int8',    struct('OK',        int8(1), 'KO',        int8(2), 'default',      int8(0)), ...
            'uint8',   struct('OK',       uint8(1), 'KO',       uint8(2), 'default',     uint8(0)), ...
            'int16',   struct('OK',       int16(1), 'KO',       int16(2), 'default',     int16(0)), ...
            'uint16',  struct('OK',      uint16(1), 'KO',      uint16(2), 'default',    uint16(0)), ...
            'int32',   struct('OK',       int32(1), 'KO',       int32(2), 'default',     int32(0)), ...
            'uint32',  struct('OK',      uint32(1), 'KO',      uint32(2), 'default',    uint32(0)), ...
            'int64',   struct('OK',       int64(1), 'KO',       int64(2), 'default',     int64(0)), ...
            'uint64',  struct('OK',      uint64(1), 'KO',      uint64(2), 'default',    uint64(0))  ...
        );
        dataSpecial = struct(                                                                       ...
            'char',    struct('OK',         'true', 'KO',        'false', 'default',           ''), ...
            'cell',    struct('OK',          {{1}}, 'KO',          {{2}}, 'default', {cell(1, 1)}), ...
            'struct',  struct('OK', struct('f', 1), 'KO', struct('F', 2), 'default',     struct())  ...
        );
        dataSize = struct(      ...
            'S1x2',      [1, 2], ...
            'S2x1',      [2, 1], ...
            'S2x2',      [2, 2], ...
            'S1x1x2', [1, 1, 2], ...
            'S2x2x2', [2, 2, 2]  ...
        );
    end

    properties(Access=private)
        mBasePath
    end

    methods(TestClassSetup)
        function setupPath(self)
            self.mBasePath = fileparts(fileparts(mfilename('fullpath')));
            addpath(self.mBasePath);
            rehash;
        end
    end

    methods(Test, ParameterCombination='pairwise')
        function testScalarTrueTwoArgs(self, dataTypes)
            self.verifyEqual(iff(true, dataTypes.OK), dataTypes.OK);
        end
        function testScalarFalseTwoArgs(self, dataTypes)
            self.verifyEqual(iff(false, dataTypes.OK), dataTypes.default);
        end
        function testScalarTrueThreeArgs(self, dataTypes)
            self.verifyEqual(iff(true, dataTypes.OK, dataTypes.KO), dataTypes.OK);
        end
        function testScalarFalseThreeArgs(self, dataTypes)
            self.verifyEqual(iff(false, dataTypes.OK, dataTypes.KO), dataTypes.KO);
        end
        function testSpecialTrueTwoArgs(self, dataSpecial)
            self.verifyEqual(iff(true, dataSpecial.OK), dataSpecial.OK);
        end
        function testSpecialFalseTwoArgs(self, dataSpecial)
            self.verifyEqual(iff(false, dataSpecial.OK), dataSpecial.default);
        end
        function testSpecialTrueThreeArgs(self, dataSpecial)
            self.verifyEqual(iff(true, dataSpecial.OK, dataSpecial.KO), dataSpecial.OK);
        end
        function testSpecialFalseThreeArgs(self, dataSpecial)
            self.verifyEqual(iff(false, dataSpecial.OK, dataSpecial.KO), dataSpecial.KO);
        end
        function testFunctionTrueTwoArgs(self)
            fun = iff(true, @() 1);
            self.verifyEqual(fun(), 1);
        end
        function testFunctionFalseTwoArgs(self)
            fun = iff(false, @() 1);
            self.verifyEqual(fun(), 0);
        end
        function testFunctionTrueThreeArgs(self)
            fun = iff(true, @() 1, @() 2);
            self.verifyEqual(fun(), 1);
        end
        function testFunctionFalseThreeArgs(self)
            fun = iff(false, @() 1, @() 2);
            self.verifyEqual(fun(), 2);
        end
        function testMatrixTrueTwoArgs(self, dataTypes, dataSize)
            self.verifyEqual(iff(true, repmat(dataTypes.OK, dataSize)), repmat(dataTypes.OK, dataSize));
        end
        function testMatrixFalseTwoArgs(self, dataTypes, dataSize)
            self.verifyEqual(iff(false, repmat(dataTypes.OK, dataSize)), repmat(dataTypes.default, dataSize));
        end
        function testMatrixTrueThreeArgs(self, dataTypes, dataSize)
            self.verifyEqual(iff(true, repmat(dataTypes.OK, dataSize), repmat(dataTypes.KO, dataSize)), repmat(dataTypes.OK, dataSize));
        end
        function testMatrixFalseThreeArgs(self, dataTypes, dataSize)
            self.verifyEqual(iff(false, repmat(dataTypes.OK, dataSize), repmat(dataTypes.KO, dataSize)), repmat(dataTypes.KO, dataSize));
        end
        function testUnsupported(self)
            self.verifyWarning(@() self.verifyEqual(iff(false, self), []), 'iff:TypeUnsupported');
        end
        function testErrorTooFewArgs(self)
            self.verifyError(@() iff(true), 'iff:BadArgumentNumber');
        end
        function testErrorTooManyArgs(self)
            self.verifyError(@() iff(true, 1, 0, 'test'), 'iff:BadArgumentNumber');
        end
    end

    methods(TestClassTeardown)
        function teardownPath(self)
            rmpath(self.mBasePath);
            rehash;
        end
    end
end

