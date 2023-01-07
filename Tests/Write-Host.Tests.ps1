$script:psProjectRoot = ([IO.DirectoryInfo] $PSScriptRoot).Parent
. ('{0}\PSWriteLog\Private\Write-Log.ps1' -f $psProjectRoot.FullName)
. ('{0}\PSWriteLog\Public\Write-Host.ps1' -f $psProjectRoot.FullName)

Describe 'Write-Host' {
    BeforeAll {
        $script:DefaultLog = "${TestDrive}\Logs\Write-Host.log"
        $script:DefaultLog = [IO.Path]::Combine($env:Temp, ('PowerShell {0} {1} {2}.log' -f $PSVersionTable.PSEdition, $PSVersionTable.PSVersion, $MyInvocation.CommandOrigin))
        # Write-Host ('DefaultLog: {0}' -f $script:DefaultLog) -Fore 'Black' -Back 'Green'
        $script:Message = 'Hello World!!'
        # Write-Host ('Message: {0}' -f $script:Message) -Fore 'Black' -Back 'Green'
    }

    Context 'Write-Host $Message' {
        BeforeAll {
            $script:DefaultLog = [IO.Path]::Combine($env:Temp, ('PowerShell {0} {1} {2}.log' -f $PSVersionTable.PSEdition, $PSVersionTable.PSVersion, $MyInvocation.CommandOrigin))
            # Write-Host ('DefaultLog: {0}' -f $script:DefaultLog) -Fore 'Black' -Back 'Cyan'
            $script:Message = 'Hello World!!'
            # Write-Host ('Message: {0}' -f $script:Message) -Fore 'Black' -Back 'Cyan'
        }

        BeforeEach {
            Remove-Item $script:DefaultLog -Force -ErrorAction 'Ignore' | Out-Null
            # Write-Host ('Message: {0}' -f $script:Message) -Fore 'Black' -Back 'Magenta'
            Write-Host $script:Message
        }

        It "Creates ${script:DefaultLog}" {
            # Write-Host ('DefaultLog: {0}' -f $script:DefaultLog) -Fore 'Black' -Back 'Yellow'
            $script:DefaultLog | Should -Exist
        }

        It "Writes '${script:Message}' to ${script:DefaultLog}" {
            # Write-Host ('DefaultLog: {0}' -f $script:DefaultLog) -Fore 'Black' -Back 'Yellow'
            # Write-Host ('Message: {0}' -f $script:Message) -Fore 'Black' -Back 'Cyan'
            $script:DefaultLog | Should -FileContentMatch ([regex]::Escape($script:Message))
        }
    }
}
