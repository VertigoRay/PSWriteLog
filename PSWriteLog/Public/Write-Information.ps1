function global:Write-Information {
    [CmdletBinding(HelpUri='http://go.microsoft.com/fwlink/?LinkId=525909', RemotingCapability='None')]
    param(
        [Parameter(Mandatory=$true, Position=0)]
        [Alias('Msg')]
        [System.Object]
        ${MessageData},

        [Parameter(Position=1)]
        [string[]]
        ${Tags},

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
                $wrappedCmd = $ExecutionContext.InvokeCommand.GetCommand('Microsoft.PowerShell.Utility\Write-Information', [System.Management.Automation.CommandTypes]::Cmdlet)
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
        if ((Get-Command 'Write-Log' -ErrorAction 'Ignore') -and ($InformationPreference -ine 'SilentlyContinue')) {
            if ($Tags.isPresent) {
                Write-Log @writeLog -Message "$MessageData {$($Tags -join ',')}"
            } else {
                Write-Log @writeLog -Message "$MessageData"
            }
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

    .ForwardHelpTargetName Microsoft.PowerShell.Utility\Write-Information
    .ForwardHelpCategory Cmdlet

    #>
}