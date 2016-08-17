# benchmark.psm1

#function for running the instrumented android tests

function bm-amaze-instrumentation ([ScriptBlock]$Expression, [int]$Samples = 1, [string]$testName) {
<#
.SYNOPSIS
  Runs the given script block and returns the execution duration.
  Hat tip to StackOverflow. http://stackoverflow.com/questions/3513650-a-commands-execution-in-powershell
  
  Remember to do dotexe stuff before running the test script:
  . "C:\Users\Tomi\testAutomation\measurements\amaze\benchmark.ps1"
  
  
.EXAMPLE
  bm-amaze-instrumentation { gradle connectedPlayDebugAndroidTest --stacktrace } 3 espresso_tests
  
  Output files will be following:
	-file_path
		-testName-run_start_time
			-gradle_report_folder
			-full_file_path.txt
			-full_file_path.csv
#>

  echo "STARTING AMAZE TESTING, USING TEST SUITE $testName"
  #tag name, used at start of result file name and as git branch
  $test_name = $testName
  
  #the script output file path
  $file_path = "c:\users\Tomi\testAutomation\measurements\amaze\"
  $project_path = "C:\users\Tomi\Projects\amazeFileManager\AmazeFileManager\"
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
  #gradle compilePlayDebugSources
  gradle assemblePlayDebug
  "AMAZE TEST RUN REPORT`n`n" | Out-File "$($full_file_path_txt)" -Append
  
  #start the test runs
  do {
	# install application and run uiautomator script to grant permissions before testing
	# we have to install it like this for some reason, if it is installed just by gradle installPlayDebug, it is
	# not shown up in instrumentation for some reason, and we can't run the last command to actually run the automation script
	echo "installing play-debug.apk, androidTest.apk"
	adb push C:\Users\Tomi\Projects\amazeFileManager\AmazeFileManager\build\outputs\apk\AmazeFileManager-play-debug.apk /data/local/tmp/com.amaze.filemanager
	adb shell pm install -r "/data/local/tmp/com.amaze.filemanager"
	adb push C:\Users\Tomi\Projects\amazeFileManager\AmazeFileManager\build\outputs\apk\AmazeFileManager-play-debug-androidTest-unaligned.apk /data/local/tmp/com.amaze.filemanager.test
	adb shell pm install -r "/data/local/tmp/com.amaze.filemanager.test"
	echo "running test granter uiautomator script"
	adb shell am instrument -w -e class com.amaze.filemanager.test.PermissionGranter com.amaze.filemanager.test/android.support.test.runner.AndroidJUnitRunner
	
	#create new stopwatch to record time the test takes
    $sw = New-Object Diagnostics.Stopwatch

	echo "starting test suite run number $Run"
    $sw.Start()
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
	$runTime = pup -f "$($project_path)\build\reports\androidTests\connected\flavors\PLAY\index.html" '.counter:contains(\"s\") text{}'
	"$($Run);$($runTime)" | Out-File "$($full_file_path_csv)" -Append -Encoding ascii
	
	echo "copying gradle output file"
	#copy the html document
	xcopy "$($project_path)\build\reports\androidTests\connected\flavors\PLAY" "$($file_path)\$($filename)\$($gradle_report_folder)\$($Run)" /E /C /H /R /K /O /Y /i
	#copy the xml output
	xcopy "$($project_path)\build\outputs\androidTest-results\connected\flavors\PLAY" "$($file_path)\$($filename)\$($gradle_report_folder)\$($Run)\xml" /E /C /H /R /K /O /Y /i
	
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


#function for running the tests with Appium
function bm-amaze-appium ([ScriptBlock]$Expression, [int]$Samples = 1, [string]$testName) {
<#
.SYNOPSIS
  Runs the given script block and returns the execution duration.
  Hat tip to StackOverflow. http://stackoverflow.com/questions/3513650-a-commands-execution-in-powershell
  
  Remember to do dotexe stuff before running the test script:
  . "C:\Users\Tomi\testAutomation\measurements\benchmark.ps1"
  
  
.EXAMPLE
  bm-amaze-appium { gradle testPlayDebugUnitTest } 3 appium_tests
  
  Output files will be following:
	-file_path
		-testName-run_start_time
			-gradle_report_folder
			-full_file_path.txt
			-full_file_path.csv
#>

  echo "STARTING AMAZE TESTING, USING TEST SUITE $testName"
  #tag name, used at start of result file name and as git branch
  $test_name = $testName
  
  #the script output file path
  $file_path = "c:\users\Tomi\testAutomation\measurements\amaze\"
  $project_path = "C:\users\Tomi\Projects\amazeFileManager\AmazeFileManager\"
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
  gradle compilePlayDebugSources
  "AMAZE TEST RUN REPORT`n`n" | Out-File "$($full_file_path_txt)" -Append
  
  #start the test runs
  do {
	# install application and run uiautomator script to grant permissions before testing
	# we have to install it like this for some reason, if it is installed just by gradle installPlayDebug, it is
	# not shown up in instrumentation for some reason, and we can't run the last command to actually run the automation script
	echo "installing play-debug.apk, androidTest.apk"
	adb push C:\Users\Tomi\Projects\amazeFileManager\AmazeFileManager\build\outputs\apk\AmazeFileManager-play-debug.apk /data/local/tmp/com.amaze.filemanager
	adb shell pm install -r "/data/local/tmp/com.amaze.filemanager"
	adb push C:\Users\Tomi\Projects\amazeFileManager\AmazeFileManager\build\outputs\apk\AmazeFileManager-play-debug-androidTest-unaligned.apk /data/local/tmp/com.amaze.filemanager.test
	adb shell pm install -r "/data/local/tmp/com.amaze.filemanager.test"
	echo "running test granter uiautomator script"
	adb shell am instrument -w -e class com.amaze.filemanager.test.PermissionGranter com.amaze.filemanager.test/android.support.test.runner.AndroidJUnitRunner
	
	echo "running gradle clean"
	gradle clean
	
	#create new stopwatch to record time the test takes
    $sw = New-Object Diagnostics.Stopwatch
	#run the tests
	echo "starting test suite run number $Run"
    $sw.Start()
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
	$runTime = pup -f "$($project_path)\build\reports\tests\playDebug\index.html" '.counter:contains(\"s\") text{}'
	"$($Run);$($runTime)" | Out-File "$($full_file_path_csv)" -Append -Encoding ascii
	
	echo "copying gradle output file"
	xcopy "$($project_path)\build\reports\tests\playDebug" "$($file_path)\$($filename)\$($gradle_report_folder)\$($Run)" /E /C /H /R /K /O /Y /i
	#copy the xml output
	xcopy "$($project_path)\build\test-results\playDebug" "$($file_path)\$($filename)\$($gradle_report_folder)\$($Run)\xml" /E /C /H /R /K /O /Y /i
	
	#C:\Users\Tomi\Projects\amazeFileManager\AmazeFileManager\build\test-results\playDebug
	
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