function global:Write-Warning {
    [CmdletBinding(HelpUri='http://go.microsoft.com/fwlink/?LinkID=113430', RemotingCapability='None')]
    param(
        [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
        [Alias('Msg')]
        [AllowEmptyString()]
        [string]
        ${Message})

    begin
    {
        if ($MyInvocation.PSCommandPath) {
            $invo_file = Split-Path $MyInvocation.PSCommandPath -Leaf
        } else {
            $invo_file = Split-Path $MyInvocation.InvocationName -Leaf
        }

        $write_log = @{
            'Severity' = 'Warning';
            'Component' = (& { $PSCallStack = (Get-PSCallStack)[2]; "$($PSCallStack.Command) $($PSCallStack.Arguments)" });
            'Source' = "${invo_file}:$($MyInvocation.ScriptLineNumber)";
        }

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

    process
    {
        if ((Get-Command 'Write-Log' -ErrorAction 'Ignore') -and ($WarningPreference -ine 'SilentlyContinue')) {
            Write-Log @write_log -Message $Message
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

    .ForwardHelpTargetName Microsoft.PowerShell.Utility\Write-Warning
    .ForwardHelpCategory Cmdlet

    #>
}