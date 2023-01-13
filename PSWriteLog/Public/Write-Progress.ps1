function global:Write-Progress {
    [CmdletBinding(HelpUri='http://go.microsoft.com/fwlink/?LinkID=113428', RemotingCapability='None')]
    param(
        [Parameter(Mandatory=$true, Position=0)]
        [string]
        ${Activity},

        [Parameter(Position=1)]
        [ValidateNotNullOrEmpty()]
        [string]
        ${Status},

        [Parameter(Position=2)]
        [ValidateRange(0, 2147483647)]
        [int]
        ${Id},

        [ValidateRange(-1, 100)]
        [int]
        ${PercentComplete},

        [int]
        ${SecondsRemaining},

        [string]
        ${CurrentOperation},

        [ValidateRange(-1, 2147483647)]
        [int]
        ${ParentId},

        [switch]
        ${Completed},

        [int]
        ${SourceId}
    )

    begin
    {
        if ($MyInvocation.PSCommandPath) {
            $invoFile = Split-Path $MyInvocation.PSCommandPath -Leaf
        } else {
            $invoFile = Split-Path $MyInvocation.InvocationName -Leaf
        }

        $writeLog = @{
            'Severity' = 'Progress'
            'Component' = (& { $PSCallStack = (Get-PSCallStack)[2]; "$($PSCallStack.Command) $($PSCallStack.Arguments)" });
            'Source' = "${invoFile}:$($MyInvocation.ScriptLineNumber)";
        }

        if (-not ($env:PSWriteLogProgessSilent -as [bool])) {
            try {
                $outBuffer = $null
                if ($PSBoundParameters.TryGetValue('OutBuffer', [ref]$outBuffer))
                {
                    $PSBoundParameters['OutBuffer'] = 1
                }
                $PSBoundParameters.Remove('WriteHostColor')
                $wrappedCmd = $ExecutionContext.InvokeCommand.GetCommand('Microsoft.PowerShell.Utility\Write-Progress', [System.Management.Automation.CommandTypes]::Cmdlet)
                $scriptCmd = {& $wrappedCmd @PSBoundParameters }
                $steppablePipeline = $scriptCmd.GetSteppablePipeline($myInvocation.CommandOrigin)
                $steppablePipeline.Begin($PSCmdlet)
            } catch {
                throw
            }
        }
    }

    process
    {
        if (Get-Command 'Write-Log' -ErrorAction 'Ignore' -and ($ProgressPreference -ine 'SilentlyContinue')) {
            [System.Collections.ArrayList] $Message = @()
            if ($PSBoundParameters.ContainsKey('ParentId')) { $Message.Add("[${ParentId}]") | Out-Null }
            if ($PSBoundParameters.ContainsKey('Id')) { $Message.Add("[${Id}]") | Out-Null }
            $Message.Add($Activity) | Out-Null
            if ($PSBoundParameters.ContainsKey('PercentComplete')) { $Message.Add("${PercentComplete}%") | Out-Null }
            if ($PSBoundParameters.ContainsKey('SecondsRemaining')) { $Message.Add("(${SecondsRemaining} Seconds Remaining)") | Out-Null }
            $Message.Add(':') | Out-Null
            $Message.Add($Status) | Out-Null
            $Message.Add(':') | Out-Null
            $Message.Add($CurrentOperation) | Out-Null

            Write-Log @writeLog -Message ($Message -join ' ')
        }

        if (-not ($env:PSWriteLogProgessSilent -as [bool])) {
            try {
                $steppablePipeline.Process($_)
            } catch {
                throw
            }
        }
    }

    end
    {
        if (-not ($env:PSWriteLogProgessSilent -as [bool])) {
            try {
                $steppablePipeline.End()
            } catch {
                throw
            }
        }
    }
    <#

    .ForwardHelpTargetName Microsoft.PowerShell.Utility\Write-Progress
    .ForwardHelpCategory Cmdlet

    #>
}