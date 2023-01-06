Write messages to a log file in CMTrace.exe compatible format or Legacy text file format.

# Quick Start

Create a new script, mine will be called `foo.ps1` and will contain the following lines:

```powershell
#Requires -Modules PSWriteLog
Write-Host 'Hello World!'
```

> ℹ: You'll notice that the `Hello World!` message did output to host as expected.

Because nothing was configured, you can find the log in the default location:

- `%TEMP%\PowerShell Desktop 5.1.19041.1682 Internal.log`

> ℹ: The file name will vary depending on your environment, but can be gleaned with this command:
>
> ```powershell
> [IO.Path]::Combine($env:Temp, ('PowerShell {0} {1} {2}.log' -f $PSVersionTable.PSEdition, $PSVersionTable.PSVersion, $MyInvocation.CommandOrigin))
> ```

If you open that file, you can see that the log appears in *CMTrace* format:

```xml
<![LOG[Info: Hello World!]LOG]!><time="22:32:05.575-360" date="01-05-2023" component="foo.ps1 {}" context="TEST\VertigoRay" type="6" thread="15" file="foo.ps1:2">
```

# Description

Write messages to a log file in CMTrace.exe compatible format or Legacy text file format and optionally display in the console.

To specify Default Parameters, use the PowerShell 3.0+ built-in [`$PSDefaultParameterValues`](https://technet.microsoft.com/en-us/library/hh847819.aspx) variable. Here's an example of specifying the Log file path and type globally:

```powershell
$PSDefaultParameterValues.Add('Write-Log:FilePath', "${env:SystemRoot}\Logs\MyApp.log")
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