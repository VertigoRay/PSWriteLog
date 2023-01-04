function global:Write-Debug {
    [CmdletBinding(HelpUri='http://go.microsoft.com/fwlink/?LinkID=113424', RemotingCapability='None')]
    param(
        [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
        [Alias('Msg')]
        [AllowEmptyString()]
        [string]
        ${Message}
        ,
        [switch]
        ${NoLog}
    )

    begin
    {
        if ($MyInvocation.PSCommandPath) {
            $invo_file = Split-Path $MyInvocation.PSCommandPath -Leaf
        } else {
            $invo_file = Split-Path $MyInvocation.InvocationName -Leaf
        }

        $write_log = @{
            'Severity' = 'Debug';
            'Component' = (& { $PSCallStack = (Get-PSCallStack)[2]; "$($PSCallStack.Command) $($PSCallStack.Arguments)" });
            'Source' = "${invo_file}:$($MyInvocation.ScriptLineNumber)";
        }

        try {
            $outBuffer = $null
            if ($PSBoundParameters.TryGetValue('OutBuffer', [ref]$outBuffer))
            {
                $PSBoundParameters['OutBuffer'] = 1
            }
            $PSBoundParameters.Remove('NoLog') | Out-Null
            $wrappedCmd = $ExecutionContext.InvokeCommand.GetCommand('Microsoft.PowerShell.Utility\Write-Debug', [System.Management.Automation.CommandTypes]::Cmdlet)
            $scriptCmd = { & $wrappedCmd @PSBoundParameters }
            $steppablePipeline = $scriptCmd.GetSteppablePipeline($myInvocation.CommandOrigin)
            $steppablePipeline.Begin($PSCmdlet)
        } catch {
            throw
        }
    }

    process
    {
        if (-not $NoLog.isPresent) {
            if ((Get-Command 'Write-Log' -ErrorAction 'Ignore') -and ($DebugPreference -ine 'SilentlyContinue')) {
                Write-Log @write_log -Message $Message
            }
        }

        try {
            $steppablePipeline.Process($_)
        } catch {
            throw
        }
    }

    end
    {
        try {
            $steppablePipeline.End()
        } catch {
            throw
        }
    }
    <#

    .ForwardHelpTargetName Microsoft.PowerShell.Utility\Write-Debug
    .ForwardHelpCategory Cmdlet

    #>
}