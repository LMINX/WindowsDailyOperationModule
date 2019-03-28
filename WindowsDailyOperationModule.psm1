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
  $PerfData=Invoke-Command -ComputerName $ServerName -ScriptBlock {Get-Counter -Counter "\Processor(_Total)\% Processor Time" -SampleInterval 1 -MaxSamples 5} -Credential $SACredential
  $CpuUsage=@()

  foreach ($sample in $PerfData)
  {
    $ArraySample=$sample.readings.split(":")    
    $type=$ArraySample[0].trim()
    $value=[int]$ArraySample[1].trim()
    $metric=switch -Wildcard ($type) 
    {
    '*\Processor(_Total)\% Processor Time'{'cpu'}
    '*\LogicalDisk(_Total)\Disk Transfers/sec'{'diskIORequest'}
    '*\LogicalDisk(_Total)\Disk Bytes/sec'{'diskIOThrought'}
    '*\network interface(microsoft hyper-v network adapter)\Bytes Total/sec'{'NetworkThrought'}
    }
  
    #deserial the return object from invoke-command

    if ($metric -eq 'cpu'){
      $CpuUsage+=$value
    }
    elseif ($metric -eq 'disk') {
      
    }
    elseif ($metric -eq 'network') {
      
    }


    
  }

  $ServerBasicInfo=[PSCustomObject]@{
    Servername = $ServerName
    AvgCpuUsage= ($CpuUsage|Measure-Object -Average).average

  }
  $ServerBasicInfo


  #format table like  CPU /top process  

}
catch {
  $error[0]
}
finally {
  
}




}

Diag-ServerIssue rnlq03404hv001