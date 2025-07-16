<#

    Clear_GRS - Detection

    Description
    Checks for entries in the below locations that would prevent a device from attempting to install a Win32 application
    If found triggers a remediation to remove the keys and prompt the device to re-attempt installs
    
    HKLM:\SOFTWARE\Microsoft\IntuneManagementExtension\Win32Apps\
    HKLM:\SOFTWARE\Microsoft\IntuneManagementExtension\Win32Apps\xxx\GRS

    Script Context:
    Administrator
#>

Function Get-AppsPendingGRS {
    # Define variables
    $PendingRetry = @()
    $win32AppsKeyPath = 'HKLM:\SOFTWARE\Microsoft\IntuneManagementExtension\Win32Apps\'

    # Filter's \Win32Apps\ for GUIDS
    $UserKeys = Get-ChildItem -Path $win32AppsKeyPath | Where {[System.Guid]::TryParse($_.PSChildName , [ref]'00000000-0000-0000-0000-000000000000') -eq $True} | Select -ExpandProperty PSChildName    
    
    # Iterate through each user's GUID, retrieve global retry entries that contain an AppID
    foreach($User in $UserKeys){
        $GRSKeys = 'HKLM:\SOFTWARE\Microsoft\IntuneManagementExtension\Win32Apps\{0}\GRS' -f $User
        $GRSSubkeys = Get-childitem -path $GRSKeys
    
        foreach($Key in $GRSSubkeys){
        $Properties = $Key.Property
            foreach($Property in $Properties){
            if([System.Guid]::TryParse($Property , [ref]'00000000-0000-0000-0000-000000000000') -eq $True){
                $PendingRetry += [PSCustomObject]@{
                    UserID = $User
                    AppGUID = $Key.Property | where {$_.length -eq 36}
                    Path = $Key.PSChildName
                }
            }
            }

        }
        
    }
    return $PendingRetry
}

#### SCRIPT ENTRY POINT ####

# Get the failed Win32 app states
$PendingRetry = Get-AppsPendingGRS


# Output the result
if ($PendingRetry -ne $Null) {
    Write-Host "Failed apps detected, remediation will proceed.; App's Found: $PendingRetry.AppGUID"
    exit 1
}
else {
    Write-Host "No apps found in global retry schedule. No action required."
    exit 0
}