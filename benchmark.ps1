# benchmark.psm1
# Exports: Benchmark-Command

function Benchmark-Command ([ScriptBlock]$Expression, [int]$Samples = 1) {
<#
.SYNOPSIS
  Runs the given script block and returns the execution duration.
  Hat tip to StackOverflow. http://stackoverflow.com/questions/3513650-a-commands-execution-in-powershell
  
  Remember to do dotexe stuff before running the test script:
  . "path_to_this_script"
  
.EXAMPLE
  Benchmark-Command { ping -n 1 google.com } 3
#>
  #change file tag name below, it is added to beginning of file name
  $test_name = "uiautomator_amaze"
  $file_path = "c:\users\Tomi\testAutomation\measurements\"
  [int]$Run = 1
  $Start_time = Get-Date
  $filename = "$test_name-$(get-date -f yyy-MM-dd_hh_mm_ss).txt"
  #echo $filename
  $full_file_path = "$file_path$filename"
  #echo $full_file_path
  New-Item $full_file_path
  
  do {
    $sw = New-Object Diagnostics.Stopwatch
    $sw.Start()
    $printout = & $Expression 2>&1
    $sw.Stop()
    "run number: $Run" | Out-File "$($full_file_path)" -Append
    "run time:  $($sw.Elapsed.TotalSeconds)" | Out-File "$($full_file_path)" -Append
	"Command printout: " | Out-File "$($full_file_path)" -Append
    $($printout) | Out-File "$($full_file_path)" -Append
	
	"`n######################################################`n" | Out-File "$($full_file_path)" -Append 
    $sw.Reset()
    $Samples--
    $Run++
  }
  while ($Samples -gt 0)
  $End_time = Get-Date
  #add the file to git, push with comment
  git add $filename
  git commit -m "results from $test_name - $Start_time to $End_time"
  git push
}

Export-ModuleMember Benchmark-Command