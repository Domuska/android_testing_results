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
  #$timings = @()
  [int]$Run = 1
  do {
    $sw = New-Object Diagnostics.Stopwatch
    $sw.Start()
    $printout = & $Expression 2>&1
    $sw.Stop()
    "run number: $Run" | Out-File c:\users\Tomi\testAutomation\measurements\robotium_amaze.txt -Append
    "run time:  $($sw.Elapsed.TotalSeconds)" | Out-File c:\users\Tomi\testAutomation\measurements\robotium_amaze.txt -Append
	"Command printout: " | Out-File c:\users\Tomi\testAutomation\measurements\robotium_amaze.txt -Append
    $($printout) | Out-File c:\users\Tomi\testAutomation\measurements\robotium_amaze.txt -Append
	"`n######################################################`n" | Out-File c:\users\Tomi\testAutomation\measurements\robotium_amaze.txt -Append 
    $sw.Reset()
    $Samples--
    $Run++
  }
  while ($Samples -gt 0)
  git add robotium_amaze.txt
  git commit -m "results from START_TIME to END_TIME"
  git push
}

Export-ModuleMember Benchmark-Command