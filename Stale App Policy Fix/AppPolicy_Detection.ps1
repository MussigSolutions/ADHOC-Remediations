<#
    AppPolicy Detection

    Description
    Checks application policies on a device, if any report an error state it prompts for remediation.    

    Script Context:
    Administrator
#>

$Name = $env:COMPUTERNAME

$ApplicationPolicy = Get-CimInstance -Namespace 'ROOT\CCM\ClientSDK' -Query "SELECT * FROM CCM_ApplicationPolicy" | Where {$_.CurrentState -eq 'Error'}
$Count = $ApplicationPolicy.count


if(!$ApplicationPolicy){

    Write-Host 'No application policies reporting an error state'
    Exit 0

}Else{
    
    Write-output '$count apps reporting an error state'
    exit 1

}
