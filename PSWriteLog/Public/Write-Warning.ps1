function global:Write-Warning {
    [CmdletBinding(HelpUri='http://go.microsoft.com/fwlink/?LinkID=113430', RemotingCapability='None')]
    param(
        [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
        [Alias('Msg')]
        [AllowEmptyString()]
        [string]
        ${Message}
    )

    begin
    {
        if ($MyInvocation.PSCommandPath) {
            $invoFile = Split-Path $MyInvocation.PSCommandPath -Leaf
        } else {
            $invoFile = Split-Path $MyInvocation.InvocationName -Leaf
        }

        $writeLog = @{
            'Severity' = 'Warning';
            'Component' = (& { $PSCallStack = (Get-PSCallStack)[2]; "$($PSCallStack.Command) $($PSCallStack.Arguments)" });
            'Source' = "${invoFile}:$($MyInvocation.ScriptLineNumber)";
        }

        if (-not ($env:PSWriteLogWarningSilent -as [bool])) {
            try {
                $outBuffer = $null
                if ($PSBoundParameters.TryGetValue('OutBuffer', [ref]$outBuffer))
                {
                    $PSBoundParameters['OutBuffer'] = 1
                }
                $wrappedCmd = $ExecutionContext.InvokeCommand.GetCommand('Microsoft.PowerShell.Utility\Write-Warning', [System.Management.Automation.CommandTypes]::Cmdlet)
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
        if ((Get-Command 'Write-Log' -ErrorAction 'Ignore') -and ($WarningPreference -ine 'SilentlyContinue')) {
            Write-Log @writeLog -Message $Message
        }

        if (-not ($env:PSWriteLogWarningSilent -as [bool])) {
            try {
                $steppablePipeline.Process($_)
            } catch {
                throw
            }
        }
    }

    end
    {
        if (-not ($env:PSWriteLogWarningSilent -as [bool])) {
            try {
                $steppablePipeline.End()
            } catch {
                throw
            }
        }
    }
    <#

    .ForwardHelpTargetName Microsoft.PowerShell.Utility\Write-Warning
    .ForwardHelpCategory Cmdlet

    #>
}