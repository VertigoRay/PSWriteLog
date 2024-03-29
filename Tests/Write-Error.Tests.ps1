$script:psProjectRoot = ([IO.DirectoryInfo] $PSScriptRoot).Parent
. ('{0}\PSWriteLog\Private\Write-Log.ps1' -f $psProjectRoot.FullName)
. ('{0}\PSWriteLog\Public\Write-Error.ps1' -f $psProjectRoot.FullName)

Describe 'Write-Error' {
    BeforeAll {
        $script:DefaultLog = "${TestDrive}\Logs\Write-Error.log"
        $script:DefaultLog = [IO.Path]::Combine($env:Temp, ('PowerShell {0} {1} {2}.log' -f $PSVersionTable.PSEdition, $PSVersionTable.PSVersion, $MyInvocation.CommandOrigin))
        # Write-Host ('DefaultLog: {0}' -f $script:DefaultLog) -Fore 'Black' -Back 'Green'
        $script:Message = 'Hello World!!'
        # Write-Host ('Message: {0}' -f $script:Message) -Fore 'Black' -Back 'Green'
    }

    Context 'Write-Error $Message' {
        BeforeAll {
            $script:DefaultLog = [IO.Path]::Combine($env:Temp, ('PowerShell {0} {1} {2}.log' -f $PSVersionTable.PSEdition, $PSVersionTable.PSVersion, $MyInvocation.CommandOrigin))
            # Write-Host ('DefaultLog: {0}' -f $script:DefaultLog) -Fore 'Black' -Back 'Cyan'
            $script:Message = 'Hello World!!'
            # Write-Host ('Message: {0}' -f $script:Message) -Fore 'Black' -Back 'Cyan'
        }

        BeforeEach {
            Remove-Item $script:DefaultLog -Force -ErrorAction 'Ignore' | Out-Null
            # Write-Host ('Message: {0}' -f $script:Message) -Fore 'Black' -Back 'Magenta'
            if (-not $env:CI -and -not $env:APPVEYOR) {
                Write-Error $script:Message 2>&1
            }
        }

        It "Creates ${script:DefaultLog}" {
            if ($env:CI -and $env:APPVEYOR) {
                # Tests skipped because they are not functioning on AppVeyor.
                # Should come back to this later ...
                # Ref: https://ci.appveyor.com/project/VertigoRay/pswritelog/builds/45866181
                Set-ItResult -Skipped -Because 'Tests skipped because they are not functioning on AppVeyor.'
            }
            # Write-Host ('DefaultLog: {0}' -f $script:DefaultLog) -Fore 'Black' -Back 'Yellow'
            $script:DefaultLog | Should -Exist
        }

        It "Writes '${script:Message}' to ${script:DefaultLog}" {
            if ($env:CI -and $env:APPVEYOR) {
                # Tests skipped because they are not functioning on AppVeyor.
                # Should come back to this later ...
                # Ref: https://ci.appveyor.com/project/VertigoRay/pswritelog/builds/45866181
                Set-ItResult -Skipped -Because 'Tests skipped because they are not functioning on AppVeyor.'
            }
            # Write-Host ('DefaultLog: {0}' -f $script:DefaultLog) -Fore 'Black' -Back 'Yellow'
            # Write-Host ('Message: {0}' -f $script:Message) -Fore 'Black' -Back 'Cyan'
            $script:DefaultLog | Should -FileContentMatch ([regex]::Escape($script:Message))
        }
    }
}
