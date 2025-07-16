  # AppPolicy Remediation

  # Description
  After confirming there is policy errors we first confirm if there are App-V errors as well
  If there is we will complete mofcomp on WMI and App-V .mof files to repair this first.

  Once the WMI is healthy we can re-evaluate our policies to trigger application discovery.
  

  #Script Context
  Administrator
