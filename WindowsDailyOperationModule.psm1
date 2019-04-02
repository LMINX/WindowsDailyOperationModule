<#
 .Synopsis
  Query the server basic information 

 .Description
  Query the server basic information,EX:  timezone /last boot time/ error log 

 .Parameter Servername
  ServerName 


 .Example
   # Show a default display all basic informatoin for the server
   Diagnose-ServeIssue -ServerName R4WAPPP001

 .Example
   # Display basic informatoin for the server errorlog  in last 24H
   Diagnose-ServeIssue -ServerName R4WAPPP001 -errorlog 24H


#>

function Diag-ServerIssue
{
param(
    $ServerName 
)

#get SA  Credential

$username=$env:USERDOMAIN+"\"+$env:USERNAME
if ($username -notmatch "NIKE\SA.")
{
$SAUserName=$username.replace("\","\SA.")
$SACredential=Get-Credential -UserName $SAUserName -Message "Please input your SA account Password"
# validation the username and pwd

}
else 
{$SACredential=Get-Credential -UserName $UserName -Message "Please input your SA account Password"
}
try {
  #$CPUUsagePerfData=Get-Counter -Counter "\Processor(_Total)\% Processor Time" -SampleInterval 1 -ComputerName $ServerName -MaxSamples 5 
  #$PerfData=Invoke-Command -ComputerName $ServerName -ScriptBlock {Get-Counter -Counter "\Processor(_Total)\% Processor Time" -SampleInterval 1 -MaxSamples 5} -Credential $SACredential
  #$CpuUsage=@()
  
  #get cpu usage by summary each process usage 
  $AllProcessPerfData=@()
  $LogicalCpuCores=(Get-WmiObject -Class win32_processor -ComputerName $ServerName -Credential $SACredential|Measure-Object -Property NumberOfLogicalProcessors -Sum).Sum
  $PerfData=Invoke-Command -ComputerName $ServerName -ScriptBlock {Get-Counter -Counter "\Process(*)\% Processor Time" -SampleInterval 1 -MaxSamples 1} -Credential $SACredential
  
  $datePattern = [Regex]::new('\\\\')
  $matchPatterns = $datePattern.Matches($perfdata.readings)
  $i=0
  foreach($m in $matchPatterns){
    if ($i -le ($matchPatterns.count-2))
  {
      
    $next=$matchPatterns[$i+1]
    $Perfsampledata=$perfdata.readings.substring($m.index, ($next.Index-$m.index))
    $i++
    $ArraySample=$Perfsampledata.split(":")    
    $type=$ArraySample[0].trim()
    $value=$ArraySample[1].trim()
    $metric=switch -Wildcard ($type) 
    {
    '*\% Processor Time'{'cpu'}
    '*\LogicalDisk(_Total)\Disk Transfers/sec'{'diskIORequest'}
    '*\LogicalDisk(_Total)\Disk Bytes/sec'{'diskIOThrought'}
    '*\network interface(microsoft hyper-v network adapter)\Bytes Total/sec'{'NetworkThrought'}
    }
  
    #deserial the return object from invoke-command

    if ($metric -eq 'cpu'){
      if(($type -notmatch "total") -and ($type -notmatch "idle")){
        $ProcessPerfData=[PSCustomObject]@{
          Servername = $ServerName
          ProcessCpuUsage=$value/$LogicalCpuCores
          Porcessname=$type
        }
  
      }
      else {
        #skip as we dont need the informat for idle and total process.
      }
    }
    elseif ($metric -eq 'disk') {
      
    }
    elseif ($metric -eq 'network') {
      
    }

  }
    
    $AllProcessPerfData+=$ProcessPerfData
   
    
  }


  #format table like  CPU /top process  
` $Tops5Process=$AllProcessPerfData|Sort-Object -Property ProcessCpuUsage  -Descending|Select-Object -First 5
  $TotalCpuUsage=($AllProcessPerfData|Measure-Object -Sum -Property  ProcessCpuUsage).Sum


  $output= $Tops5Process+'Total Cpu Usage is {0}' -f $TotalCpuUsage
  $output


}
catch {
  $error[0]
}
finally {
  
}




}

Diag-ServerIssue rnlq03404hv001