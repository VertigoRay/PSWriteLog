function global:Write-Verbose {
    [CmdletBinding(HelpUri='http://go.microsoft.com/fwlink/?LinkID=113429', RemotingCapability='None')]
    param(
        [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
        [Alias('Msg')]
        [AllowEmptyString()]
        [string]
        ${Message},

        [switch]
        $Silent
    )

    begin
    {
        if ($MyInvocation.PSCommandPath) {
            $invoFile = Split-Path $MyInvocation.PSCommandPath -Leaf
        } else {
            $invoFile = Split-Path $MyInvocation.InvocationName -Leaf
        }

        $writeLog = @{
            'Severity' = 'Verbose';
            'Component' = (& { $PSCallStack = (Get-PSCallStack)[2]; "$($PSCallStack.Command) $($PSCallStack.Arguments)" });
            'Source' = "${invoFile}:$($MyInvocation.ScriptLineNumber)";
        }

        if (-not $Silent) {
            try {
                $outBuffer = $null
                if ($PSBoundParameters.TryGetValue('OutBuffer', [ref]$outBuffer))
                {
                    $PSBoundParameters['OutBuffer'] = 1
                }
                $wrappedCmd = $ExecutionContext.InvokeCommand.GetCommand('Microsoft.PowerShell.Utility\Write-Verbose', [System.Management.Automation.CommandTypes]::Cmdlet)
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
        if ((Get-Command 'Write-Log' -ErrorAction 'Ignore') -and ($VerbosePreference -ine 'SilentlyContinue')) {
            Write-Log @writeLog -Message $Message
        }

        if (-not $Silent) {
            try {
                $steppablePipeline.Process($_)
            } catch {
                throw
            }
        }
    }

    end
    {
        if (-not $Silent) {
            try {
                $steppablePipeline.End()
            } catch {
                throw
            }
        }
    }
    <#

    .ForwardHelpTargetName Microsoft.PowerShell.Utility\Write-Verbose
    .ForwardHelpCategory Cmdlet

    #>
}