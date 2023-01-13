<#
.DESCRIPTION
    Write a Log Header similar to the one created by `Start-Transcript -IncludeInvocationHeader`:

        **********************
        Windows PowerShell transcript start
        Start time: 20230110191101
        Username: UTSARR\SYSTEM
        RunAs User: UTSARR\SYSTEM
        Configuration Name:
        Machine: RR711111IP01 (Microsoft Windows NT 10.0.19044.0)
        Host Application: C:\WINDOWS\system32\WindowsPowerShell\v1.0\PowerShell.exe -NoLogo -Noninteractive -NoProfile -ExecutionPolicy Bypass & 'C:\WINDOWS\CCM\SystemTemp\861996c9-1d3e-4522-9837-ff30577a8184.ps1' True
        Process ID: 40784
        PSVersion: 5.1.19041.1682
        PSEdition: Desktop
        PSCompatibleVersions: 1.0, 2.0, 3.0, 4.0, 5.0, 5.1.19041.1682
        BuildVersion: 10.0.19041.1682
        CLRVersion: 4.0.30319.42000
        WSManStackVersion: 3.0
        PSRemotingProtocolVersion: 2.3
        SerializationVersion: 1.1.0.1
        **********************
#>
function Get-InvocationHeader {
    [CmdletBinding()]
    param()

    $tmp = New-TemporaryFile
    Start-Transcript -LiteralPath $tmp.FullName -IncludeInvocationHeader -Force | Out-Null
    Stop-Transcript | Out-Null

    $inHeader = $false
    $header = Get-Content $tmp.FullName | ForEach-Object {
        if ($_.StartsWith('*') -and $inHeader) {
            # Reached end of header
            break
        } elseif ($_.StartsWith('*')) {
            # Reached start of header
            $inHeader = $true
        } else {
            # In header
            switch -regex ($_.Trim()) {
                '^Windows PowerShell transcript start' {
                    Write-Output ('PSWriteLog v{0} Invocation Header' -f (Get-Module 'PSWriteLog' | Select-Object -First 1).Version)
                    break
                }
                '^Start time\:\s+' {
                    Write-Output ('Start time: {0}' -f (Get-Date -Format 'O'))
                    break
                }
                default {
                    Write-Output $_
                }
            }
        }
    }

    $tmp.FullName | Remove-Item -ErrorAction 'SilentlyContinue' -Force
    $env:PSWriteLogIncludeInvocationHeader = $null

    return $header
}
