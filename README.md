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
  - [Proxy Functions](#proxy-functions)
    - [`Write-Debug`](#write-debug)
    - [`Write-Error`](#write-error)
    - [`Write-Host`](#write-host)
    - [`Write-Information`](#write-information)
    - [`Write-Output`](#write-output)
    - [`Write-Progress`](#write-progress)
    - [`Write-Verbose`](#write-verbose)
    - [`Write-Warning`](#write-warning)
- [Parameters](#parameters)
  - [ContinueOnError](#continueonerror)
  - [DisableLogging](#disablelogging)
  - [FilePath](#filepath)
  - [IncludeInvocationHeader](#includeinvocationheader)
  - [LogType](#logtype)
  - [MaxLogFileSizeMB](#maxlogfilesizemb)
- [Resolve-Error](#resolve-error)
- [Notes](#notes)
  - [Bypassing Write-Log](#bypassing-write-log)
  - [Debug with Write-Information](#debug-with-write-information)
  - [Debug PSWriteLog (or Your Application)](#debug-pswritelog-or-your-application)

# Quick Start

Before you do anything, [install *PSWriteLog*](https://www.powershellgallery.com/packages/PSWriteLog).
Create a new script, mine will be called `foo.ps1` and will contain the following lines:

```powershell
#Requires -Modules PSWriteLog
Write-Host 'Hello World!'
```

**I love how clean and simple that is!**
However, [the `#Requires` statement will terminate](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_requires?view=powershell-5.1#-modules-module-name--hashtable) if you don't have *PSWriteLog* installed.
Since we're not introducing any new functions, *PSWriteLog* shouldn't be required to *just run the script*.
To ensure there are no errors if you share your script with someone that doesn't have *PSWriteLog* installed:

```powershell
if (Get-Module 'PSWriteLog' -ListAvailable) {
    Import-Module PSWriteLog
}
Write-Host 'Hello World!'
```

> ℹ: You'll notice that the `Hello World!` message did output to host as expected.

Because nothing was configured, you can find the log in the [default location](#filepath):

- `%TEMP%\PowerShell Desktop 5.1.19041.1682 Internal.log`

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
You can specify default parameters using the built-in [`$PSDefaultParameterValues`](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_parameters_default_values?view=powershell-5.1) variable.
Here's an example of specifying the Log file path and log type globally:

```powershell
$PSDefaultParameterValues.Add('Write-Log:FilePath', "${env:SystemRoot}\Logs\MyApp.log")
$PSDefaultParameterValues.Add('Write-Log:LogType', 'Legacy')
```

## Proxy Functions

The following proxy functions will log anything sent to those proxy functions while keeping the original funtionality of those functions in tact.
Keep in mind, that some messaging will only be logged if it would have been outputted to the screen.
This is configured with the [Preference Variables](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_preference_variables?view=powershell-5.1).
So, if you want to see verbose messages, be sure to set `$VerbosePreference` to `Continue`.

> ⚠: ***Do not* get in the habit of using `-Silent` or `-Log` parameters on function calls.**
> The point of *PSWriteLog* is that the script can be run on a system without *PSWriteFunction* installed without causing issues.
> Adding those parameters to a function call, will cause `a parameter cannot be found that matches parameter name 'Silent'` error.
> However, using `$PSDefaultParameterValues` to define parameters that do not exist are not an issue with PowerShell; even with *strict mode* enabled.

### `Write-Debug`

- Logging requires `$DebugPreference` to *not be* set to `SilentlyContinue`.
- Prevent output to console: `$PSDefaultParameterValues.Add('Write-Debug:Silent', $true)`; *do not* get in the habit of doing `Write-Debug -Silent`.
- If you look at the code, you'll notice a `NoLog` parameter; this is for internal use to prevent looping. *Don't use it!*

> ⚠: ***Do not* get in the habit of using `-Silent` parameters on function calls.**

### `Write-Error`

- Prevent output to console: `$PSDefaultParameterValues.Add('Write-Error:Silent', $true)`; *do not* get in the habit of doing `Write-Error -Silent`.

> ⚠: ***Do not* get in the habit of using `-Silent` parameters on function calls.**

### `Write-Host`

- Prevent output to console: `$PSDefaultParameterValues.Add('Write-Host:Silent', $true)`; *do not* get in the habit of doing `Write-Host -Silent`.

> ⚠: ***Do not* get in the habit of using `-Silent` parameters on function calls.**

### `Write-Information`

- Logging requires `$InformationPreference`; PowerShell 5.0+ to *not be* set to `SilentlyContinue`.
- Prevent output to console: `$PSDefaultParameterValues.Add('Write-Information:Silent', $true)`; *do not* get in the habit of doing `Write-Information -Silent`.

> ⚠: ***Do not* get in the habit of using `-Silent` parameters on function calls.**

### `Write-Output`

- Logging requires `$PSDefaultParameterValues.Add('Write-Output:Log', $true)`; *do not* get in the habit of doing `Write-Output -Log`.

> ⚠: ***Do not* get in the habit of using `-Log` parameters on function calls.**

### `Write-Progress`

- We try to capture all of the progress information.

### `Write-Verbose`

- Logging requires `$VerbosePreference` to *not be* set to `SilentlyContinue`.
- Prevent output to console: `$PSDefaultParameterValues.Add('Write-Verbose:Silent', $true)`; *do not* get in the habit of doing `Write-Verbose -Silent`.

> ⚠: ***Do not* get in the habit of using `-Silent` parameters on function calls.**

### `Write-Warning`

- Logging requires `$WarningPreference` to *not be* set to `SilentlyContinue`.
- Prevent output to console: `$PSDefaultParameterValues.Add('Write-Warning:Silent', $true)`; *do not* get in the habit of doing `Write-Warning -Silent`.

> ⚠: ***Do not* get in the habit of using `-Silent` parameters on function calls.**

# Parameters

The core function is a hidden `Write-Log` function that is called by all the [proxy functions](#proxy-functions) above.
Since it's a hidden function, you use [`$PSDefaultParameterValues`](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_parameters_default_values?view=powershell-5.1) to customize functionality.

## ContinueOnError

- Type: `[switch]`

If there's an error writing to the log file, a terminating error will be thrown.
Unless of course, you've specified this switch.

```powershell
$PSDefaultParameterValues.Set_Item('Write-Log:ContinueOnError', $true)
```

## DisableLogging

- Type: `[switch]`

If there's a reason to toggle-off all logging for a bit, this is your mechanism.

```powershell
$PSDefaultParameterValues.Set_Item('Write-Log:DisableLogging', $true)
Get-AllSuperSecretStuff -Verbose
$PSDefaultParameterValues.Set_Item('Write-Log:DisableLogging', $false)
```

## FilePath

- Type: `[IO.FileInfo]`
- Default: *Something like: `%TEMP%\PowerShell Desktop 5.1.19041.1682 Internal.log`*
    ```powershell
    [IO.Path]::Combine($env:Temp, ('PowerShell {0} {1} {2}.log' -f @(
        $PSVersionTable.PSEdition
        $PSVersionTable.PSVersion
        $MyInvocation.CommandOrigin
    ))
    ```

The default file name will vary depending on your environment.
Change the location by providing the full path to the log file.

```powershell
$PSDefaultParameterValues.Set_Item('Write-Log:FilePath', "${env:SystemRoot}\Logs\MyApp.log")
```

## IncludeInvocationHeader

- Type: `[switch]`

If you're familiar with `Start-Transcript -IncludeInvocationHeader` then you already know what this does.
It logs some environment information before the next `Write-Log` call.

```powershell
$PSDefaultParameterValues.Set_Item('Write-Log:IncludeInvocationHeader', $true)
```

We set `$env:PSWriteLogIncludedInvocationHeader` to `True` when it's written to ensure it's only done once per session.
If you want it done again, just clear out that environment variable:

```powershell
$env:PSWriteLogIncludedInvocationHeader = $null
```

## LogType

- Type: `[string]`
- Default: `CMTrace`
- Options: `CMTrace`, `Legacy`

Define the format for log messages.
Will write messages to a log file in [`CMTrace`](https://learn.microsoft.com/en-us/mem/configmgr/core/support/cmtrace) compatible format, but `Legacy` (plain-text) file format is also available.

```powershell
$PSDefaultParameterValues.Set_Item('Write-Log:LogType', 'Legacy')
```

## MaxLogFileSizeMB

- Type: `[decimal]`
- Default: `10.0`

Log rotations are built in.
Archived logs are renamed from a `.log` extension to a `.lo_` extension.
If a `.lo_` already exists, it'll be deleted.

```powershell
$PSDefaultParameterValues.Set_Item('Write-Log:MaxLogFileSizeMB', 3.14)
```

# Resolve-Error

**So ... remember when I said that we're not introducing any additional functions?**
I lied.
There's one.
However, it's very useful ... I swear!
I still believe that *PSWriteLog* shouldn't be required to *just run the script*.
So, here's how you can use `Resolve-Error`:

```powershell
try {
    # Do something that throws an error ...
} catch {
    $resolvedError = if (Get-Command 'Resolve-Error' -ErrorAction 'Ignore') {
        Resolve-Error
    } else {
        $_.Exception.Message
    }
	Write-Error ('Failed to do a thing. {0}' -f $resolvedError)
}
```

# Notes

The rest of this stuff is really beyond the scope of *PSWriteLog*, but I hope it's useful information ...

## Bypassing Write-Log

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

## Debug with Write-Information

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
