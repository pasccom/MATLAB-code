classdef TestChdir < matlab.unittest.TestCase
    properties(TestParameter)
        dataSingle = {                   ...
            fullfile('dir1');            ...
            fullfile('dir1', 'subdir11') ...
        };
        dataSingleNonExisting = {
            fullfile('dir3');            ...
            fullfile('dir1', 'subdir13') ...
        }
        dataMultipleAbsolute = {                                          ...
            {fullfile('dir1'),             fullfile('dir1', 'subdir11')}; ...
            {fullfile('dir1'),             fullfile('dir2')            }; ...
            {fullfile('dir1'),             fullfile('dir2', 'subdir21')}; ...
            {fullfile('dir1', 'subdir11'), fullfile('dir1')            }; ...
            {fullfile('dir1', 'subdir11'), fullfile('dir1', 'subdir12')}; ...
            {fullfile('dir1', 'subdir11'), fullfile('dir2', 'subdir22')}; ...
        };
        dataMultipleRelative = {                                                                                    ...
            {fullfile('dir1'),             fullfile('dir1', 'subdir11'), fullfile('subdir11')                    }; ...
            {fullfile('dir1'),             fullfile('dir2'),             fullfile('..', 'dir2')                  }; ...
            {fullfile('dir1'),             fullfile('dir2', 'subdir21'), fullfile('..', 'dir2', 'subdir21')      }; ...
            {fullfile('dir1', 'subdir11'), fullfile('dir1'),             fullfile('..')                          }; ...
            {fullfile('dir1', 'subdir11'), fullfile('dir1', 'subdir12'), fullfile('..', 'subdir12')              }; ...
            {fullfile('dir1', 'subdir11'), fullfile('dir2', 'subdir22'), fullfile('..', '..', 'dir2', 'subdir22')}; ...
        };
    end
    properties(Access=private)
        mBasePath;
        mTestRoot;
        mOldPwd;
    end

    methods(TestClassSetup)
        function setupTestTree(self)
            self.mTestRoot = fullfile(tempdir, 'TestChdir');
            self.fatalAssertTrue(mkdir(self.mTestRoot));
            self.fatalAssertTrue(mkdir(fullfile(self.mTestRoot, 'dir1')));
            self.fatalAssertTrue(mkdir(fullfile(self.mTestRoot, 'dir1', 'subdir11')));
            self.fatalAssertTrue(mkdir(fullfile(self.mTestRoot, 'dir1', 'subdir12')));
            self.fatalAssertTrue(mkdir(fullfile(self.mTestRoot, 'dir2')));
            self.fatalAssertTrue(mkdir(fullfile(self.mTestRoot, 'dir2', 'subdir21')));
            self.fatalAssertTrue(mkdir(fullfile(self.mTestRoot, 'dir2', 'subdir22')));
        end
        function setupPath(self)
            self.mBasePath = fileparts(fileparts(mfilename('fullpath')));
            addpath(self.mBasePath);
            rehash;
        end
        function savePwd(self)
            self.mOldPwd = pwd;
        end
    end

    methods(TestMethodSetup)
        function setPwd(self)
            cd(self.mOldPwd);
        end
        function clearChdir(self)
            clear chdir
        end
    end

    methods(Test)
        function testSingle(self, dataSingle)
            path = fullfile(self.mTestRoot, dataSingle);
            self.assumeEqual(exist(path, 'dir'), 7);

            self.assumeEqual(pwd, self.mOldPwd);
            self.assumeEqual(chdir('', 'Debug'), {});

            eval(sprintf('chdir %s', path));
            self.verifyEqual(pwd, path);
            self.verifyEqual(chdir('', 'Debug'), {self.mOldPwd});

            chdir -
            self.verifyEqual(pwd, self.mOldPwd);
            self.verifyEqual(chdir('', 'Debug'), {});
        end
        function testFunctionSingle(self, dataSingle)
            path = fullfile(self.mTestRoot, dataSingle);
            self.assumeEqual(exist(path, 'dir'), 7);

            self.assumeEqual(pwd, self.mOldPwd);
            self.assumeEqual(chdir('', 'Debug'), {});

            chdir(path);
            self.verifyEqual(pwd, path);
            self.verifyEqual(chdir('', 'Debug'), {self.mOldPwd});

            chdir('-');
            self.verifyEqual(pwd, self.mOldPwd);
            self.verifyEqual(chdir('', 'Debug'), {});
        end
        function testSingleNonExisting(self, dataSingleNonExisting)
            path = fullfile(self.mTestRoot, dataSingleNonExisting);
            self.assumeEqual(exist(path, 'dir'), 0);

            self.assumeEqual(pwd, self.mOldPwd);
            self.assumeEqual(chdir('', 'Debug'), {});

            self.verifyError(@() eval(sprintf('chdir %s', path)), 'chdir:NonExistentFolder');
            self.verifyEqual(pwd, self.mOldPwd);
            self.verifyEqual(chdir('', 'Debug'), {});

            function testSingleNonExistingPrivate()
                chdir -
            end
            self.verifyWarning(@testSingleNonExistingPrivate, 'chdir:NoHistory');
            self.verifyEqual(pwd, self.mOldPwd);
            self.verifyEqual(chdir('', 'Debug'), {});
        end
        function testFunctionSingleNonExisting(self, dataSingleNonExisting)
            path = fullfile(self.mTestRoot, dataSingleNonExisting);
            self.assumeEqual(exist(path, 'dir'), 0);

            self.assumeEqual(pwd, self.mOldPwd);
            self.assumeEqual(chdir('', 'Debug'), {});

            self.verifyError(@() chdir(path), 'chdir:NonExistentFolder');
            self.verifyEqual(pwd, self.mOldPwd);
            self.verifyEqual(chdir('', 'Debug'), {});

            self.verifyWarning(@() chdir('-'), 'chdir:NoHistory');
            self.verifyEqual(pwd, self.mOldPwd);
            self.verifyEqual(chdir('', 'Debug'), {});
        end
        function testMultipleAbsolute(self, dataMultipleAbsolute)
            path1 = fullfile(self.mTestRoot, dataMultipleAbsolute{1});
            self.assumeEqual(exist(path1, 'dir'), 7);

            self.assumeEqual(pwd, self.mOldPwd);
            self.assumeEqual(chdir('', 'Debug'), {});

            eval(sprintf('chdir %s', path1));
            self.verifyEqual(pwd, path1);
            self.verifyEqual(chdir('', 'Debug'), {self.mOldPwd});

            path2 = fullfile(self.mTestRoot, dataMultipleAbsolute{2});
            self.assumeEqual(exist(path2, 'dir'), 7);

            eval(sprintf('chdir %s', path2));
            self.verifyEqual(pwd, path2);
            self.verifyEqual(chdir('', 'Debug'), {self.mOldPwd, path1});

            chdir -
            self.verifyEqual(pwd, path1);
            self.verifyEqual(chdir('', 'Debug'), {self.mOldPwd});

            chdir -
            self.verifyEqual(pwd, self.mOldPwd);
            self.verifyEqual(chdir('', 'Debug'), {});
        end
        function testFunctionMultipleAbsolute(self, dataMultipleAbsolute)
            path1 = fullfile(self.mTestRoot, dataMultipleAbsolute{1});
            self.assumeEqual(exist(path1, 'dir'), 7);

            self.assumeEqual(pwd, self.mOldPwd);
            self.assumeEqual(chdir('', 'Debug'), {});

            chdir(path1);
            self.verifyEqual(pwd, path1);
            self.verifyEqual(chdir('', 'Debug'), {self.mOldPwd});

            path2 = fullfile(self.mTestRoot, dataMultipleAbsolute{2});
            self.assumeEqual(exist(path2, 'dir'), 7);

            chdir(path2);
            self.verifyEqual(pwd, path2);
            self.verifyEqual(chdir('', 'Debug'), {self.mOldPwd, path1});

            chdir('-');
            self.verifyEqual(pwd, path1);
            self.verifyEqual(chdir('', 'Debug'), {self.mOldPwd});

            chdir('-');
            self.verifyEqual(pwd, self.mOldPwd);
            self.verifyEqual(chdir('', 'Debug'), {});
        end
        function testMultipleRelative(self, dataMultipleRelative)
            path1 = fullfile(self.mTestRoot, dataMultipleRelative{1});
            self.assumeEqual(exist(path1, 'dir'), 7);

            self.assumeEqual(pwd, self.mOldPwd);
            self.assumeEqual(chdir('', 'Debug'), {});

            eval(sprintf('chdir %s', path1));
            self.verifyEqual(pwd, path1);
            self.verifyEqual(chdir('', 'Debug'), {self.mOldPwd});

            path2 = fullfile(self.mTestRoot, dataMultipleRelative{2});
            self.assumeEqual(exist(path2, 'dir'), 7);

            eval(sprintf('chdir %s', dataMultipleRelative{3}));
            self.verifyEqual(pwd, path2);
            self.verifyEqual(chdir('', 'Debug'), {self.mOldPwd, path1});

            chdir -
            self.verifyEqual(pwd, path1);
            self.verifyEqual(chdir('', 'Debug'), {self.mOldPwd});

            chdir -
            self.verifyEqual(pwd, self.mOldPwd);
            self.verifyEqual(chdir('', 'Debug'), {});
        end
        function testFunctionMultipleRelative(self, dataMultipleRelative)
            path1 = fullfile(self.mTestRoot, dataMultipleRelative{1});
            self.assumeEqual(exist(path1, 'dir'), 7);

            self.assumeEqual(pwd, self.mOldPwd);
            self.assumeEqual(chdir('', 'Debug'), {});

            chdir(path1);
            self.verifyEqual(pwd, path1);
            self.verifyEqual(chdir('', 'Debug'), {self.mOldPwd});

            path2 = fullfile(self.mTestRoot, dataMultipleRelative{2});
            self.assumeEqual(exist(path2, 'dir'), 7);

            chdir(dataMultipleRelative{3});
            self.verifyEqual(pwd, path2);
            self.verifyEqual(chdir('', 'Debug'), {self.mOldPwd, path1});

            chdir('-');
            self.verifyEqual(pwd, path1);
            self.verifyEqual(chdir('', 'Debug'), {self.mOldPwd});

            chdir('-');
            self.verifyEqual(pwd, self.mOldPwd);
            self.verifyEqual(chdir('', 'Debug'), {});
        end
        function testSame(self, dataSingle)
            path = fullfile(self.mTestRoot, dataSingle);
            self.assumeEqual(exist(path, 'dir'), 7);

            self.assumeEqual(pwd, self.mOldPwd);
            self.assumeEqual(chdir('', 'Debug'), {});

            eval(sprintf('chdir %s', path));
            self.verifyEqual(pwd, path);
            self.verifyEqual(chdir('', 'Debug'), {self.mOldPwd});

            eval(sprintf('chdir %s', path));
            self.verifyEqual(pwd, path);
            self.verifyEqual(chdir('', 'Debug'), {self.mOldPwd});

            chdir -
            self.verifyEqual(pwd, self.mOldPwd);
            self.verifyEqual(chdir('', 'Debug'), {});

            function testSamePrivate()
                chdir -
            end
            self.verifyWarning(@testSamePrivate, 'chdir:NoHistory');
            self.verifyEqual(pwd, self.mOldPwd);
            self.verifyEqual(chdir('', 'Debug'), {});
        end
        function testFunctionSame(self, dataSingle)
            path = fullfile(self.mTestRoot, dataSingle);
            self.assumeEqual(exist(path, 'dir'), 7);

            self.assumeEqual(pwd, self.mOldPwd);
            self.assumeEqual(chdir('', 'Debug'), {});

            chdir(path);
            self.verifyEqual(pwd, path);
            self.verifyEqual(chdir('', 'Debug'), {self.mOldPwd});

            chdir(path);
            self.verifyEqual(pwd, path);
            self.verifyEqual(chdir('', 'Debug'), {self.mOldPwd});

            chdir('-');
            self.verifyEqual(pwd, self.mOldPwd);
            self.verifyEqual(chdir('', 'Debug'), {});

            self.verifyWarning(@() chdir('-'), 'chdir:NoHistory');
            self.verifyEqual(pwd, self.mOldPwd);
            self.verifyEqual(chdir('', 'Debug'), {});
        end
        function testDot(self, dataSingle)
            path = fullfile(self.mTestRoot, dataSingle);
            self.assumeEqual(exist(path, 'dir'), 7);

            self.assumeEqual(pwd, self.mOldPwd);
            self.assumeEqual(chdir('', 'Debug'), {});

            eval(sprintf('chdir %s', path));
            self.verifyEqual(pwd, path);
            self.verifyEqual(chdir('', 'Debug'), {self.mOldPwd});

            chdir .
            self.verifyEqual(pwd, path);
            self.verifyEqual(chdir('', 'Debug'), {self.mOldPwd});

            chdir -
            self.verifyEqual(pwd, self.mOldPwd);
            self.verifyEqual(chdir('', 'Debug'), {});

            function testSamePrivate()
                chdir -
            end
            self.verifyWarning(@testSamePrivate, 'chdir:NoHistory');
            self.verifyEqual(pwd, self.mOldPwd);
            self.verifyEqual(chdir('', 'Debug'), {});
        end
        function testFunctionDot(self, dataSingle)
            path = fullfile(self.mTestRoot, dataSingle);
            self.assumeEqual(exist(path, 'dir'), 7);

            self.assumeEqual(pwd, self.mOldPwd);
            self.assumeEqual(chdir('', 'Debug'), {});

            chdir(path);
            self.verifyEqual(pwd, path);
            self.verifyEqual(chdir('', 'Debug'), {self.mOldPwd});

            chdir('.');
            self.verifyEqual(pwd, path);
            self.verifyEqual(chdir('', 'Debug'), {self.mOldPwd});

            chdir('-');
            self.verifyEqual(pwd, self.mOldPwd);
            self.verifyEqual(chdir('', 'Debug'), {});

            self.verifyWarning(@() chdir('-'), 'chdir:NoHistory');
            self.verifyEqual(pwd, self.mOldPwd);
            self.verifyEqual(chdir('', 'Debug'), {});
        end
        function test0Args(self)
            self.verifyError(@() chdir, 'chdir:BadArgumentNumber');
            self.verifyEqual(pwd, self.mOldPwd);
            self.verifyEqual(chdir('', 'Debug'), {});
        end
        function test2Args(self, dataSingle)
            path = fullfile(self.mTestRoot, dataSingle);
            self.assumeEqual(exist(path, 'dir'), 7);

            self.verifyError(@() eval(sprintf('chdir %s Test', path)), 'chdir:BadArgumentNumber');
            self.verifyEqual(pwd, self.mOldPwd);
            self.verifyEqual(chdir('', 'Debug'), {});
        end
        function testFunction2Args(self, dataSingle)
            path = fullfile(self.mTestRoot, dataSingle);
            self.assumeEqual(exist(path, 'dir'), 7);

            self.verifyError(@() chdir(path,'Test'), 'chdir:BadArgumentNumber');
            self.verifyEqual(pwd, self.mOldPwd);
            self.verifyEqual(chdir('', 'Debug'), {});
        end
        function testOutput(self, dataSingle)
            path = fullfile(self.mTestRoot, dataSingle);
            self.assumeEqual(exist(path, 'dir'), 7);

            function testOutputPrivate()
                test = chdir(path);
            end
            self.verifyError(@testOutputPrivate, 'chdir:BadArgumentNumber');
            self.verifyEqual(pwd, self.mOldPwd);
            self.verifyEqual(chdir('', 'Debug'), {});
        end
    end

    methods(TestClassTeardown)
        function deleteTestTree(self)
            self.fatalAssertTrue(rmdir(fullfile(self.mTestRoot, 'dir1', 'subdir11')));
            self.fatalAssertTrue(rmdir(fullfile(self.mTestRoot, 'dir1', 'subdir12')));
            self.fatalAssertTrue(rmdir(fullfile(self.mTestRoot, 'dir1')));
            self.fatalAssertTrue(rmdir(fullfile(self.mTestRoot, 'dir2', 'subdir21')));
            self.fatalAssertTrue(rmdir(fullfile(self.mTestRoot, 'dir2', 'subdir22')));
            self.fatalAssertTrue(rmdir(fullfile(self.mTestRoot, 'dir2')));
            self.fatalAssertTrue(rmdir(self.mTestRoot));
        end
        function teardownPath(self)
            rmpath(self.mBasePath);
            rehash;
        end
        function resetPwd(self)
            cd(self.mOldPwd);
        end
    end
end

