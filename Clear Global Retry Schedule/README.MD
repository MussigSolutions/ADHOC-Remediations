# Clear_GRS

> Useful to remove failed Win32 app install attempts from the global retry schedule. If failures are present their reg keys are removed and the Intune Management Extension service is restarted to prompt the device to sync and rety installations.

## Global Retry Schedule Key's

AppGUID = HKLM:\SOFTWARE\Microsoft\IntuneManagementExtension\Win32Apps\xxx

GRS Hash = HKLM:\SOFTWARE\Microsoft\IntuneManagementExtension\Win32Apps\AppGUID\GRS\xxx
