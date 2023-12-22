classdef TestTaskList < matlab.unittest.TestCase
    properties(TestParameter)
        filterName  = {'ImageName',   'PID', 'SessionName', 'SessionNumber', 'State',   'WindowTitle'                    }
        filterValue = {'svchost.exe',  0,    'Services',     0,              'Running', ['MATLAB R', version('-release')]}
    end

    properties(Access=private)
        mBasePath
        mNoDetailFields = {'ImageName', 'PID', 'SessionName', 'SessionNumber', 'Memory'}
        mDetailFields = {'State', 'UserName', 'CpuTime', 'WindowTitle'}
    end

    methods(TestClassSetup)
        function setupPath(self)
            self.mBasePath = fileparts(fileparts(mfilename('fullpath')));
            addpath(self.mBasePath);
            rehash;
        end
    end

    methods(Test, ParameterCombination='sequential')
        function testDefault(self)
            tasks = taskList();
            self.verifyClass(tasks, 'struct');
            self.verifyEqual(size(tasks, 2), 1);
            for field = self.mNoDetailFields
                self.verifyTrue(isfield(tasks, field{:}));
            end
            for field = self.mDetailFields
                self.verifyFalse(isfield(tasks, field{:}));
            end
        end
        function testDetail(self)
            tasks = taskList(true);
            self.verifyClass(tasks, 'struct');
            self.verifyEqual(size(tasks, 2), 1);
            for field = [self.mNoDetailFields, self.mDetailFields]
                self.verifyTrue(isfield(tasks, field{:}));
            end
        end
        function testNoDetail(self)
            tasks = taskList(false);
            self.verifyClass(tasks, 'struct');
            self.verifyEqual(size(tasks, 2), 1);
            for field = self.mNoDetailFields
                self.verifyTrue(isfield(tasks, field{:}));
            end
            for field = self.mDetailFields
                self.verifyFalse(isfield(tasks, field{:}));
            end
        end
        function testDetailBasicFilter(self)
            tasks = taskList(true, 'svchost.exe');
            self.verifyClass(tasks, 'struct');
            self.verifyEqual(size(tasks, 2), 1);
            for field = transpose(fieldnames(tasks))
                self.verifyTrue(any(strcmp(field{:}, [self.mNoDetailFields, self.mDetailFields])));
            end
        end
        function testNoDetailBasicFilter(self)
            tasks = taskList(false, 'svchost.exe');
            self.verifyClass(tasks, 'struct');
            self.verifyEqual(size(tasks, 2), 1);
            for field = transpose(fieldnames(tasks))
                self.verifyTrue(any(strcmp(field{:}, self.mNoDetailFields)));
            end
        end
        function testDetailFilter(self, filterName, filterValue)
            tasks = taskList(true, filterName, filterValue);
            self.verifyClass(tasks, 'struct');
            self.verifyEqual(size(tasks, 2), 1);
            for field = transpose(fieldnames(tasks))
                self.verifyTrue(any(strcmp(field{:}, [self.mNoDetailFields, self.mDetailFields])));
            end
        end
        function testNoDetailFilter(self, filterName, filterValue)
            tasks = taskList(false, filterName, filterValue);
            self.verifyClass(tasks, 'struct');
            self.verifyEqual(size(tasks, 2), 1);
            for field = transpose(fieldnames(tasks))
                self.verifyTrue(any(strcmp(field{:}, self.mNoDetailFields)));
            end
        end
        function testDetailFilterSingleMatch(self)
            tasks = taskList(true, 'tasklist.exe');
            self.verifyClass(tasks, 'struct');
            self.verifyEqual(size(tasks), [1, 1]);
            for field = transpose(fieldnames(tasks))
                self.verifyTrue(any(strcmp(field{:}, [self.mNoDetailFields, self.mDetailFields])));
            end
        end
        function testNoDetailFilterSingleMatch(self)
            tasks = taskList(false, 'tasklist.exe');
            self.verifyClass(tasks, 'struct');
            self.verifyEqual(size(tasks), [1, 1]);
            for field = transpose(fieldnames(tasks))
                self.verifyTrue(any(strcmp(field{:}, self.mNoDetailFields)));
            end
        end
        function testDetailFilterNoMatch(self)
            tasks = taskList(true, 'NonExistingValue');
            self.verifyClass(tasks, 'struct');
            self.verifyEmpty(tasks);
        end
        function testNoDetailFilterNoMatch(self)
            tasks = taskList(false, 'NonExistingValue');
            self.verifyClass(tasks, 'struct');
            self.verifyEmpty(tasks);
        end
        function testDetailFilterError(self)
            self.verifyError(@() taskList(true, 'BadFilter', 'svchost.exe'), 'taskList:FilterError');
        end
        function testNoDetailFilterError(self)
            self.verifyError(@() taskList(false, 'BadFilter', 'svchost.exe'), 'taskList:FilterError');
        end
    end

    methods(TestClassTeardown)
        function teardownPath(self)
            rmpath(self.mBasePath);
            rehash;
        end
    end
end