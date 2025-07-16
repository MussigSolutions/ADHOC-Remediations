# Clear Teams Cache

# Description
This remediation is run under user context to allow us to re-launch the application for the user.
A verification is run on the cache path to ensure we do not clear a redundant directory. For when Microsoft eventually decides to specify a new cache location.... 

# Action
Closes MS-Teams, clears the cache and re-launches the application.
