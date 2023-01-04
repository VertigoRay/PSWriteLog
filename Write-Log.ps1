<#
.SYNOPSIS
Write messages to a log file in CMTrace.exe compatible format or Legacy text file format.
.DESCRIPTION
Write messages to a log file in CMTrace.exe compatible format or Legacy text file format and optionally display in the console.

Can also specify parameters via $env:Write-Log variable. Store variables in as JSON. [More in the wiki.](https://git.cas.unt.edu/posh/write-log/wikis/Environment_Variable_Write-Log)
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
https://git.cas.unt.edu/posh/write-log
#>
function global:Write-Log {
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory=$true,Position=0,ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true)]
        [AllowEmptyCollection()]
        [string[]]
        $Message
        ,
        [Parameter(Mandatory=$false,Position=1)]
        [string]
        $Severity = 'Info'
        ,
        [Parameter(Mandatory=$false,Position=2)]
        [ValidateNotNull()]
        [string]
        $Source = (& { If ($script:MyInvocation.Value.ScriptName) { Split-Path -Path $script:MyInvocation.Value.ScriptName -Leaf } Else { Split-Path -Path $script:MyInvocation.MyCommand.Definition -Leaf } }) + ":" + $MyInvocation.ScriptLineNumber
        ,
        [Parameter(Mandatory=$false,Position=3)]
         [alias("ScriptSection")]
        [ValidateNotNull()]
        [string]
        $Component = (& { $PSCallStack = (Get-PSCallStack)[1]; "$($PSCallStack.Command) $($PSCallStack.Arguments)" })
        ,
        [Parameter(Mandatory=$false,Position=4)]
        [ValidateSet('CMTrace','Legacy')]
        [string]
        $LogType = 'CMTrace'
        ,
        [Parameter(Mandatory=$false,Position=5)]
        [ValidateNotNullorEmpty()]
        [string]
        $LogFileDirectory = $env:Temp
        ,
        [Parameter(Mandatory=$false,Position=6)]
        [ValidateNotNullorEmpty()]
        [string]
        $LogFileName = "$($PSCmdlet.MyInvocation.MyCommand.Name).log"
        ,
        [Parameter(Mandatory=$false,Position=7)]
        [ValidateNotNullorEmpty()]
        [decimal]
        $MaxLogFileSizeMB = 10
        ,
        [Parameter(Mandatory=$false,Position=9)]
        [ValidateNotNullorEmpty()]
        [boolean]
        $ContinueOnError = $true
    )

    Begin {
        if ((Get-Command 'Write-Debug').Source -eq 'Microsoft.PowerShell.Utility') {
            $write_debug = @{}
        } else {
            $write_debug = @{'NoLog' = $true}
        }
        Write-Debug "[Write-Log] BoundParameters: $($MyInvocation.BoundParameters | Out-String)" @write_debug

        # Get the name of this function
        [string]${CmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name

        # Initialize $DisableLogging variable to avoid error if 'Set-StrictMode' is set
        If (-not (Test-Path -Path 'variable:DisableLogging')) { $DisableLogging = $false }

        [scriptblock]$LogDate = { (Get-Date -Format MM-dd-yyyy).ToString() }

        [scriptblock]$LogTime = {
            [string]$script:LogTimeZoneBias = [System.TimeZone]::CurrentTimeZone.GetUtcOffset([datetime]::Now).TotalMinutes
            "$((Get-Date -Format HH:mm:ss.fff).ToString())${script:LogTimeZoneBias}"
        }

        # Create script block for generating a Legacy log entry
        [scriptblock]$LegacyLogString = {
            Param (
                [string]$lMessage
            )

            [System.Collections.ArrayList]$LegacyMessage = @()

            $LegacyMessage.Add("[$(& $LogDate) $(& $LogTime)]") | Out-Null
            if ($Source) { $LegacyMessage.Add("[${Source}]") | Out-Null }
            $LegacyMessage.Add("[${Component}]") | Out-Null
            $LegacyMessage.Add("[${Severity}]") | Out-Null
            $LegacyMessage.Add(($lMessage.Trim() | Out-String)) | Out-Null

            ($LegacyMessage -join ' ').Trim()
        }

        # Create script block for generating CMTrace.exe compatible log entry
        [scriptblock]$CMTraceLogString = {
            Param (
                [string]$lMessage
            )
            Write-Debug "[Write-Log] Source (sb): ${Source}" @write_debug
            $Severity_map = @{ # Vaguely based on POSH stream numbers
                'Debug'       = 5;
                'Error'       = 3;
                'Host'        = 1;
                'Info'        = 6;
                'Information' = 6;
                'Output'      = 4;
                'Progress'    = 1;
                'Verbose'     = 4;
                'Warning'     = 2;
            }
            "<![LOG[${Severity}: $($lMessage.Trim())]LOG]!><time=`"$(& $LogTime)`" date=`"$(& $LogDate)`" component=`"${Component}`" context=`"$([System.Security.Principal.WindowsIdentity]::GetCurrent().Name)`" type=`"$($Severity_map.$Severity)`" thread=`"$([Threading.Thread]::CurrentThread.ManagedThreadId)`" file=`"${Source}`">"
        }

        #  Create the directory where the log file will be saved
        [boolean]$LogDirectoryCreateError = $false
        If (-not (Test-Path -Path $LogFileDirectory -PathType Container)) {
            Try {
                New-Item -Path $LogFileDirectory -Type 'Directory' -Force -ErrorAction 'Stop' | Out-Null
            }
            Catch {
                [boolean]$LogDirectoryCreateError = $true
                #  If error creating directory, write message to console
                If (-not $ContinueOnError) {
                    Throw "[$(& $LogDate) $(& $LogTime)] [${CmdletName}] ${Component} :: Failed to create the log directory [${LogFileDirectory}]. `n${_}"
                }
                Return
            }
        }

        #  Assemble the fully qualified path to the log file
        [string]$LogFilePath = Join-Path -Path $LogFileDirectory -ChildPath $LogFileName
    }

    Process {
        # Exit function if it is a debug message and 'LogDebugMessage' option is not $true, or if the log directory was not successfully created in 'Begin' block.
        If ((($DebugMessage) -and (-not $LogDebugMessage)) -or ($LogDirectoryCreateError)) { Return }

        ForEach ($Msg in $Message) {
            Write-Debug "[Write-Log] Source: $Source" @write_debug
            # Write the log entry to the log file if logging is not currently disabled
            If (-not $DisableLogging) {
                ## Choose which log type to write to file
                If ($LogType -ieq 'CMTrace') {
                    [string]$LogLine = & $CMTraceLogString -lMessage ($Msg | Out-String).Trim() -lSource $Source
                } Else {
                    [string]$LogLine = & $LegacyLogString -lMessage ($Msg | Out-String).Trim() -lSource $Source
                }

                Try {
                    $LogLine | Out-File -FilePath $LogFilePath -Append -NoClobber -Force -Encoding 'UTF8' -ErrorAction 'Stop'
                }
                Catch {
                    If (-not $ContinueOnError) {
                        Throw "[$(& $LogDate) $(& $LogTime)] [${CmdletName}] [${Component}] :: Failed to write message [$Msg] to the log file [$LogFilePath]. `n$(Resolve-Error)"
                    }
                }
            }
        }
    }

    End {
        # Archive log file if size is greater than $MaxLogFileSizeMB and $MaxLogFileSizeMB > 0
        try {
            [System.IO.FileInfo]$LogFile = Get-ChildItem -Path $LogFilePath -ErrorAction 'Stop'
            [decimal]$LogFileSizeMB = $LogFile.Length/1MB
            Write-Debug "[Write-Log] LogFileSizeMB: $LogFileSizeMB" @write_debug
            Write-Debug "[Write-Log] MaxLogFileSizeMB: $MaxLogFileSizeMB" @write_debug
            If (($LogFileSizeMB -gt $MaxLogFileSizeMB) -and ($MaxLogFileSizeMB -gt 0)) {
                Write-Debug "[Write-Log] Log File Needs to be archived ..." @write_debug
                # Change the file extension to "lo_"
                [string]$ArchivedOutLogFile = [System.IO.Path]::ChangeExtension($LogFilePath, 'lo_')
                [hashtable]$ArchiveLogParams = @{ Component = $Component; Source = ${CmdletName}; Severity = 'Info'; LogFileDirectory = $LogFileDirectory; LogFileName = $LogFileName; LogType = $LogType; MaxLogFileSizeMB = 0; WriteHost = $WriteHost; ContinueOnError = $ContinueOnError; PassThru = $false }

                # Log message about archiving the log file
                if ((Get-PSCallStack)[1].Command -ne 'Write-Log') {
                    # Prevent Write-Log from looping more than once.
                    Write-Log -Message "Maximum log file size [${MaxLogFileSizeMB} MB] reached. Rename log file to: ${ArchivedOutLogFile}" @ArchiveLogParams
                }

                # Archive existing log file from <filename>.log to <filename>.lo_. Overwrites any existing <filename>.lo_ file. This is the same method SCCM uses for log files.
                Move-Item -Path $LogFilePath -Destination $ArchivedOutLogFile -Force -ErrorAction 'Stop'

                # Start new log file and Log message about archiving the old log file
                Write-Log -Message "Maximum log file size [${MaxLogFileSizeMB} MB] reached. Previous log file was renamed to: ${ArchivedOutLogFile}" @ArchiveLogParams
            } else {
                Write-Debug "[Write-Log] Log File does not need to be archived." @write_debug
            }
        } catch {
            # If renaming of file fails, script will continue writing to log file even if size goes over the max file size
            Write-Debug "[Write-Log] Archive Error: ${_}" @write_debug
        }

        Write-Debug "[Write-Log] Archive Finally: PassThru($( if ($PassThru) {'true'} else {'false'} ))" @write_debug
        If ($PassThru) { Write-Output $Message }
    }
}
