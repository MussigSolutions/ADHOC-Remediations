<#

    Clear_GRS - Remediation

    Description
    Retrieves the guid for win32 app's that are pending global retry schedule
    removes relevant registry key's and restarts the IME service to prompt device to try install again

    HKLM:\SOFTWARE\Microsoft\IntuneManagementExtension\Win32Apps\xxx
    HKLM:\SOFTWARE\Microsoft\IntuneManagementExtension\Win32Apps\xxx\GRS\xxx
    
    Logging
    Logs are stored at 'C:\ProgramData\Microsoft\IntuneManagementExtension\RemediationLogs\Clear_GRS.log'

    Script Context:
    Administrator
#>


Function Write-Log
{
   Param ([string]$logstring, [string]$LogPath)
   if(!(Test-Path -path 'C:\ProgramData\Microsoft\IntuneManagementExtension\RemediationLogs')){New-Item -Path "C:\ProgramData\Microsoft\IntuneManagementExtension\" -Name "RemediationLogs" -ItemType "directory" | out-null}
   $logdate = Get-Date -Format "dd/MM/yyyy hh:mm:ss tt"
   $LogTitle = 'Clear_GRS'
   $LogPath = 'C:\ProgramData\Microsoft\IntuneManagementExtension\RemediationLogs\{0}.log' -F $LogTitle
   Add-content -Path $LogPath -Value "$LogTitle : $Logdate :   $Logstring"
}


Function Get-AppsPendingGRC {
    # Define variables
    $PendingRetry = @()
    $win32AppsKeyPath = 'HKLM:\SOFTWARE\Microsoft\IntuneManagementExtension\Win32Apps\'

    # Filter's \Win32Apps\ for GUIDS
    $UserKeys = Get-ChildItem -Path $win32AppsKeyPath | Where {[System.Guid]::TryParse($_.PSChildName , [ref]'00000000-0000-0000-0000-000000000000') -eq $True} | Select -ExpandProperty PSChildName    
    
    # Iterate through each user's GUID, retrieve global retry hash entries that contain an AppID
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




Function Remove-AppFromGRS {
    param ([Parameter(Mandatory=$true)]
    [Array]$PendingRetry)

    foreach($Entry in $PendingRetry){
        
        # We remove the GRS hash key each GRS hash with an AppGUID property string

        $GRSPath = 'HKLM:\SOFTWARE\Microsoft\IntuneManagementExtension\Win32Apps\{0}\GRS\{1}' -f $Entry.UserID, $Entry.Path
        Write-Log -logstring "Attempting to remove registry key: $GRSPath"
        Remove-Item -path $GRSPath -recurse -force

        # Checks if the previous command to remove reg key failed and logs accordingly
        if($?){
            Write-Log -logstring "Successfully removed registry key: $GRSPath"
        }else{
        # If the reg key action failed we output the error to the log
            $RegError = 'Error: ' +$Error[0].Exception.message
            Write-Log -logstring $RegError
        }

        # Confirm there is a matching key
        $UserPath = 'HKLM:\SOFTWARE\Microsoft\IntuneManagementExtension\Win32Apps\{0}' -f $Entry.UserID
        $AppGUID = Get-childitem -path $UserPath | where {$_.Name -match $Entry.AppGUID} | Select -ExpandProperty name
        $AppGUID = $AppGUID.split('\')[6]

        # Remove the AppGUID key
        $AppPath = 'HKLM:\SOFTWARE\Microsoft\IntuneManagementExtension\Win32Apps\{0}\{1}' -f $Entry.UserID, $AppGUID
        Write-Log -logstring "Attempting to remove registry key: $AppPath"
        Remove-item -Path $AppPath -recurse -force
        
        # Checks if the previous command to remove reg key failed and logs accordingly
        if($?){
            Write-Log -logstring "Successfully removed registry key: $AppPath"
        }else{
            $RegError = 'Error: ' +$Error[0].Exception.message
            Write-Log -logstring $RegError
        }
    
    }
}



##### Script Execution #####

Write-Log 'Warning: We will check for applicationg pending the global retry schedule'

$UserKeys = Get-AppsPendingGRS

if($UserKeys -ne $null){
    Write-log -logstring "Detected apps pending the global retry schedule, we will attempt to remove those now"
    Remove-AppFromGRC -PendingRetry $UserKeys

    Write-Log -LogString "Warning: Restarting the IME service to force a sync and prompt the device to install the applications again"
    Restart-Service -Name 'IntuneManagementExtension' -Force -PassThru | Out-null
}else{
    Write-host 'No keys to remove'
    Write-Log -logstring 'No GRS Keys detected no action has been taken'
}
