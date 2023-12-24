classdef TestFullPath < matlab.unittest.TestCase
    properties(TestParameter)
        dataTest = {                                                                                                          ...
            {fullfile(''),                 fullfile('.'),                           fullfile('')                           }; ...
            {fullfile(''),                 fullfile('file0'),                       fullfile('file0')                      }; ...
            {fullfile(''),                 fullfile('file.0'),                      fullfile('file.0')                     }; ...
            {fullfile(''),                 fullfile('dir1'),                        fullfile('dir1')                       }; ...
            {fullfile(''),                 fullfile('dir1', 'file1') ,              fullfile('dir1', 'file1')              }; ...
            {fullfile(''),                 fullfile('dir1', 'file.1'),              fullfile('dir1', 'file.1')             }; ...
            {fullfile(''),                 fullfile('dir1', '.'),                   fullfile('dir1')                       }; ...
            {fullfile(''),                 fullfile('dir1', 'subdir11', 'file11'),  fullfile('dir1', 'subdir11', 'file11') }; ...
            {fullfile(''),                 fullfile('dir1', 'subdir11', 'file.11'), fullfile('dir1', 'subdir11', 'file.11')}; ...
            {fullfile(''),                 fullfile('dir1', 'subdir11'),            fullfile('dir1', 'subdir11')           }; ...
            {fullfile('dir1'),             fullfile('file1'),                       fullfile('dir1', 'file1')              }; ...
            {fullfile('dir1'),             fullfile('file.1'),                      fullfile('dir1', 'file.1')             }; ...
            {fullfile('dir1'),             fullfile('.'),                           fullfile('dir1')                       }; ...
            {fullfile('dir1'),             fullfile('..', 'file0'),                 fullfile('file0')                      }; ...
            {fullfile('dir1'),             fullfile('..', 'file.0'),                fullfile('file.0')                     }; ...
            {fullfile('dir1'),             fullfile('..'),                          fullfile('')                           }; ...
            {fullfile('dir1'),             fullfile('subdir11'),                    fullfile('dir1', 'subdir11')           }; ...
            {fullfile('dir1'),             fullfile('subdir11', 'file11'),          fullfile('dir1', 'subdir11', 'file11') }; ...
            {fullfile('dir1'),             fullfile('subdir11', 'file.11'),         fullfile('dir1', 'subdir11', 'file.11')}; ...
            {fullfile('dir1'),             fullfile('subdir11', '.'),               fullfile('dir1', 'subdir11')           }; ...
            {fullfile('dir1', 'subdir11'), fullfile('file11'),                      fullfile('dir1', 'subdir11', 'file11') }; ...
            {fullfile('dir1', 'subdir11'), fullfile('file.11'),                     fullfile('dir1', 'subdir11', 'file.11')}; ...
            {fullfile('dir1', 'subdir11'), fullfile('.'),                           fullfile('dir1', 'subdir11')           }; ...
            {fullfile('dir1', 'subdir11'), fullfile('..', 'file1'),                 fullfile('dir1', 'file1')              }; ...
            {fullfile('dir1', 'subdir11'), fullfile('..', 'file.1'),                fullfile('dir1', 'file.1')             }; ...
            {fullfile('dir1', 'subdir11'), fullfile('..'),                          fullfile('dir1')                       }; ...
            {fullfile('dir1', 'subdir11'), fullfile('..', '..', 'file0'),           fullfile('file0')                      }; ...
            {fullfile('dir1', 'subdir11'), fullfile('..', '..', 'file.0'),          fullfile('file.0')                     }; ...
            {fullfile('dir1', 'subdir11'), fullfile('..', '..'),                    fullfile('')                           }; ...
        };
    end
    properties(Access=private)
        mBasePath;
        mTestRoot;
        mOldPwd;
    end

    methods(TestClassSetup)
        function setupTestTree(self)
            self.mTestRoot = fullfile(tempdir, 'TestFullPath');
            self.fatalAssertTrue(mkdir(self.mTestRoot));
            self.fatalAssertTrue(mkdir(fullfile(self.mTestRoot, 'dir1')));
            self.fatalAssertTrue(mkdir(fullfile(self.mTestRoot, 'dir1', 'subdir11')));

            fId = fopen(fullfile(self.mTestRoot, 'file0'), 'w');
            self.fatalAssertNotEqual(fId, -1);
            self.fatalAssertEqual(fprintf(fId, '0\n'), 2);
            self.fatalAssertEqual(fclose(fId), 0);

            fId = fopen(fullfile(self.mTestRoot, 'dir1', 'file1'), 'w');
            self.fatalAssertNotEqual(fId, -1);
            self.fatalAssertEqual(fprintf(fId, '1\n'), 2);
            self.fatalAssertEqual(fclose(fId), 0);

            fId = fopen(fullfile(self.mTestRoot, 'dir1', 'subdir11', 'file11'), 'w');
            self.fatalAssertNotEqual(fId, -1);
            self.fatalAssertEqual(fprintf(fId, '11\n'), 3);
            self.fatalAssertEqual(fclose(fId), 0);

            fId = fopen(fullfile(self.mTestRoot, 'file.0'), 'w');
            self.fatalAssertNotEqual(fId, -1);
            self.fatalAssertEqual(fprintf(fId, '0\n'), 2);
            self.fatalAssertEqual(fclose(fId), 0);

            fId = fopen(fullfile(self.mTestRoot, 'dir1', 'file.1'), 'w');
            self.fatalAssertNotEqual(fId, -1);
            self.fatalAssertEqual(fprintf(fId, '1\n'), 2);
            self.fatalAssertEqual(fclose(fId), 0);

            fId = fopen(fullfile(self.mTestRoot, 'dir1', 'subdir11', 'file.11'), 'w');
            self.fatalAssertNotEqual(fId, -1);
            self.fatalAssertEqual(fprintf(fId, '11\n'), 3);
            self.fatalAssertEqual(fclose(fId), 0);

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
    end

    methods(Test)
        function test(self, dataTest)
            basePath = fullfile(self.mTestRoot, dataTest{1});
            self.assumeEqual(exist(basePath, 'dir'), 7);

            absPath = fullfile(self.mTestRoot, dataTest{3});
            self.assumeNotEqual(exist(absPath), 0);

            cd(basePath);
            self.verifyEqual(fullpath(dataTest{2}), absPath);
        end
    end

    methods(TestClassTeardown)
        function deleteTestTree(self)
            delete(fullfile(self.mTestRoot, 'file0'));
            delete(fullfile(self.mTestRoot, 'file.0'));
            delete(fullfile(self.mTestRoot, 'dir1', 'file1'));
            delete(fullfile(self.mTestRoot, 'dir1', 'file.1'));
            delete(fullfile(self.mTestRoot, 'dir1', 'subdir11', 'file11'));
            delete(fullfile(self.mTestRoot, 'dir1', 'subdir11', 'file.11'));
            rmdir(fullfile(self.mTestRoot, 'dir1', 'subdir11'));
            rmdir(fullfile(self.mTestRoot, 'dir1'));
            rmdir(self.mTestRoot);
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

