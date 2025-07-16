<#
    AppPolicy Remediation

    Description
    Once we know there is policy errors we first confirm if there are App-V errors as well
    If there is we will repair WMI before we re-evaluate the policies.
    

    Script Context:
    Administrator
#>


$Name = $env:COMPUTERNAME
$ApplicationPolicy = Get-CimInstance -Namespace 'ROOT\CCM\ClientSDK' -Query "SELECT * FROM CCM_ApplicationPolicy" | Where {$_.CurrentState -eq 'Error'}


if(!$ApplicationPolicy){

    Write-Host 'No application policies reporting an error state'
    Exit 0

}Else{

# Check for App-V & WMI erros, if found repair before completing the app policy fix
$AppV = Select-String -Path "C:\windows\ccm\logs\AppDiscovery.log" -Pattern 'Most likely AppV client is not installed correctly' -Quiet
$AppList = Get-CimInstance -Namespace 'ROOT\CCM\ClientSDK' -Query "SELECT * FROM CCM_Application"


# If there are appv errors or no applications showing in CCM_Application we can safely assume WMI needs repairing.
if ($AppV -or (!$AppList)){

    # List the Files in c:\windows\System32\wbem 
    $FileList = get-childitem -Path c:\windows\system32\wbem -Name -include *.mfl, *.mof -exclude "*Uninstall*"

    # Cycle through the files and mofcomp them
    foreach ($file in $FileList) {

        $RealFile = -join("C:\Windows\System32\Wbem\", $file)
        mofcomp $RealFile | Out-Null

    }

    # Run extra mofcomp on ExtendedStatus & Appv
    cd "C:\Program Files\Microsoft Policy Platform\" | mofcomp ExtendedStatus.mof | Out-Null
    cd "C:\Windows\System32\wbem" | mofcomp Remove.Microsoft.Appv.AppvClientWmi.mof | out-null
    cd "C:\Windows\System32\wbem" | mofcomp Microsoft.Appv.AppvClientWmi.mof | out-null 
       
}
    
    $PolicyClass = [WmiClass]"\\$Name\root\ccm\clientSDK:CCM_ApplicationPolicy"
    
    foreach($Policy in $ApplicationPolicy){
        $PolicyClass.EvaluateAppPolicy($Policy.Id,$Policy.Revision,$Policy.IsMachineTarget,'High',0)
    }

}
