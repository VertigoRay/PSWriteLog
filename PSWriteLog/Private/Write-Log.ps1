<#
.SYNOPSIS
Write messages to a log file in CMTrace.exe compatible format or Legacy text file format.
.DESCRIPTION
Write messages to a log file in CMTrace.exe compatible format or Legacy text file format and optionally display in the console.
.PARAMETER Message
The message to write to the log file or output to the console.
.PARAMETER Severity
Defines message type. When writing to console or CMTrace.exe log format, it allows highlighting of message type.
Options: 1 = Information (default), 2 = Warning (highlighted in yellow), 3 = Error (highlighted in red)
.PARAMETER Source
The source of the message being logged.
.PARAMETER Component
The heading for the portion of the script that is being executed. Default is: $script:installPhase.
.PARAMETER LogType
Choose whether to write a CMTrace.exe compatible log file or a Legacy text log file.
.PARAMETER LogFileDirectory
Set the directory where the log file will be saved.
.PARAMETER LogFileName
Set the name of the log file.
.PARAMETER MaxLogFileSizeMB
Maximum file size limit for log file in megabytes (MB). Default is 10 MB.
Setting to 0 will disable log rotations.
.PARAMETER ContinueOnError
Suppress writing log message to console on failure to write message to log file.
.EXAMPLE
Write-Log -Message "Installing patch MS15-031" -Source 'Add-Patch' -LogType 'CMTrace'
.EXAMPLE
Write-Log -Message "Script is running on Windows 8" -Source 'Test-ValidOS' -LogType 'Legacy'
.NOTES
Taken from PSAppDeployToolkit:
https://github.com/PSAppDeployToolkit/PSAppDeployToolkit/blob/3.6.4/Toolkit/AppDeployToolkit/AppDeployToolkitMain.ps1#L480-L741
.LINK
https://github.com/VertigoRay/PSWriteLog
#>
function global:Write-Log {
    [CmdletBinding()]
    Param(
        [Parameter(
            Mandatory = $true,
            Position = 0,
            ValueFromPipeline=$true,
            ValueFromPipelineByPropertyName=$true)]
        [AllowEmptyCollection()]
        [string[]]
        $Message,

        [Parameter(Mandatory = $false, Position = 1)]
        [string]
        $Severity = 'Info',

        [Parameter(Mandatory = $false, Position = 2)]
        [ValidateNotNull()]
        [string]
        $Source = (& { if ($script:MyInvocation.Value.ScriptName) {
            Split-Path -Path $script:MyInvocation.Value.ScriptName -Leaf
        } else {
            Split-Path -Path $script:MyInvocation.MyCommand.Definition -Leaf
        } }) + ':' + $MyInvocation.ScriptLineNumber,

        [Parameter(Mandatory = $false, Position = 3)]
        [alias('ScriptSection')]
        [ValidateNotNull()]
        [string]
        $Component = (& { $PSCallStack = (Get-PSCallStack)[1]; "$($PSCallStack.Command) $($PSCallStack.Arguments)" }),

        [Parameter(Mandatory = $false, Position = 4)]
        [ValidateSet('CMTrace', 'Legacy')]
        [string]
        $LogType = $(if ($env:PSWriteLogType) { $env:PSWriteLogType } else { 'CMTrace' }),

        [Parameter(Mandatory = $false, Position = 5)]
        [ValidateNotNullorEmpty()]
        [IO.FileInfo]
        $FilePath = $(if ($env:PSWriteLogFilePath) { $env:PSWriteLogFilePath } else { [IO.Path]::Combine($env:Temp, ('PowerShell {0} {1} {2}.log' -f $PSVersionTable.PSEdition, $PSVersionTable.PSVersion, $MyInvocation.CommandOrigin)) }),

        [Parameter(Mandatory = $false, Position = 6)]
        [ValidateNotNullorEmpty()]
        [decimal]
        $MaxLogFileSizeMB = $(if ($env:PSWriteLogMaxLogFileSizeMB) { $env:PSWriteLogMaxLogFileSizeMB -as [decimal] } else { 10 }),

        [Parameter(Mandatory = $false)]
        [bool]
        $ContinueOnError = $(if ($env:PSWriteLogContinueOnError) { $env:PSWriteLogContinueOnError -as [bool] } else { $false }),

        [Parameter(Mandatory = $false)]
        [bool]
        $DisableLogging = $(if ($env:PSWriteLogDisableLogging) { $env:PSWriteLogDisableLogging -as [bool] } else { $false }),

        [Parameter(Mandatory = $false)]
        [bool]
        $IncludeInvocationHeader = $(if ($env:PSWriteLogIncludeInvocationHeader) { $env:PSWriteLogIncludeInvocationHeader -as [bool] } else { $false })
    )

    begin {
        # Microsoft.PowerShell.Utility\Write-Debug ('[Write-Log] BoundParameters: {0}' -f $($MyInvocation.BoundParameters | Out-String))

        if ($env:PSWriteLogDisableLogging) {
            # If logging is not currently disabled, get out now!
            # Microsoft.PowerShell.Utility\Write-Debug ('[Write-Log] env:PSWriteLogDisableLogging: {0}' -f $env:PSWriteLogDisableLogging)
            return $null
        }

        # Get the name of this function
        [string] $CmdletName = $PSCmdlet.MyInvocation.MyCommand.Name

        [scriptblock] $logDate = {
            return (Get-Date -Format MM-dd-yyyy).ToString()
        }

        [scriptblock] $logTime = {
            [string] $script:logTimeZoneBias = [System.TimeZone]::CurrentTimeZone.GetUtcOffset([datetime]::Now).TotalMinutes
            return "$((Get-Date -Format HH:mm:ss.fff).ToString())${script:logTimeZoneBias}"
        }

        # Create script block for generating a Legacy log entry
        [scriptblock] $legacyLogString = {
            Param(
                [string]
                $lMessage
            )

            [System.Collections.ArrayList] $legacyMessage = @()

            $legacyMessage.Add(('[{0}]' -f (Get-Date -Format 'O'))) | Out-Null
            if ($Source) {
                $legacyMessage.Add("[${Source}]") | Out-Null
            }
            # $legacyMessage.Add("[${Component}]") | Out-Null
            $legacyMessage.Add("[${Severity}]") | Out-Null
            $legacyMessage.Add(($lMessage.Trim() | Out-String)) | Out-Null

            return ($legacyMessage -join ' ').Trim()
        }

        # Create script block for generating CMTrace.exe compatible log entry
        [scriptblock] $cmTraceLogString = {
            param(
                [string]
                $lMessage
            )
            # Microsoft.PowerShell.Utility\Write-Debug "[Write-Log] Source (sb): ${Source}"
            $severityMap = @{ # Vaguely based on POSH stream numbers
                Debug       = 5
                Error       = 3
                Host        = 1
                Info        = 6
                Information = 6
                Output      = 4
                Progress    = 1
                Verbose     = 4
                Warning     = 2
            }

            return ('<![LOG[{0}: {1}]LOG]!><time="{2}" date="{3}" component="{4}" context="{5}" type="{6}" thread="{7}" file="{8}">' -f @(
                $Severity
                $lMessage.Trim()
                & $logTime
                & $logDate
                $Component
                [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
                $severityMap.$Severity
                [Threading.Thread]::CurrentThread.ManagedThreadId
                $Source
            ))
        }

        [scriptblock] $logLine = {
            param(
                [string]
                $sMsg
            )
            ## Choose which log type to write to file
            $line = if ($LogType -ieq 'CMTrace') {
                & $cmTraceLogString -lMessage ($sMsg | Out-String).Trim() -lSource $Source
            } else {
                & $legacyLogString -lMessage ($sMsg | Out-String).Trim() -lSource $Source
            }

            $line | Out-File -FilePath $FilePath.FullName -Append -NoClobber -Force -Encoding 'UTF8' -ErrorAction 'Stop'
        }

        #  Create the directory where the log file will be saved
        if (-not $FilePath.Directory.Exists) {
            New-Item -Path $FilePath.DirectoryName -Type 'Directory' -Force -ErrorAction 'Stop' | Out-Null
        }
    }

    process {
        if ($IncludeInvocationHeader) {
            & $logLine -sMsg (Get-InvocationHeader)
        }

        foreach ($msg in $Message) {
            # Microsoft.PowerShell.Utility\Write-Debug ('[Write-Log] Source: {0}' -f $Source)
            try {
                & $logLine -sMsg $msg
            } catch {
                if (-not $ContinueOnError) {
                    throw ('[{0} {1}] [{2}] [{3}] :: Failed to write message [{4}] to the log file [{5}].{6}{7}' -f @(
                        & $logDate
                        & $logTime
                        $CmdletName
                        $Component
                        $Msg
                        $FilePath.FullName
                        "`n"
                        Resolve-Error | Out-String
                    ))
                }
            }
        }
    }

    end {
        # Archive log file if size is greater than $MaxLogFileSizeMB and $MaxLogFileSizeMB > 0
        if ($MaxLogFileSizeMB) {
            try {
                [decimal] $LogFileSizeMB = $FilePath.Length/1MB
                # Microsoft.PowerShell.Utility\Write-Debug "[Write-Log] LogFileSizeMB: $LogFileSizeMB / $MaxLogFileSizeMB"
                if ($LogFileSizeMB -gt $MaxLogFileSizeMB) {
                    # Microsoft.PowerShell.Utility\Write-Debug "[Write-Log] Log File Needs to be archived ..."
                    # Change the file extension to "lo_"
                    [string] $archivedOutLogFile = [IO.Path]::ChangeExtension($FilePath.FullName, 'lo_')

                    # Log message about archiving the log file
                    if ((Get-PSCallStack)[1].Command -ne 'Write-Log') {
                        # Prevent Write-Log from looping more than once.
                        & $logLine -sMsg "Maximum log file size [${MaxLogFileSizeMB} MB] reached. Rename log file to: ${archivedOutLogFile}"
                    }

                    # Archive existing log file from <filename>.log to <filename>.lo_. Overwrites any existing <filename>.lo_ file. This is the same method SCCM uses for log files.
                    Move-Item -Path $FilePath.FullName -Destination $archivedOutLogFile -Force -ErrorAction 'Stop'

                    # Start new log file and Log message about archiving the old log file
                    & $logLine -sMsg "Maximum log file size [${MaxLogFileSizeMB} MB] reached. Previous log file was renamed to: ${archivedOutLogFile}"
                } else {
                    # Microsoft.PowerShell.Utility\Write-Debug "[Write-Log] Log File does not need to be archived."
                }
            } catch {
                # If renaming of file fails, script will continue writing to log file even if size goes over the max file size
                # Microsoft.PowerShell.Utility\Write-Debug "[Write-Log] Archive Error: ${_}"
            }
        }
    }
}
