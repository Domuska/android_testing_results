# benchmark.psm1
# Exports: Benchmark-Command

function bm-notes-instrumentation ([ScriptBlock]$Expression, [int]$Samples = 1, [string]$testName) {
<#
.SYNOPSIS
  Runs the given script block and returns the execution duration.
  Hat tip to StackOverflow. http://stackoverflow.com/questions/3513650-a-commands-execution-in-powershell
  
  Remember to do dotexe stuff before running the test script:
  . "C:\Users\Tomi\testAutomation\measurements\wikipedia\benchmark_notes.ps1"
  
  
.EXAMPLE
  bm-notes-instrumentation { gradle connectedAlphaDebugAndroidTest --stacktrace } 1 espresso_tests
  
  Output files will be following:
	-file_path
		-testName-run_start_time
			-gradle_report_folder
				-run_number_1
				-run_number_2
				...
				-run_number_samples
			-full_file_path.txt
			-full_file_path.csv
#>

  echo "STARTING NOTES TESTING, USING TEST SUITE $testName"
  #tag name, used at start of result file name and as git branch
  $test_name = $testName
  
  #the script output file path
  $file_path = "c:\users\Tomi\testAutomation\measurements\notes\"
  $project_path = "C:\Users\Tomi\Projects\notepad_own_fork\NotePad\"
  $test_report_path = "app\build\reports\androidTests\connected\flavors\FREE"
  $gradle_report_folder = "gradle_reports"
  $runs_total = $Samples
  
  #run number, incremented later
  [int]$Run = 1
  
  $Start_time = Get-Date -f yyy_MM_dd-HH_mm_ss
  #the raw file path, no extension example : uiautomator_tests-2016_08_22-11_00_31
  $filename = "$test_name-$(get-date -f yyy_MM_dd-HH_mm_ss)"
  #echo $filename
  #in current directory
  $full_file_path_txt = "$file_path$filename\$filename.txt"
  $full_file_path_csv = "$file_path$filename\$filename.csv"
  #echo $full_file_path_txt
  
  #create a new directory with the name 
  New-Item "$file_path$filename" -type directory
  
  #navigate to the application folder
  cd $project_path
  git checkout $test_name
  #gradle assembleAlphaDebug
  "NOTES TEST RUN REPORT, branch $test_name`n`n" | Out-File "$($full_file_path_txt)" -Append
  #headers for the csv
  "runNumber;runTime;failures;totalRunTime" | Out-File "$($full_file_path_csv)" -Append -Encoding ascii
  
  #start the test runs
  do {
	#create new stopwatch to record time the test takes
    $sw = New-Object Diagnostics.Stopwatch
	$sw.Start()
	echo "starting test suite run number $Run / $runs_total"
	$printout = & $Expression 2>&1
	
    $sw.Stop()
	
	#write results to human-readable .txt
    "run number: $Run" | Out-File "$($full_file_path_txt)" -Append
    "run time:  $($sw.Elapsed.TotalSeconds)" | Out-File "$($full_file_path_txt)" -Append
	"Command printout: " | Out-File "$($full_file_path_txt)" -Append
    $($printout) | Out-File "$($full_file_path_txt)" -Append
	"`n######################################################`n" | Out-File "$($full_file_path_txt)" -Append 
	
	
	#use pup program (credit to https://github.com/ericchiang/pup) to get execution time from gradle test report
	$runTime = pup -f "$($project_path)$($test_report_path)\index.html" '.infoBox[id=\"duration\"] .counter text{}'
	$failures = pup -f "$($project_path)$($test_report_path)\index.html" '.infoBox[id=\"failures\"] .counter text{}'
	#write to .csv that has ; as separator between fields
	"$($Run);$($runTime);$($failures);$($sw.Elapsed.TotalSeconds)" | Out-File "$($full_file_path_csv)" -Append -Encoding ascii
	
	echo "copying gradle output file"
	xcopy "$($project_path)$($test_report_path)" "$($file_path)\$($filename)\$($gradle_report_folder)\$($Run)" /E /C /H /R /K /O /Y /i
	#copy the xml output
	xcopy "$($project_path)app\build\outputs\androidTest-results\connected\flavors\ALPHA" "$($file_path)\$($filename)\$($gradle_report_folder)\$($Run)\xml" /E /C /H /R /K /O /Y /i
	
    $sw.Reset()
    $Samples--
    $Run++
  }
  while ($Samples -gt 0)
  $End_time = Get-Date -f yyy_MM_dd-HH_mm_ss
  #navigate back to the test result folder
  cd $file_path
  
  echo "Adding files to git"
  #add the file to git, push with comment
  git add $filename
  git commit -m "results from $test_name - $Start_time to $End_time"
  git push
}

function bm-notes-appium([ScriptBlock]$Expression, [int]$Samples = 1, [string]$testName) {
<#
.SYNOPSIS
  Runs the given script block and returns the execution duration.
  Hat tip to StackOverflow. http://stackoverflow.com/questions/3513650-a-commands-execution-in-powershell
  
  Remember to do dotexe stuff before running the test script:
  . "C:\Users\Tomi\testAutomation\measurements\wikipedia\benchmark_notes.ps1"
  
  
.EXAMPLE
  bm-notes-appium { gradle testAlphaDebugUnitTest } 1 appium_tests
  
  Output files will be following:
	-file_path
		-testName-run_start_time
			-gradle_report_folder
				-run_number_1
				-run_number_2
				...
				-run_number_samples
			-full_file_path.txt
			-full_file_path.csv
#>

  echo "STARTING NOTES TESTING, USING TEST SUITE $testName"
  #tag name, used at start of result file name and as git branch
  $test_name = $testName
  
  #the script output file path
  $file_path = "c:\users\Tomi\testAutomation\measurements\notes\"
  $project_path = "C:\Users\Tomi\Projects\notepad_own_fork\NotePad\"
  $test_report_path = "app\build\reports\tests\freeDebug"
  $gradle_report_folder = "gradle_reports"
  $runs_total = $Samples
  
  #run number, incremented later
  [int]$Run = 1
  
  $Start_time = Get-Date -f yyy_MM_dd-HH_mm_ss
  #the raw file path, no extension example : uiautomator_tests-2016_08_22-11_00_31
  $filename = "$test_name-$(get-date -f yyy_MM_dd-HH_mm_ss)"
  #echo $filename
  #in current directory
  $full_file_path_txt = "$file_path$filename\$filename.txt"
  $full_file_path_csv = "$file_path$filename\$filename.csv"
  #echo $full_file_path_txt
  
  #create a new directory with the name 
  New-Item "$file_path$filename" -type directory
  
  #navigate to the application folder
  cd $project_path
  git checkout $test_name
  "NOTES TEST RUN REPORT, branch $test_name`n`n" | Out-File "$($full_file_path_txt)" -Append
  #headers for the csv
  "runNumber;runTime;failures;totalRunTime" | Out-File "$($full_file_path_csv)" -Append -Encoding ascii
  
  #start the test runs
  do {
	#create new stopwatch to record time the whole test execution takes
    $sw = New-Object Diagnostics.Stopwatch
	$sw.Start()
	echo "running gradle clean"
	gradle clean

	echo "starting test suite run number $Run / $runs_total"
    $printout = & $Expression 2>&1
    $sw.Stop()
	
	#write results to human-readable .txt
    "run number: $Run" | Out-File "$($full_file_path_txt)" -Append
    "run time:  $($sw.Elapsed.TotalSeconds)" | Out-File "$($full_file_path_txt)" -Append
	"Command printout: " | Out-File "$($full_file_path_txt)" -Append
    $($printout) | Out-File "$($full_file_path_txt)" -Append
	"`n######################################################`n" | Out-File "$($full_file_path_txt)" -Append 
	
	
	#use pup program (credit to https://github.com/ericchiang/pup) to get execution time from gradle test report
	$runTime = pup -f "$($project_path)$($test_report_path)\index.html" '.infoBox[id=\"duration\"] .counter text{}'
	$failures = pup -f "$($project_path)$($test_report_path)\index.html" '.infoBox[id=\"failures\"] .counter text{}'
	#write run number, test execution time, failures, total elapsed time to .csv that has ; as separator between fields
	"$($Run);$($runTime);$($failures);$($sw.Elapsed.TotalSeconds)" | Out-File "$($full_file_path_csv)" -Append -Encoding ascii

	echo "copying gradle output file"
	xcopy "$($project_path)$($test_report_path)" "$($file_path)\$($filename)\$($gradle_report_folder)\$($Run)" /E /C /H /R /K /O /Y /i
	#copy the xml output
	xcopy "$($project_path)app\build\test-results\freeDebug" "$($file_path)\$($filename)\$($gradle_report_folder)\$($Run)\xml" /E /C /H /R /K /O /Y /i
	
    $sw.Reset()
    $Samples--
    $Run++
  }
  while ($Samples -gt 0)
  $End_time = Get-Date -f yyy_MM_dd-HH_mm_ss
  #navigate back to the test result folder
  cd $file_path
  
  echo "Adding files to git"
  #add the file to git, push with comment
  git add $filename
  git commit -m "results from $test_name - $Start_time to $End_time"
  git push
}