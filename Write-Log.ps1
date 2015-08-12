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
The source of the message being logged. Default is from `$MyInvocation`: *ScriptName:ScriptLineNumber*
.PARAMETER Component
The heading for the portion of the script that is being executed. Default is from `$MyInvocation`: *Command {Arguments}*
.PARAMETER LogType
Choose whether to write a CMTrace.exe compatible log file or a Legacy text log file.
.PARAMETER LogFileDirectory
Set the directory where the log file will be saved.
.PARAMETER LogFileName
Set the name of the log file.
.PARAMETER MaxLogFileSizeMB
Maximum file size limit for log file in megabytes (MB). Default is 10 MB.
.PARAMETER WriteHost
Write the log message to the console.
.PARAMETER ContinueOnError
Suppress writing log message to console on failure to write message to log file.
.PARAMETER PassThru
Return the message that was passed to the function
.PARAMETER DebugMessage
Specifies that the message is a debug message. Debug messages only get logged if -LogDebugMessage is set to $true.
.PARAMETER LogDebugMessage
Debug messages only get logged if this parameter is set to $true in the config XML file.
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
Function Write-Log {
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory=$true,Position=0,ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true)]
        [AllowEmptyCollection()]
        [string[]]$Message,
        [Parameter(Mandatory=$false,Position=1)]
        [ValidateRange(1,3)]
        [int16]$Severity = 1,
        [Parameter(Mandatory=$false,Position=2)]
        [ValidateNotNull()]
        [string]$Source = (& { If ($script:MyInvocation.Value.ScriptName) { Split-Path -Path $script:MyInvocation.Value.ScriptName -Leaf } Else { Split-Path -Path $script:MyInvocation.MyCommand.Definition -Leaf } }) + ":" + $MyInvocation.ScriptLineNumber,
        [Parameter(Mandatory=$false,Position=3)]
         [alias("ScriptSection")]
        [ValidateNotNull()]
        [string]$Component = (& { $PSCallStack = (Get-PSCallStack)[1]; "$($PSCallStack.Command) $($PSCallStack.Arguments)" }),
        [Parameter(Mandatory=$false,Position=4)]
        [ValidateSet('CMTrace','Legacy')]
        [string]$LogType = 'CMTrace',
        [Parameter(Mandatory=$false,Position=5)]
        [ValidateNotNullorEmpty()]
        [string]$LogFileDirectory = "${env:SystemRoot}\Logs",
        [Parameter(Mandatory=$false,Position=6)]
        [ValidateNotNullorEmpty()]
        [string]$LogFileName = "$($PSCmdlet.MyInvocation.MyCommand.Name).log",
        [Parameter(Mandatory=$false,Position=7)]
        [ValidateNotNullorEmpty()]
        [decimal]$MaxLogFileSizeMB = 10,
        [Parameter(Mandatory=$false,Position=8)]
        [ValidateNotNullorEmpty()]
        [boolean]$WriteHost = $false,
        [Parameter(Mandatory=$false,Position=9)]
        [ValidateNotNullorEmpty()]
        [boolean]$ContinueOnError = $true,
        [Parameter(Mandatory=$false,Position=10)]
        [switch]$PassThru = $false,
        [Parameter(Mandatory=$false,Position=11)]
        [switch]$DebugMessage = $false,
        [Parameter(Mandatory=$false,Position=12)]
        [boolean]$LogDebugMessage = $false
    )
    
    Begin {
        # Get the name of this function
        [string]${CmdletName} = $PSCmdlet.MyInvocation.MyCommand.Name

        # Initialize config from $variable:Write-Log
        if (${env:Write-Log} -and ${env:Write-Log} -is 'String' -and [boolean](-not [string]::IsNullOrEmpty(${env:Write-Log}))) {
            try {
                $env_WriteLog = ConvertFrom-Json ${env:Write-Log}
            } catch {
                # Not valid JSON
                $env_WriteLog = $false
            }

            if ($env_WriteLog) {
                foreach ($parameter in ((Get-Command -Name $CmdletName).Parameters).Values.Name) {
                    if ($MyInvocation.BoundParameters[$parameter]) {
                        # Parameters passed in always take precedence.
                        continue
                    }
                    if ($env_WriteLog.PSObject.Properties[$parameter]) {
                        Set-Variable -Name $parameter -Value $env_WriteLog.$parameter
                    }
                }
            }
        }

        # Initialize the date/time variables
        [string]$LogTime = (Get-Date -Format HH:mm:ss.fff).ToString()
        [string]$LogDate = (Get-Date -Format MM-dd-yyyy).ToString()
        If (-not (Test-Path -Path 'variable:LogTimeZoneBias')) {
            [int32]$script:LogTimeZoneBias = [System.TimeZone]::CurrentTimeZone.GetUtcOffset([datetime]::Now).TotalMinutes
        }
        #  Add the timezone bias to the log time
        [string]$LogTimePlusBias = $LogTime + $script:LogTimeZoneBias
        
        # Check if the script section is defined
        [boolean]$ComponentDefined = [boolean](-not [string]::IsNullOrEmpty($Component))
        
        # Initialize $DisableLogging variable to avoid error if 'Set-StrictMode' is set
        If (-not (Test-Path -Path 'variable:DisableLogging')) { $DisableLogging = $false }
        
        # Create script block for generating CMTrace.exe compatible log entry
        [scriptblock]$CMTraceLogString = {
            Param (
                [string]$lMessage,
                [string]$lComponent,
                [int16]$lSeverity
            )
            "<![LOG[${lMessage}]LOG]!><time=`"$LogTimePlusBias`" date=`"$LogDate`" component=`"$lComponent`" context=`"$([System.Security.Principal.WindowsIdentity]::GetCurrent().Name)`" type=`"$lSeverity`" thread=`"$([Threading.Thread]::CurrentThread.ManagedThreadId)`" file=`"$Source`">"
        }
        
        # Create script block for writing log entry to the console
        [scriptblock]$WriteLogLineToHost = {
            Param (
                [string]$lTextLogLine,
                [int16]$lSeverity
            )
            If ($WriteHost) {
                #  Only output using color options if running in a host which supports colors.
                If ($Host.UI.RawUI.ForegroundColor) {
                    Switch ($lSeverity) {
                        3 { Write-Host $lTextLogLine -ForegroundColor 'Red' -BackgroundColor 'Black' }
                        2 { Write-Host $lTextLogLine -ForegroundColor 'Yellow' -BackgroundColor 'Black' }
                        1 { Write-Host $lTextLogLine }
                    }
                }
                #  If executing "powershell.exe -File <filename>.ps1 > log.txt", then all the Write-Host calls are converted to Write-Output calls so that they are included in the text log.
                Else {
                    Write-Output $lTextLogLine
                }
            }
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
                    Write-Host "[$LogDate $LogTime] [${CmdletName}] ${Component} :: Failed to create the log directory [${LogFileDirectory}]. `n${_}" -ForegroundColor 'Red'
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
            # If the message is not $null or empty, create the log entry for the different logging methods
            [string]$CMTraceMsg = ''
            [string]$ConsoleLogLine = ''
            [string]$LegacyTextLogLine = ''
            If ($Msg) {
                #  Create the CMTrace log message
                [string]$CMTraceMsg = $Msg
                
                #  Create a Console and Legacy "text" log entry
                [string]$LegacyMsg = "[${LogDate} ${LogTime}]"
                If ($ComponentDefined) { [string]$LegacyMsg += " [${Component}]" }
                If ($Source) {
                    [string]$ConsoleLogLine = "${LegacyMsg} [${Source}] :: ${Msg}"
                    Switch ($Severity) {
                        3 { [string]$LegacyTextLogLine = "${LegacyMsg} [${Source}] [Error] :: ${Msg}" }
                        2 { [string]$LegacyTextLogLine = "${LegacyMsg} [${Source}] [Warning] :: ${Msg}" }
                        1 { [string]$LegacyTextLogLine = "${LegacyMsg} [${Source}] [Info] :: ${Msg}" }
                    }
                }
                Else {
                    [string]$ConsoleLogLine = "${LegacyMsg} :: ${Msg}"
                    Switch ($Severity) {
                        3 { [string]$LegacyTextLogLine = "${LegacyMsg} [Error] :: ${Msg}" }
                        2 { [string]$LegacyTextLogLine = "${LegacyMsg} [Warning] :: ${Msg}" }
                        1 { [string]$LegacyTextLogLine = "${LegacyMsg} [Info] :: ${Msg}" }
                    }
                }
            }
            
            # Execute script block to create the CMTrace.exe compatible log entry
            [string]$CMTraceLogLine = & $CMTraceLogString -lMessage $CMTraceMsg -lComponent $Component -lSeverity $Severity
            
            # Choose which log type to write to file
            If ($LogType -ieq 'CMTrace') {
                [string]$LogLine = $CMTraceLogLine
            }
            Else {
                [string]$LogLine = $LegacyTextLogLine
            }
            
            # Write the log entry to the log file if logging is not currently disabled
            If (-not $DisableLogging) {
                Try {
                    $LogLine | Out-File -FilePath $LogFilePath -Append -NoClobber -Force -Encoding 'UTF8' -ErrorAction 'Stop'
                }
                Catch {
                    If (-not $ContinueOnError) {
                        Write-Host "[$LogDate $LogTime] [$Component] [${CmdletName}] :: Failed to write message [$Msg] to the log file [$LogFilePath]. `n$(Resolve-Error)" -ForegroundColor 'Red'
                    }
                }
            }
            
            # Execute script block to write the log entry to the console if $WriteHost is $true
            & $WriteLogLineToHost -lTextLogLine $ConsoleLogLine -lSeverity $Severity
        }
    }
    End {
        # Archive log file if size is greater than $MaxLogFileSizeMB and $MaxLogFileSizeMB > 0
        Try {
            [System.IO.FileInfo]$LogFile = Get-ChildItem -Path $LogFilePath -ErrorAction 'Stop'
            [decimal]$LogFileSizeMB = $LogFile.Length/1MB
            Write-Verbose "LogFileSizeMB: $LogFileSizeMB"
            Write-Verbose "MaxLogFileSizeMB: $MaxLogFileSizeMB"
            If (($LogFileSizeMB -gt $MaxLogFileSizeMB) -and ($MaxLogFileSizeMB -gt 0)) {
                # Change the file extension to "lo_"
                [string]$ArchivedOutLogFile = [System.IO.Path]::ChangeExtension($LogFilePath, 'lo_')
                [hashtable]$ArchiveLogParams = @{ Component = $Component; Source = ${CmdletName}; Severity = 2; LogFileDirectory = $LogFileDirectory; LogFileName = $LogFileName; LogType = $LogType; MaxLogFileSizeMB = 0; WriteHost = $WriteHost; ContinueOnError = $ContinueOnError; PassThru = $false }
                
                # Log message about archiving the log file
                if ((Get-PSCallStack)[1].Command -ne 'Write-Log') {
                    # Prevent Write-Log from looping more than once.
                    $ArchiveLogMessage = "Maximum log file size [$MaxLogFileSizeMB MB] reached. Rename log file to [$ArchivedOutLogFile]."
                    Write-Log -Message $ArchiveLogMessage @ArchiveLogParams
                }
                
                # Archive existing log file from <filename>.log to <filename>.lo_. Overwrites any existing <filename>.lo_ file. This is the same method SCCM uses for log files.
                Move-Item -Path $LogFilePath -Destination $ArchivedOutLogFile -Force -ErrorAction 'Stop'
                
                # Start new log file and Log message about archiving the old log file
                $NewLogMessage = "Previous log file was renamed to [$ArchivedOutLogFile] because maximum log file size of [$MaxLogFileSizeMB MB] was reached."
                Write-Log -Message $NewLogMessage @ArchiveLogParams
            }
        }
        Catch {
            # If renaming of file fails, script will continue writing to log file even if size goes over the max file size
            Write-Verbose $_
        }
        Finally {
            If ($PassThru) { Write-Output $Message }
        }
    }
}
