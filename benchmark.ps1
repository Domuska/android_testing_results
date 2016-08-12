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


  #change file tag name below, it is added to beginning of file name
  $test_name = "uiautomator_amaze"
  
  
  
  $file_path = "c:\users\Tomi\testAutomation\measurements\"
  [int]$Run = 1
  $Start_time = Get-Date -f yyy-MM-dd_hh_mm_ss
  #the raw file path, no extension
  $filename = "$test_name-$(get-date -f yyy-MM-dd_hh_mm_ss)"
  #$filename_txt = "$test_name-$(get-date -f yyy-MM-dd_hh_mm_ss).txt"
  #$filename_csv = "$test_name-$(get-date -f yyy-MM-dd_hh_mm_ss).csv"
  #echo $filename
  #in current directory
  $full_file_path_txt = "$file_path$filename\$filename.txt"
  $full_file_path_csv = "$file_path$filename\$filename.csv"
  #echo $full_file_path_txt
  
  #create a new directory with the name 
  New-Item "$file_path$filename" -type directory
  
  do {
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
	#write to .txt that has tab separators between fields
	"$($Run);$($sw.Elapsed.TotalSeconds);$($printout)" | Out-File "$($full_file_path_csv)" -Append -Encoding ascii
	#"," | Out-File "$($full_file_path_csv)" -Append
	#$sw.Elapsed.TotalSeconds | Out-File "$($full_file_path_csv)" -Append
	
    $sw.Reset()
    $Samples--
    $Run++
  }
  while ($Samples -gt 0)
  $End_time = Get-Date -f yyy-MM-dd_hh_mm_ss
  #add the file to git, push with comment
  git add $filename
  git commit -m "results from $test_name - $Start_time to $End_time"
  git push
}

#Export-ModuleMember Benchmark-Command