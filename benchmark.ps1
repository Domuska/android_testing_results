# benchmark.psm1
# Exports: Benchmark-Command

function Benchmark-Command ([ScriptBlock]$Expression, [int]$Samples = 1) {
<#
.SYNOPSIS
  Runs the given script block and returns the execution duration.
  Hat tip to StackOverflow. http://stackoverflow.com/questions/3513650-a-commands-execution-in-powershell
  
  Remember to do dotexe stuff before running the test script:
  . "C:\Users\Tomi\testAutomation\measurements\benchmark.ps1"
  
  
.EXAMPLE
  Benchmark-Command { ping -n 1 google.com } 3
#>

  #tag name, used at start of result file name and as git branch
  $test_name = "espresso_tests"
  
  #the script output file path
  $file_path = "c:\users\Tomi\testAutomation\measurements\"
  
  #run number, incremented later
  [int]$Run = 1
  
  $Start_time = Get-Date -f yyy-MM-dd_hh_mm_ss
  #the raw file path, no extension
  $filename = "$test_name-$(get-date -f yyy-MM-dd_hh_mm_ss)"
  #echo $filename
  #in current directory
  $full_file_path_txt = "$file_path$filename\$filename.txt"
  $full_file_path_csv = "$file_path$filename\$filename.csv"
  #echo $full_file_path_txt
  
  #create a new directory with the name 
  New-Item "$file_path$filename" -type directory
  
  #navigate to the application folder
  cd c:\users\Tomi\Projects\amazeFileManager\AmazeFileManager  
  git checkout $test_name
  gradle compilePlayDebugSources
  
  #start the test runs
  do {
	#install application and run uiautomator script to grant permissions before testing
	gradle installPlayDebug
	adb shell am instrument -w -e class com.amaze.filemanager.test.PermissionGranter com.amaze.filemanager.test/android.support.test.runner.AndroidJUnitRunner
	
    $sw = New-Object Diagnostics.Stopwatch
    $sw.Start()
    $printout = & $Expression 2>&1
    $sw.Stop()
	#write to human-readable .txt
    "run number: $Run" | Out-File "$($full_file_path_txt)" -Append
    "run time:  $($sw.Elapsed.TotalSeconds)" | Out-File "$($full_file_path_txt)" -Append
	"Command printout: " | Out-File "$($full_file_path_txt)" -Append
    $($printout) | Out-File "$($full_file_path_txt)" -Append
	"`n######################################################`n" | Out-File "$($full_file_path_txt)" -Append 
	
	#write to .csv that has ; as separator between fields
	"$($Run);$($sw.Elapsed.TotalSeconds);$($printout)" | Out-File "$($full_file_path_csv)" -Append -Encoding ascii
	
    $sw.Reset()
    $Samples--
    $Run++
  }
  while ($Samples -gt 0)
  $End_time = Get-Date -f yyy-MM-dd_hh_mm_ss
  #navigate back to the test result folder
  cd $file_path
  #add the file to git, push with comment
  #git add $filename
  #git commit -m "results from $test_name - $Start_time to $End_time"
  #git push
}

#Export-ModuleMember Benchmark-Command