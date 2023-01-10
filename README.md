[![Build status](https://ci.appveyor.com/api/projects/status/vxp2bf5b6t6t774y/branch/master?svg=true)](https://ci.appveyor.com/project/VertigoRay/pswritelog)
[![codecov](https://codecov.io/gh/VertigoRay/PSWriteLog/branch/master/graph/badge.svg)](https://codecov.io/gh/VertigoRay/PSWriteLog)
[![version](https://img.shields.io/powershellgallery/v/PSWriteLog.svg)](https://www.powershellgallery.com/packages/PSWriteLog)
[![downloads](https://img.shields.io/powershellgallery/dt/PSWriteLog.svg?label=downloads)](https://www.powershellgallery.com/stats/packages/PSWriteLog?groupby=Version)
[![PSScriptAnalyzer](https://github.com/VertigoRay/PSWriteLog/actions/workflows/powershell.yml/badge.svg)](https://github.com/VertigoRay/PSWriteLog/actions/workflows/powershell.yml)
[![Codacy Security Scan](https://github.com/VertigoRay/PSWriteLog/actions/workflows/codacy.yml/badge.svg)](https://github.com/VertigoRay/PSWriteLog/actions/workflows/codacy.yml)
[![DevSkim](https://github.com/VertigoRay/PSWriteLog/actions/workflows/devskim.yml/badge.svg)](https://github.com/VertigoRay/PSWriteLog/actions/workflows/devskim.yml)

![PSWriteLog](https://t.ly/wrBQ) is a tool to standardize logging without the need to use new function calls in your PowerShell scripts.
Just configure the log location (or don't) and start logging with your standard `Write` functions.

- [Quick Start](#quick-start)
- [Description](#description)
- [Bypassing Write-Log](#bypassing-write-log)
- [Debug with Write-Information](#debug-with-write-information)
  - [Debug PSWriteLog (or Your Application)](#debug-pswritelog-or-your-application)

# Quick Start

Before you do anything, [install PSWriteLog](https://www.powershellgallery.com/packages/PSWriteLog).
Create a new script, mine will be called `foo.ps1` and will contain the following lines:

```powershell
#Requires -Modules PSWriteLog
Write-Host 'Hello World!'
```

> ℹ: You'll notice that the `Hello World!` message did output to host as expected.

Because nothing was configured, you can find the log in the default location:

- `%TEMP%\PowerShell Desktop 5.1.19041.1682 Internal.log`

> ℹ: The default file name will vary depending on your environment, but it can be gleaned with this command:
>
> ```powershell
> [IO.Path]::Combine($env:Temp, ('PowerShell {0} {1} {2}.log' -f @(
>     $PSVersionTable.PSEdition,
>     $PSVersionTable.PSVersion,
>     $MyInvocation.CommandOrigin
> )))
> ```

If you open that file, you can see that the log appears in *CMTrace* format:

```xml
<![LOG[Info: Hello World!]LOG]!><time="22:32:05.575-360" date="01-05-2023" component="foo.ps1 {}" context="TEST\VertigoRay" type="6" thread="15" file="foo.ps1:2">
```

# Description

PSWriteLog has a private function called `Write-Log` that does all the logging for you.
It's a private function because we don't want you to use it.
Instead, we've created [proxy functions](https://learn.microsoft.com/en-us/dotnet/api/system.management.automation.proxycommand?view=powershellsdk-1.1.0) for the `Write-*` functions so you don't have to learn to use a new function.
These proxy functions keep the original functionality of the function intact, while also sending the outputted message to the `Write-Log` function.
By default, `Write-Log` will write messages to a log file in [CMTrace](https://learn.microsoft.com/en-us/mem/configmgr/core/support/cmtrace) compatible format, but Legacy (plain-text) file format is also available.
To configure *PSWriteLog*, what you need to do is change the default actions of the `Write-Log` parameters.
You can specify default parameters using the built-in [`$PSDefaultParameterValues`](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_parameters_default_values?view=powershell-5.1) variable. Here's an example of specifying the Log file path and log type globally:

```powershell
$PSDefaultParameterValues.Add('Write-Log:FilePath', "${env:SystemRoot}\Logs\MyApp.log")
$PSDefaultParameterValues.Add('Write-Log:LogType', 'Legacy')
```

These are the proxy functions that are imported:

- `Write-Debug` (Log dependent on `$DebugPreference`)
- `Write-Error`
- `Write-Host`
- `Write-Information` (Log dependent on `$InformationPreference`; PowerShell 5.0+)
- `Write-Output` (Log dependent on `$VerbosePreference`)
- `Write-Progress`
- `Write-Verbose` (Log dependent on `$VerbosePreference`)
- `Write-Warning` (Log dependent on `$WarningPreference`)

Importing the above functions will log anything sent to those proxy functions while keeping the original funtionality of those functions in tact.
Keep in mind, that verbose messaging will only be logged if it would have been outputted to the screen.
This is configured with the [Preference Variables](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_preference_variables?view=powershell-5.1).
So, if you want to see verbose messages, be sure to set `$VerbosePreference` to `continue`.

# Bypassing Write-Log

There may be instances when you are using *PSWriteLog* that you want to output to the screen, but not save the output to the log.
Maybe you have sensitive data (e.g.: passwords, auth tokens, etc.) that you don't want saved to a log file.
In those cases, you can bypass *PSWriteLog*'s logging functionality, by telling PowerShell to use the original Microsoft function using its full path.
Here's how you get the full path to `Write-Host`:

```powershell
Get-Command Write-Host
```

That'll give you the source and other information:

> CommandType | Name | Version | Source
> ----------- | ---- | ------- | ------
> Cmdlet | Write-Host | 3.1.0.0 | Microsoft.PowerShell.Utility

You can then call the function and provide the source path as well:

```powershell
Microsoft.PowerShell.Utility\Write-Host "Password: $password"
```

# Debug with Write-Information

I like to use `Write-Information` to debug because I send the messages to a variable and filter them later.
Instead of scrolling through a ton of `Verbose` or `Debug` output, I can just filter down to the messages that came tagged the way I was expecting.
Here's some sample code for you to play with and see what I'm talking about:

```powershell
function foo {
    [CmdletBinding()]
    Param()
    Microsoft.PowerShell.Utility\Write-Information 'Test 1'
    Microsoft.PowerShell.Utility\Write-Information "[foo] Processor: $env:PROCESSOR_IDENTIFIER" -Tags 'foo','Test'
    Microsoft.PowerShell.Utility\Write-Information 'Test 2'
}
foo -InformationVariable bar
$bar | ?{ $_.Tags -eq 'foo' }
```

If you aren't near a PowerShell terminal, here's a quick demo:

![Write-Information Tag Filtering](https://i.imgur.com/u9WBQQG.gif)

## Debug PSWriteLog (or Your Application)

In *PSWriteLog* every `Write-Information` that I use, [bypasses the the log](#bypassing-write-log).
This means that my `Write-Information` calls *should* never end up in your log file.
They also have two tags:

- `VertigoRay\PSWriteLog`
- The Function Name (e.g.: `Write-Log`)

For me, when I'm working on *PSWriteLog* and I want to see just those messages, I'll do something like this:

```powershell
$InformationPreference = 'Continue'
$PSDefaultParameterValues.Set_Item('Write-Log:InformationVariable', 'foo')

Write-Host 'Testing a thing'
$foo | ?{ $_.Tags -eq 'Write-Log' }
```

With that I'll see just want I want to see.
You can use the same ideas in your scripts by always tagging your calls to `Write-Information` so that when you want to redirect them to a variable for easy filtering, you can.

Cheers! 🍻
