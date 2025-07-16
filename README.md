# ADHOC-Remediations

A collection of powershell scripts to resolve problems that have become tedious.


# Clear Global Retry Schedule:
Where win32 app deployments have reached their maximum retry attempts, simply run the remediation to clear the registry keys and restart the IME service. Company portal will then attempt to re-install again.

# Clear Teams Cache:
No need to explain, standard fix for a wide range of issues MS teams faces.

# Stale App Policy Fix:
When applications are missing from software centre, show as evaluation state 0, unknown or error. This script checks each applications policy for error states and triggers a re-evaluation if found. 



