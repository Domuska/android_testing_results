# benchmark.psm1
# Exports: Benchmark-Command

function bm-wikipedia-instrumentation ([ScriptBlock]$Expression, [int]$Samples = 1, [string]$testName) {
<#
.SYNOPSIS
  Runs the given script block and returns the execution duration.
  Hat tip to StackOverflow. http://stackoverflow.com/questions/3513650-a-commands-execution-in-powershell
  
  Remember to do dotexe stuff before running the test script:
  . "C:\Users\Tomi\testAutomation\measurements\wikipedia\benchmark_wikipedia.ps1"
  
  
.EXAMPLE
  Benchmark-Command-Wikipedia { gradle connectedAlphaDebugAndroidTest --stacktrace } 1 espresso_tests
  
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

  echo "STARTING WIKIPEDIA TESTING, USING TEST SUITE $testName"
  #tag name, used at start of result file name and as git branch
  $test_name = $testName
  
  #the script output file path
  $file_path = "c:\users\Tomi\testAutomation\measurements\wikipedia\"
  $project_path = "C:\Users\Tomi\Projects\wikipedia_3\apps-android-wikipedia\"
  $gradle_report_folder = "gradle_reports"
  
  #run number, incremented later
  [int]$Run = 1
  
  $Start_time = Get-Date -f yyy_MM_dd-hh_mm_ss
  #the raw file path, no extension
  $filename = "$test_name-$(get-date -f yyy_MM_dd-hh_mm_ss)"
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
  "WIKIPEDIA TEST RUN REPORT, branch $test_name`n`n" | Out-File "$($full_file_path_txt)" -Append
  #headers for the csv
  "runNumber;runTime;failures;totalRunTime" | Out-File "$($full_file_path_csv)" -Append -Encoding ascii
  
  #start the test runs
  do {
	#create new stopwatch to record time the test takes
    $sw = New-Object Diagnostics.Stopwatch
	$sw.Start()
	echo "running gradle clean"
	gradle clean
	echo "starting test suite run number $Run / $Samples"
    $printout = & $Expression 2>&1
    $sw.Stop()
	
	#write results to human-readable .txt
    "run number: $Run" | Out-File "$($full_file_path_txt)" -Append
    "run time:  $($sw.Elapsed.TotalSeconds)" | Out-File "$($full_file_path_txt)" -Append
	"Command printout: " | Out-File "$($full_file_path_txt)" -Append
    $($printout) | Out-File "$($full_file_path_txt)" -Append
	"`n######################################################`n" | Out-File "$($full_file_path_txt)" -Append 
	
	#write to .csv that has ; as separator between fields
	#"$($Run);$($sw.Elapsed.TotalSeconds);$($printout)" | Out-File "$($full_file_path_csv)" -Append -Encoding ascii
	#use pup program (credit to https://github.com/ericchiang/pup) to get execution time from gradle test report
	$runTime = pup -f "$($project_path)\app\build\reports\androidTests\connected\flavors\PLAY\index.html" '.infoBox[id=\"duration\"] .counter text{}'
	$failures = pup -f "$($project_path)\app\build\reports\androidTests\connected\flavors\PLAY\index.html" '.infoBox[id=\"failures\"] .counter text{}'
	"$($Run);$($runTime);$($failures);$($sw.Elapsed.TotalSeconds)" | Out-File "$($full_file_path_csv)" -Append -Encoding ascii
	
	echo "copying gradle output file"
	xcopy "$($project_path)\app\build\reports\androidTests\connected\flavors\ALPHA" "$($file_path)\$($filename)\$($gradle_report_folder)\$($Run)" /E /C /H /R /K /O /Y /i
	
    $sw.Reset()
    $Samples--
    $Run++
  }
  while ($Samples -gt 0)
  $End_time = Get-Date -f yyy_MM_dd-hh_mm_ss
  #navigate back to the test result folder
  cd $file_path
  
  echo "Adding files to git"
  #add the file to git, push with comment
  git add $filename
  git commit -m "results from $test_name - $Start_time to $End_time"
  git push
}

function bm-wikipedia-appium([ScriptBlock]$Expression, [int]$Samples = 1, [string]$testName) {
<#
.SYNOPSIS
  Runs the given script block and returns the execution duration.
  Hat tip to StackOverflow. http://stackoverflow.com/questions/3513650-a-commands-execution-in-powershell
  
  Remember to do dotexe stuff before running the test script:
  . "C:\Users\Tomi\testAutomation\measurements\wikipedia\benchmark_wikipedia.ps1"
  
  
.EXAMPLE
  bm-wikipedia-appium { gradle testAlphaDebugUnitTest } 1 appium_tests
  
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

  echo "STARTING WIKIPEDIA TESTING, USING TEST SUITE $testName"
  #tag name, used at start of result file name and as git branch
  $test_name = $testName
  
  #the script output file path
  $file_path = "c:\users\Tomi\testAutomation\measurements\wikipedia\"
  $project_path = "C:\Users\Tomi\Projects\wikipedia_3\apps-android-wikipedia\"
  $gradle_report_folder = "gradle_reports"
  
  #run number, incremented later
  [int]$Run = 1
  
  $Start_time = Get-Date -f yyy_MM_dd-hh_mm_ss
  #the raw file path, no extension
  $filename = "$test_name-$(get-date -f yyy_MM_dd-hh_mm_ss)"
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
  "WIKIPEDIA TEST RUN REPORT, branch $test_name`n`n" | Out-File "$($full_file_path_txt)" -Append
  #headers for the csv
  "runNumber;runTime;failures;totalRunTime" | Out-File "$($full_file_path_csv)" -Append -Encoding ascii
  
  #start the test runs
  do {
	#create new stopwatch to record time the whole test execution takes
    $sw = New-Object Diagnostics.Stopwatch
	$sw.Start()
	echo "running gradle clean"
	gradle clean

	echo "starting test suite run number $Run / $Samples"
    $printout = & $Expression 2>&1
    $sw.Stop()
	
	#write results to human-readable .txt
    "run number: $Run" | Out-File "$($full_file_path_txt)" -Append
    "run time:  $($sw.Elapsed.TotalSeconds)" | Out-File "$($full_file_path_txt)" -Append
	"Command printout: " | Out-File "$($full_file_path_txt)" -Append
    $($printout) | Out-File "$($full_file_path_txt)" -Append
	"`n######################################################`n" | Out-File "$($full_file_path_txt)" -Append 
	
	#write run number, test execution time to .csv that has ; as separator between fields
	#"$($Run);$($sw.Elapsed.TotalSeconds);$($printout)" | Out-File "$($full_file_path_csv)" -Append -Encoding ascii
	#use pup program (credit to https://github.com/ericchiang/pup) to get execution time from gradle test report
	$runTime = pup -f "$($project_path)\build\reports\tests\playDebug\index.html" '.infoBox[id=\"duration\"] .counter text{}'
	$failures = pup -f "$($project_path)\build\reports\tests\playDebug\index.html" '.infoBox[id=\"failures\"] .counter text{}'
	"$($Run);$($runTime);$($failures);$($sw.Elapsed.TotalSeconds)" | Out-File "$($full_file_path_csv)" -Append -Encoding ascii

	echo "copying gradle output file"
	xcopy "$($project_path)\app\build\reports\tests\alphaDebug" "$($file_path)\$($filename)\$($gradle_report_folder)\$($Run)" /E /C /H /R /K /O /Y /i
	
    $sw.Reset()
    $Samples--
    $Run++
  }
  while ($Samples -gt 0)
  $End_time = Get-Date -f yyy_MM_dd-hh_mm_ss
  #navigate back to the test result folder
  cd $file_path
  
  echo "Adding files to git"
  #add the file to git, push with comment
  git add $filename
  git commit -m "results from $test_name - $Start_time to $End_time"
  git push
}