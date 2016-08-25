We will test many things. Oh yes.

Running the script:

1) check that the file path to the output folder is correct in the test script
2) check that the application's source folder is correct in the test script (should point to root of the project, some projects might have an app folder that needs to be taken care of when supplying file path to the gradle reports)
3) ensure pup (https://github.com/ericchiang/pup) is on your machine and the .exe is included in the PATH (used for gathering run times, failures, failed test names from the gradle output)
4) ensure all Android specific stuff works, gradle is in your path and so on
5) open up powershell (most likely have to open it as administrator) and do dotsource thing mentioned in the test script
6) run the test script using the example command in the test script
7) check results in the output folder, it should have 2 .csv files, a .txt file and folder containing gradle reports for each test run

