function global:Write-Host {
    [CmdletBinding(HelpUri='http://go.microsoft.com/fwlink/?LinkID=113426', RemotingCapability='None')]
    param(
        [Parameter(Position=0, ValueFromPipeline=$true, ValueFromRemainingArguments=$true)]
        [System.Object]
        ${Object},

        [switch]
        ${NoNewline},

        [System.Object]
        ${Separator},

        [System.ConsoleColor]
        ${ForegroundColor},

        [System.ConsoleColor]
        ${BackgroundColor}
    )

    begin
    {
        if ($MyInvocation.PSCommandPath) {
            $invoFile = Split-Path $MyInvocation.PSCommandPath -Leaf
        } else {
            $invoFile = Split-Path $MyInvocation.InvocationName -Leaf
        }

        $writeLog = @{
            'Component' = (& { $PSCallStack = (Get-PSCallStack)[2]; "$($PSCallStack.Command) $($PSCallStack.Arguments)" });
            'Source' = "${invoFile}:$($MyInvocation.ScriptLineNumber)";
        }

        if (-not ($env:PSWriteLogHostSilent -as [bool])) {
            try {
                $outBuffer = $null
                if ($PSBoundParameters.TryGetValue('OutBuffer', [ref]$outBuffer))
                {
                    $PSBoundParameters['OutBuffer'] = 1
                }
                $wrappedCmd = $ExecutionContext.InvokeCommand.GetCommand('Microsoft.PowerShell.Utility\Write-Host', [System.Management.Automation.CommandTypes]::Cmdlet)
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
        if (Get-Command 'Write-Log' -ErrorAction 'Ignore') {
            Write-Log @writeLog -Message $Object
        }

        if (-not ($env:PSWriteLogHostSilent -as [bool])) {
            try {
                $steppablePipeline.Process($_)
            } catch {
                throw
            }
        }
    }

    end
    {
        if (-not ($env:PSWriteLogHostSilent -as [bool])) {
            try {
                $steppablePipeline.End()
            } catch {
                throw
            }
        }
    }
    <#

    .ForwardHelpTargetName Microsoft.PowerShell.Utility\Write-Host
    .ForwardHelpCategory Cmdlet

    #>
}
