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
  bm-wikipedia-instrumentation { gradle connectedAlphaDebugAndroidTest --stacktrace } 1 espresso_tests
  
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
  $file_path = "c:\users\Tomi\testAutomation\measurements\wikipedia\wifi\"
  $project_path = "C:\Users\Tomi\Projects\wikipedia_3\apps-android-wikipedia\"
  $test_report_path = "app\build\reports\androidTests\connected\flavors\ALPHA"
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
  $full_file_path_test_failures_csv = "$($file_path)$($filename)\$($filename)_failures.csv"
  
  #create a new directory with the name 
  New-Item "$file_path$filename" -type directory
  
  #navigate to the application folder
  cd $project_path
  git checkout $test_name
  #gradle assembleAlphaDebug
  "WIKIPEDIA TEST RUN REPORT, branch $test_name`n`n" | Out-File "$($full_file_path_txt)" -Append
  #headers for the csv
  "runNumber;runTime_seconds;tests;failures;totalRunTime_seconds" | Out-File "$($full_file_path_csv)" -Append -Encoding ascii
  #headers to failure .csv
  "runNumber;failingTestName" | Out-File "$($full_file_path_test_failures_csv)" -Append -Encoding ascii
  
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
	
	#write to .csv that has ; as separator between fields
	#"$($Run);$($sw.Elapsed.TotalSeconds);$($printout)" | Out-File "$($full_file_path_csv)" -Append -Encoding ascii
	#use pup program (credit to https://github.com/ericchiang/pup) to get execution time from gradle test report
	$runTime = pup -f "$($project_path)$($test_report_path)\index.html" '.infoBox[id=\"duration\"] .counter text{}'
	
	#convert runTime from m_ss_msms format to seconds
	$mPosition = $runTime.IndexOf("m")
	[int]$minutes = $runtime.Substring(0, $mPosition)
	$seconds = $minutes*60
	$runTime = $runTime -replace "$($minutes)m", ""
	$runTime = $runTime -replace "s", ""
	$runTime = [double]$runTime
	$runTime += $seconds
	
	[int]$tests = pup -f "$($project_path)$($test_report_path)\index.html" '.infoBox[id=\"tests\"] .counter text{}'
	[int]$failures = pup -f "$($project_path)$($test_report_path)\index.html" '.infoBox[id=\"failures\"] .counter text{}'
	"$($Run);$($runTime);$($tests);$($failures);$($sw.Elapsed.TotalSeconds)" | Out-File "$($full_file_path_csv)" -Append -Encoding ascii
	
	if($failures -gt 0){
		#in failed_classes_tests text is in format
		#classname
		#testname
		#exclude "org", it's in full package name of the app and fields having that are extra fields we dont need
		$failed_classes_tests = pup -f "$($project_path)$($test_report_path)\index.html" '.failures a:not(:contains(\"org\")) text{}'
		#convert the variable to a string
		$failed_classes_tests = "$failed_classes_tests"
		
		#take all but last error class.failingTests and write to .csv
		for($i=1; $i -le $failures-1; $i++){
				
			#get position of the 2nd space so we get substring until that point
			$1_space_position = $failed_classes_tests.IndexOf(" ")
			$2_space_position = $failed_classes_tests.IndexOf(" ", $1_space_position+1)
			#get the substring, remove it from the full name
			$testName = $failed_classes_tests.Substring(0, $2_space_position)
			$failed_classes_tests = $failed_classes_tests -replace "$($testName) "
			
			#replace the space with .
			$testName = $testName -replace " ", "."
			"$($Run);$($testName)" | Out-File "$($full_file_path_test_failures_csv)" -Append -Encoding ascii
			
		}
		#handle taking the very last error class.failingTest
		$testName = $failed_classes_tests -replace " ", "."
		"$($Run);$($testName)" | Out-File "$($full_file_path_test_failures_csv)" -Append -Encoding ascii
	}
	
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
  $file_path = "c:\users\Tomi\testAutomation\measurements\wikipedia\wifi\"
  $project_path = "C:\Users\Tomi\Projects\wikipedia_3\apps-android-wikipedia\"
  $test_report_path = "app\build\reports\tests\alphaDebug"
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
  $full_file_path_test_failures_csv = "$($file_path)$($filename)\$($filename)_failures.csv"
  #echo $full_file_path_txt
  
  #create a new directory with the name 
  New-Item "$file_path$filename" -type directory
  
  #navigate to the application folder
  cd $project_path
  git checkout $test_name
  "WIKIPEDIA TEST RUN REPORT, branch $test_name`n`n" | Out-File "$($full_file_path_txt)" -Append
  #headers for the csv
  "runNumber;runTime_seconds;tests;failures;totalRunTime_seconds" | Out-File "$($full_file_path_csv)" -Append -Encoding ascii
  #headers to failure .csv
  "runNumber;failingTestName" | Out-File "$($full_file_path_test_failures_csv)" -Append -Encoding ascii
  
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
	
	#convert runTime from m_ss_msms format to seconds
	$mPosition = $runTime.IndexOf("m")
	[int]$minutes = $runtime.Substring(0, $mPosition)
	$seconds = $minutes*60
	$runTime = $runTime -replace "$($minutes)m", ""
	$runTime = $runTime -replace "s", ""
	$runTime = [double]$runTime
	$runTime += $seconds
	
	[int]$tests = pup -f "$($project_path)$($test_report_path)\index.html" '.infoBox[id=\"tests\"] .counter text{}'
	$failures = pup -f "$($project_path)$($test_report_path)\index.html" '.infoBox[id=\"failures\"] .counter text{}'
	"$($Run);$($runTime);$($tests);$($failures);$($sw.Elapsed.TotalSeconds)" | Out-File "$($full_file_path_csv)" -Append -Encoding ascii
	
	if($failures -gt 0){
		#write to another .csv names of the tests that failures
		for($i=1; $i -le $failures; $i++){
			$h2Text = pup -f "$($project_path)$($test_report_path)\index.html" '.tab[id=\"tab0\""] h2 text{}'
			#parse the html in project_path\app\build\outputs\androidTest-results...\index.html, get package name & test name
			#.tab class with id tab0 (could be "ignored" or "passed", but failures is checked above in for loop) .linklist class li element child number FAILURE_NUMBER, a element child 1 for package, 2 for test name
			$testPackageName = pup -f "$($project_path)$($test_report_path)\index.html" ".tab[id=`"tab0`"] .linkList li:nth-child($i) a:nth-child(1) text{}"
			$testName = pup -f "$($project_path)$($test_report_path)\index.html" ".tab[id=`"tab0`"] .linkList li:nth-child($i) a:nth-child(2) text{}"
			"$($Run);$($testPackageName).$($testName)" | Out-File "$($full_file_path_test_failures_csv)" -Append -Encoding ascii
		}
	}

	echo "copying gradle output file"
	xcopy "$($project_path)$($test_report_path)" "$($file_path)\$($filename)\$($gradle_report_folder)\$($Run)" /E /C /H /R /K /O /Y /i
	#copy the xml output
	xcopy "$($project_path)app\build\test-results\alphaDebug" "$($file_path)\$($filename)\$($gradle_report_folder)\$($Run)\xml" /E /C /H /R /K /O /Y /i
	
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