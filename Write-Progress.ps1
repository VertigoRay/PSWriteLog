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
        ,
        [ValidateScript({[enum]::GetValues([System.ConsoleColor]) -icontains $_})]
        [string]
        ${WriteHostColor}
    )

    begin
    {
        if ($MyInvocation.PSCommandPath) {
            $invo_file = Split-Path $MyInvocation.PSCommandPath -Leaf
        } else {
            $invo_file = Split-Path $MyInvocation.InvocationName -Leaf
        }

        $write_log = @{
            'Severity' = 'Progress'
            'Component' = (& { $PSCallStack = (Get-PSCallStack)[2]; "$($PSCallStack.Command) $($PSCallStack.Arguments)" });
            'Source' = "${invo_file}:$($MyInvocation.ScriptLineNumber)";
        }

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

    process
    {
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

        if (Get-Command 'Write-Log' -ErrorAction 'Ignore') {
            Write-Log @write_log -Message ($Message -join ' ')
        }

        if ($WriteHostColor) {
            Microsoft.PowerShell.Utility\Write-Host -ForegroundColor $WriteHostColor ($Message -join ' ')
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

    .ForwardHelpTargetName Microsoft.PowerShell.Utility\Write-Progress
    .ForwardHelpCategory Cmdlet

    #>
}