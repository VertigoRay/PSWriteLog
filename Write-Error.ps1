function global:Write-Error {
    [CmdletBinding(DefaultParameterSetName='NoException', HelpUri='http://go.microsoft.com/fwlink/?LinkID=113425', RemotingCapability='None')]
    param(
        [Parameter(ParameterSetName='WithException', Mandatory=$true)]
        [System.Exception]
        ${Exception},

        [Parameter(ParameterSetName='NoException', Mandatory=$true, Position=0, ValueFromPipeline=$true)]
        [Parameter(ParameterSetName='WithException')]
        [Alias('Msg')]
        [AllowEmptyString()]
        [AllowNull()]
        [string]
        ${Message},

        [Parameter(ParameterSetName='ErrorRecord', Mandatory=$true)]
        [System.Management.Automation.ErrorRecord]
        ${ErrorRecord},

        [Parameter(ParameterSetName='NoException')]
        [Parameter(ParameterSetName='WithException')]
        [System.Management.Automation.ErrorCategory]
        ${Category},

        [Parameter(ParameterSetName='NoException')]
        [Parameter(ParameterSetName='WithException')]
        [string]
        ${ErrorId},

        [Parameter(ParameterSetName='WithException')]
        [Parameter(ParameterSetName='NoException')]
        [System.Object]
        ${TargetObject},

        [string]
        ${RecommendedAction},

        [Alias('Activity')]
        [string]
        ${CategoryActivity},

        [Alias('Reason')]
        [string]
        ${CategoryReason},

        [Alias('TargetName')]
        [string]
        ${CategoryTargetName},

        [Alias('TargetType')]
        [string]
        ${CategoryTargetType})

    begin
    {
        if ($MyInvocation.PSCommandPath) {
            $invo_file = Split-Path $MyInvocation.PSCommandPath -Leaf
        } else {
            $invo_file = Split-Path $MyInvocation.InvocationName -Leaf
        }

        $write_log = @{
            'Severity' = 'Error';
            'Component' = (& { $PSCallStack = (Get-PSCallStack)[2]; "$($PSCallStack.Command) $($PSCallStack.Arguments)" });
            'Source' = "${invo_file}:$($MyInvocation.ScriptLineNumber)";
        }

        try {
            $outBuffer = $null
            if ($PSBoundParameters.TryGetValue('OutBuffer', [ref]$outBuffer))
            {
                $PSBoundParameters['OutBuffer'] = 1
            }
            $wrappedCmd = $ExecutionContext.InvokeCommand.GetCommand('Microsoft.PowerShell.Utility\Write-Error', [System.Management.Automation.CommandTypes]::Cmdlet)
            $scriptCmd = {& $wrappedCmd @PSBoundParameters }
            $steppablePipeline = $scriptCmd.GetSteppablePipeline($myInvocation.CommandOrigin)
            $steppablePipeline.Begin($PSCmdlet)
        } catch {
            throw
        }
    }

    process
    {
        if (Get-Command 'Write-Log' -ErrorAction 'Ignore') {
            [System.Collections.ArrayList] $msg = @()

            if ($PSBoundParameters.ContainsKey('ErrorRecord')) {
                $msg.Add("[$($ErrorRecord.Exception.GetType().FullName)]") | Out-Null
                $msg.Add($ErrorRecord.Exception.Message) | Out-Null
            } elseif ($PSBoundParameters.ContainsKey('Exception')) {
                $msg.Add("[${Exception}]") | Out-Null
                $msg.Add($Message) | Out-Null
            } else {
                $msg.Add($Message) | Out-Null
            }

            if (
                $Category.isPresent -or
                $ErrorId.isPresent -or
                $TargetObject.isPresent -or
                $RecommendedAction.isPresent -or
                $CategoryActivity.isPresent -or
                $CategoryReason.isPresent -or
                $CategoryTargetName.isPresent -or
                $CategoryTargetType.isPresent
            ) {
                $msg.Add("`nError Details As Json: $($PSBoundParameters | ConvertTo-Json)") | Out-Null
            }

            Write-Log @write_log -Message ($msg -join ' ') -ErrorAction 'Stop'
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

        Write-Verbose "Write-Error Done!"
    }
    <#

    .ForwardHelpTargetName Microsoft.PowerShell.Utility\Write-Error
    .ForwardHelpCategory Cmdlet

    #>
}