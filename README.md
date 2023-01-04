Write messages to a log file in CMTrace.exe compatible format or Legacy text file format.

# Description

Write messages to a log file in CMTrace.exe compatible format or Legacy text file format and optionally display in the console.

To specify Default Parameters, use the PowerShell 3.0+ built-in [`$PSDefaultParameterValues`](https://technet.microsoft.com/en-us/library/hh847819.aspx) variable. Here's an example of specifying the Log file path and type globally:

```powershell
$PSDefaultParameterValues.Add('Write-Log:LogFileDirectory', "${env:SystemRoot}\Logs")
$PSDefaultParameterValues.Add('Write-Log:LogFileName', "MyApp.log")
$PSDefaultParameterValues.Add('Write-Log:LogType', 'CMTrace')
```

Can also import any/all of the availble proxy functions:

- `Write-Debug` (Log dependent on `$DebugPreference`)
- `Write-Error`
- `Write-Host`
- `Write-Information` (Log dependent on `$InformationPreference`; PowerShell 5.0+)
- `Write-Output` (Log dependent on `$VerbosePreference`)
- `Write-Progress`
- `Write-Verbose` (Log dependent on `$VerbosePreference`)
- `Write-Warning` (Log dependent on `$WarningPreference`)

Importing the above functions will log anythign sent to those proxy functions while keeping the original funtionality of those functions in tact.

You may also want to make an alias

[The wiki contains complete documentation.](/posh/write-log/wikis/home)