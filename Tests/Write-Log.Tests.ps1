$script:psProjectRoot = ([IO.DirectoryInfo] $PSScriptRoot).Parent
. ('{0}\PSWriteLog\Private\Write-Log.ps1' -f $psProjectRoot.FullName)

$VerbosePreference = 'SilentlyContinue'

Describe 'Write-Log with parameters' {
    BeforeAll {
        $script:DefaultLog = "${TestDrive}\Logs\Write-Log.log"
        # Write-Host ('DefaultLog: {0}' -f $script:DefaultLog) -Fore 'Black' -Back 'Green'
        $script:Message = 'Hello World!!'
        # Write-Host ('Message: {0}' -f $script:Message) -Fore 'Black' -Back 'Green'
    }

    Context 'Write-Log $Message ' {
        BeforeAll {
            $script:DefaultLog = [IO.Path]::Combine($env:Temp, ('PowerShell {0} {1} {2}.log' -f $PSVersionTable.PSEdition, $PSVersionTable.PSVersion, $MyInvocation.CommandOrigin))
            # Write-Host ('DefaultLog: {0}' -f $script:DefaultLog) -Fore 'Black' -Back 'Cyan'
            $script:Message = 'Hello World!!'
            # Write-Host ('Message: {0}' -f $script:Message) -Fore 'Black' -Back 'Cyan'
        }

        BeforeEach {
            Remove-Item $script:DefaultLog -Force -ErrorAction 'Ignore' | Out-Null
            # Write-Host ('Message: {0}' -f $script:Message) -Fore 'Black' -Back 'Magenta'
            Write-Log $script:Message
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

    Context 'Write-Log $Message -LogType Legacy' {
        BeforeEach {
            Remove-Item $script:DefaultLog -Force -ErrorAction 'Ignore' | Out-Null
            Write-Log "$script:Message" -LogType Legacy
        }

        It "Creates ${script:DefaultLog}" {
            $script:DefaultLog | Should -Exist
        }

        It "Writes '${script:Message}' to ${script:DefaultLog}" {
            $script:DefaultLog | Should -FileContentMatch ([regex]::Escape($script:Message))
        }

        It "Does not write '<![LOG[' to ${script:DefaultLog}" {
            $script:DefaultLog | Should -Not -FileContentMatch ('^{0}' -f [regex]::Escape('<![LOG['))
        }
    }

    Context 'Write-Log $Message -Severity 1' {
        BeforeEach {
            Remove-Item $script:DefaultLog -Force -ErrorAction 'Ignore' | Out-Null
            Write-Log $script:Message -Severity 1
        }

        It "Writes 'type=`"1`" ' to ${script:DefaultLog}" {
            $script:DefaultLog | Should -FileContentMatch ([regex]::Escape('type="1" '))
        }
    }

    Context 'Write-Log $Message -Severity 1 -LogType Legacy' {
        BeforeEach {
            Remove-Item $script:DefaultLog -Force -ErrorAction 'Ignore' | Out-Null
            Write-Log $script:Message -Severity 1 -LogType Legacy
        }

        It "Writes '[Info]' to ${script:DefaultLog}" {
            $script:DefaultLog | Should -FileContentMatch ([regex]::Escape('[Info]'))
        }
    }

    Context 'Write-Log $Message -Severity 2' {
        BeforeEach {
            Remove-Item $script:DefaultLog -Force -ErrorAction 'Ignore' | Out-Null
            Write-Log $script:Message -Severity 2
        }

        It "Writes 'type=`"2`" ' to ${script:DefaultLog}" {
            $script:DefaultLog | Should -FileContentMatch ([regex]::Escape('type="2" '))
        }
    }

    Context 'Write-Log $Message -Severity 2 -LogType Legacy' {
        BeforeEach {
            Remove-Item $script:DefaultLog -Force -ErrorAction 'Ignore' | Out-Null
            Write-Log $script:Message -Severity 2 -LogType Legacy
        }

        It "Writes '[Warning]' to ${script:DefaultLog}" {
            $script:DefaultLog | Should -FileContentMatch ([regex]::Escape('[Warning]'))
        }
    }

    Context 'Write-Log $Message -Severity 3' {
        BeforeEach {
            Remove-Item $script:DefaultLog -Force -ErrorAction 'Ignore' | Out-Null
            Write-Log $script:Message -Severity 3
        }

        It "Writes 'type=`"3`" ' to ${script:DefaultLog}" {
            $script:DefaultLog | Should -FileContentMatch ([regex]::Escape('type="3" '))
        }
    }

    Context 'Write-Log $Message -Severity 3 -LogType Legacy' {
        BeforeEach {
            Remove-Item $script:DefaultLog -Force -ErrorAction 'Ignore' | Out-Null
            Write-Log $script:Message -Severity 3 -LogType Legacy
        }

        It "Writes '[Error]' to ${script:DefaultLog}" {
            $script:DefaultLog | Should -FileContentMatch ([regex]::Escape('[Error]'))
        }
    }

    Context 'Write-Log $Message -Source HELLO_WORLD' {
        BeforeEach {
            Remove-Item $script:DefaultLog -Force -ErrorAction 'Ignore' | Out-Null
            Write-Log $script:Message -Source HELLO_WORLD
        }

        It "Writes 'file=`"HELLO_WORLD`" ' to ${script:DefaultLog}" {
            $script:DefaultLog | Should -FileContentMatch ([regex]::Escape('file="HELLO_WORLD"'))
        }
    }

    Context 'Write-Log $Message -Source HELLO_WORLD -LogType Legacy' {
        BeforeEach {
            Remove-Item $script:DefaultLog -Force -ErrorAction 'Ignore' | Out-Null
            Write-Log $script:Message -Source HELLO_WORLD -LogType Legacy
        }

        It "Writes '[HELLO_WORLD]' to ${script:DefaultLog}" {
            $script:DefaultLog | Should -FileContentMatch ([regex]::Escape('[HELLO_WORLD]'))
        }
    }

    Context 'Write-Log $Message -Component Pester' {
        BeforeEach {
            Remove-Item $script:DefaultLog -Force -ErrorAction 'Ignore' | Out-Null
            Write-Log $script:Message -Component Pester
        }

        It "Writes 'component=`"Pester`" ' to ${script:DefaultLog}" {
            $script:DefaultLog | Should -FileContentMatch ([regex]::Escape("component=""Pester"""))
        }
    }

    Context 'Write-Log $Message -Component Pester -LogType Legacy' {
        BeforeEach {
            Remove-Item $script:DefaultLog -Force -ErrorAction 'Ignore' | Out-Null
            Write-Log $script:Message -Component Pester -LogType Legacy
        }

        It "Writes '[Pester]' to ${script:DefaultLog}" {
            $script:DefaultLog | Should -FileContentMatch ([regex]::Escape(" [Pester]"))
        }
    }

    Context 'Write-Log $Message -FilePath "$TestDrive\Test.log"' {
        BeforeAll {
            $script:LogFile = [IO.Path]::Combine($TestDrive, 'Test.log')
        }

        BeforeEach {
            Remove-Item $script:DefaultLog -Force -ErrorAction 'Ignore' | Out-Null
            Write-Log $script:Message -FilePath "$TestDrive\Test.log"
        }

        It "Creates ${script:LogFile}" {
            $script:LogFile | Should -Exist
        }

        It "Writes '${script:Message}' to ${script:LogFile}" {
            $script:LogFile | Should -FileContentMatch ([regex]::Escape($script:Message))
        }
    }

    Context 'Write-Log $Message -FilePath "$TestDrive\Test.log" -LogType Legacy' {
        BeforeAll {
            $script:LogFile = [IO.Path]::Combine($TestDrive, 'Test.log')
        }

        BeforeEach {
            Remove-Item $script:DefaultLog -Force -ErrorAction 'Ignore' | Out-Null
            Write-Log $script:Message -FilePath "$TestDrive\Test.log" -LogType Legacy
        }

        It "Creates ${script:LogFile}" {
            $script:LogFile | Should -Exist
        }

        It "Writes '${script:Message}' to ${script:LogFile}" {
            $script:LogFile | Should -FileContentMatch ([regex]::Escape($script:Message))
        }
    }

    Context 'Write-Log $Message -FilePath "$TestDrive\Test.log" -MaxLogFileSizeMB .1' {
        BeforeAll {
            [IO.FileInfo] $script:LogFile = [IO.Path]::Combine($TestDrive, 'Test.log')
            [IO.FileInfo] $script:LogFileArchived = $([IO.Path]::ChangeExtension($LogFile, 'lo_'))
        }

        BeforeEach {
            Do {
                Write-Log $script:Message -FilePath $script:LogFile.FullName -MaxLogFileSizeMB .1
                $script:LogFile.Refresh()
            } Until ($script:LogFile.Length -gt .1MB)
        }

        It "Creates ${script:LogFileArchived}" {
            Write-Log $script:Message -FilePath $script:LogFile.FullName -MaxLogFileSizeMB .1
            $script:LogFile.Refresh()
            $script:LogFileArchived | Should -Exist
        }

        It "The new '${script:LogFile}' is now very small." {
            Write-Log $script:Message -FilePath $script:LogFile.FullName -MaxLogFileSizeMB .1
            $script:LogFile.Refresh()
            [int] ($script:LogFile.Length/1KB) | Should -Be 0
        }
    }

    Context 'Write-Log $Message -WriteHost $true' {
        Mock Write-Host { return $script:Message }

        It "Should write to host" {
            Write-Log $script:Message -WriteHost $true | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Write-Log $Message -ContinueOnError $false' {
        Mock Write-Host { return $script:Message }

        It "Should not return an error" {
            Write-Log $script:Message | Should -BeNullOrEmpty
        }

        It "Should return an error" {
            Write-Log $script:Message -ContinueOnError $false | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Write-Log $Message -PassThru' {
        It "Should return '$script:Message'" {
            Write-Log $script:Message -PassThru $true | Should -BeExactly $script:Message
        }
    }

    Context 'Write-Log $Message -DebugMessage' {
        BeforeEach {
            Remove-Item $script:DefaultLog -Force -ErrorAction 'Ignore' | Out-Null
            Write-Log $script:Message -DebugMessage
        }

        It "Should not create the log file '$script:DefaultLog'" {
            $script:DefaultLog | Should -Not Exist
        }
    }

    Context 'Write-Log $Message -DebugMessage -LogDebugMessage $true' {
        BeforeEach {
            Remove-Item $script:DefaultLog -Force -ErrorAction 'Ignore' | Out-Null
            Write-Log $script:Message -DebugMessage -LogDebugMessage $true
        }

        It "Should create the log file '$script:DefaultLog'" {
            $script:DefaultLog | Should -Exist
        }
    }
}

Describe 'Write-Log with $env:Write-Log' {
    BeforeAll {
        $script:DefaultLog = "${env:SystemRoot}\Logs\Write-Log.log"
        $script:Message = 'Hello World!!'
    }

    AfterEach {
        @(
            $script:DefaultLog,
            "${TestDrive}\$(Split-Path $script:DefaultLog -Leaf)",
            "${TestDrive}\Test.log",
            "${TestDrive}\Test.lo_"
        ) | ForEach-Object {
            if (Test-Path $_) {
                $File = [IO.FileInfo] (Get-ChildItem -Path $_ -ErrorAction 'Stop')
                if ($File.Length -lt 1000) {
                    Write-Verbose "Content of '${_}':`n$([IO.File]::ReadAllText($_))"
                } else {
                    Write-Verbose "Size of '${_}': $($File.Length)"
                    Write-Verbose "Last line of '${_}':`n$((Get-Content $_)[-1])"
                }
                Write-Verbose "Deleting '${_}'"
                Remove-Item $_ -Force
            }
        }

        if (Test-Path Env:\Write-Log) {
            Write-Verbose "Deleting `$env:Write-Log: ${env:Write-Log}"
            Remove-Item Env:\Write-Log -Force
        }
    }

    Context 'Write-Log $Message ' {
        BeforeEach {
            Remove-Item $script:DefaultLog -Force -ErrorAction 'Ignore' | Out-Null
            Write-Log $script:Message
        }

        It "Creates ${script:DefaultLog}" {
            $script:DefaultLog | Should -Exist
        }

        It "Writes '${script:Message}' to ${script:DefaultLog}" {
            $script:DefaultLog | Should -FileContentMatch ([regex]::Escape($script:Message))
        }
    }

    Context 'Write-Log $Message -LogType Legacy' {
        BeforeEach {
            ${env:Write-Log} = ConvertTo-Json @{'LogType'='Legacy'} -Compress
            Write-Log $script:Message
        }

        It "Creates ${script:DefaultLog}" {
            $script:DefaultLog | Should -Exist
        }

        It "Writes '${script:Message}' to ${script:DefaultLog}" {
            $script:DefaultLog | Should -FileContentMatch ([regex]::Escape($script:Message))
        }

        It "Does not writes '<![LOG[' to ${script:DefaultLog}" {
            $script:DefaultLog | Should -Not -FileContentMatch ([regex]::Escape('<![LOG['))
        }
    }

    Context 'Write-Log $Message -Severity 1' {
        BeforeEach {
            ${env:Write-Log} = ConvertTo-Json @{'Severity'=1} -Compress
            Write-Log $script:Message
        }

        It "Writes 'type=`"1`" ' to ${script:DefaultLog}" {
            $script:DefaultLog | Should -FileContentMatch ([regex]::Escape('type="1" '))
        }
    }

    Context 'Write-Log $Message -Severity 1 -LogType Legacy' {
        BeforeEach {
            ${env:Write-Log} = ConvertTo-Json @{'Severity'=1; 'LogType'='Legacy'} -Compress
            Write-Log $script:Message
        }

        It "Writes '[Info]' to ${script:DefaultLog}" {
            $script:DefaultLog | Should -FileContentMatch ([regex]::Escape('[Info]'))
        }
    }

    Context 'Write-Log $Message -Severity 2' {
        BeforeEach {
            ${env:Write-Log} = ConvertTo-Json @{'Severity'=2} -Compress
            Write-Log $script:Message
        }

        It "Writes 'type=`"2`" ' to ${script:DefaultLog}" {
            $script:DefaultLog | Should -FileContentMatch ([regex]::Escape('type="2" '))
        }
    }

    Context 'Write-Log $Message -Severity 2 -LogType Legacy' {
        BeforeEach {
            ${env:Write-Log} = ConvertTo-Json @{'Severity'=2; 'LogType'='Legacy'} -Compress
            Write-Log $script:Message
        }

        It "Writes '[Warning]' to ${script:DefaultLog}" {
            $script:DefaultLog | Should -FileContentMatch ([regex]::Escape('[Warning]'))
        }
    }

    Context 'Write-Log $Message -Severity 3' {
        BeforeEach {
            ${env:Write-Log} = ConvertTo-Json @{'Severity'=3} -Compress
            Write-Log $script:Message
        }

        It "Writes 'type=`"3`" ' to ${script:DefaultLog}" {
            $script:DefaultLog | Should -FileContentMatch ([regex]::Escape('type="3" '))
        }
    }

    Context 'Write-Log $Message -Severity 3 -LogType Legacy' {
        BeforeEach {
            ${env:Write-Log} = ConvertTo-Json @{'Severity'=3; 'LogType'='Legacy'} -Compress
            Write-Log $script:Message
        }

        It "Writes '[Error]' to ${script:DefaultLog}" {
            $script:DefaultLog | Should -FileContentMatch ([regex]::Escape('[Error]'))
        }
    }

    Context 'Write-Log $Message -Source HELLO_WORLD' {
        BeforeEach {
            ${env:Write-Log} = ConvertTo-Json @{'Source'='HELLO_WORLD'} -Compress
            Write-Log $script:Message
        }

        It "Writes 'file=`"HELLO_WORLD`" ' to ${script:DefaultLog}" {
            $script:DefaultLog | Should -FileContentMatch ([regex]::Escape('file="HELLO_WORLD"'))
        }
    }

    Context 'Write-Log $Message -Source HELLO_WORLD -LogType Legacy' {
        BeforeEach {
            ${env:Write-Log} = ConvertTo-Json @{'Source'='HELLO_WORLD'; 'LogType'='Legacy'} -Compress
            Write-Log $script:Message
        }

        It "Writes '[HELLO_WORLD]' to ${script:DefaultLog}" {
            $script:DefaultLog | Should -FileContentMatch ([regex]::Escape('[HELLO_WORLD]'))
        }
    }

    Context 'Write-Log $Message -Component Pester' {
        BeforeEach {
            ${env:Write-Log} = ConvertTo-Json @{'Component'='Pester'} -Compress
            Write-Log $script:Message
        }

        It "Writes 'component=`"Pester`" ' to ${script:DefaultLog}" {
            $script:DefaultLog | Should -FileContentMatch ([regex]::Escape("component=""Pester"""))
        }
    }

    Context 'Write-Log $Message -Component Pester -LogType Legacy' {
        BeforeEach {
            ${env:Write-Log} = ConvertTo-Json @{'Component'='Pester'; 'LogType'='Legacy'} -Compress
            Write-Log $script:Message
        }

        It "Writes '[Pester]' to ${script:DefaultLog}" {
            $script:DefaultLog | Should -FileContentMatch ([regex]::Escape(" [Pester]"))
        }
    }

    Context 'Write-Log $Message -LogFileDirectory $TestDrive' {
        BeforeAll {
            $script:LogFile = "${TestDrive}\$(Split-Path $script:DefaultLog -Leaf)"
        }

        BeforeEach {
            ${env:Write-Log} = ConvertTo-Json @{'LogFileDirectory'=$TestDrive} -Compress
            Write-Log $script:Message
        }

        It "Creates ${script:LogFile}" {
            $script:LogFile | Should -Exist
        }

        It "Writes '${script:Message}' to ${script:LogFile}" {
            $script:LogFile | Should -FileContentMatch ([regex]::Escape($script:Message))
        }
    }

    Context 'Write-Log $Message -LogFileDirectory $TestDrive -LogType Legacy' {
        BeforeAll {
            $script:LogFile = "${TestDrive}\$(Split-Path $script:DefaultLog -Leaf)"
        }

        BeforeEach {
            ${env:Write-Log} = ConvertTo-Json @{'LogFileDirectory'=$TestDrive; 'LogType'='Legacy'} -Compress
            Write-Log $script:Message
        }

        It "Creates ${script:LogFile}" {
            $script:LogFile | Should -Exist
        }

        It "Writes '${script:Message}' to ${script:LogFile}" {
            $script:LogFile | Should -FileContentMatch ([regex]::Escape($script:Message))
        }
    }

    Context 'Write-Log $Message -FilePath "$TestDrive\Test.log"' {
        BeforeAll {
            $script:LogFile = [IO.Path]::Combine($TestDrive, 'Test.log')
        }

        BeforeEach {
            ${env:Write-Log} = ConvertTo-Json @{'LogFileDirectory'=$TestDrive; 'LogFileName'='Test.log'} -Compress
            Write-Log $script:Message
        }

        It "Creates ${script:LogFile}" {
            $script:LogFile | Should -Exist
        }

        It "Writes '${script:Message}' to ${script:LogFile}" {
            $script:LogFile | Should -FileContentMatch ([regex]::Escape($script:Message))
        }
    }

    Context 'Write-Log $Message -FilePath "$TestDrive\Test.log" -LogType Legacy' {
        BeforeAll {
            $script:LogFile = [IO.Path]::Combine($TestDrive, 'Test.log')
        }

        BeforeEach {
            ${env:Write-Log} = ConvertTo-Json @{'LogFileDirectory'=$TestDrive; 'LogFileName'='Test.log'; 'LogType'='Legacy'} -Compress
            Write-Log $script:Message
        }

        It "Creates ${script:LogFile}" {
            $script:LogFile | Should -Exist
        }

        It "Writes '${script:Message}' to ${script:LogFile}" {
            $script:LogFile | Should -FileContentMatch ([regex]::Escape($script:Message))
        }
    }

    Context 'Write-Log $Message -FilePath "$TestDrive\Test.log" -MaxLogFileSizeMB .1' {
        BeforeAll {
            $script:LogFile = [IO.Path]::Combine($TestDrive, 'Test.log')
            $LogFileArchived = $([IO.Path]::ChangeExtension($LogFile, 'lo_'))
        }

        BeforeEach {
            Do {
                Write-Log $script:Message -FilePath "$TestDrive\Test.log" -MaxLogFileSizeMB 0
            } Until (([IO.FileInfo] (Get-ChildItem -Path $script:LogFile -ErrorAction 'Stop')).Length -gt .1MB)
        }

        It "Creates ${LogFileArchived}" {
            ${env:Write-Log} = ConvertTo-Json @{'LogFileDirectory'=$TestDrive; 'LogFileName'='Test.log'; 'MaxLogFileSizeMB'=.1} -Compress
            Write-Log $script:Message
            $LogFileArchived | Should -Exist
        }

        It "The new '${script:LogFile}' is now very small." {
            ${env:Write-Log} = ConvertTo-Json @{'LogFileDirectory'=$TestDrive; 'LogFileName'='Test.log'; 'MaxLogFileSizeMB'=.1} -Compress
            Write-Log $script:Message
            [int](([IO.FileInfo] (Get-ChildItem -Path $script:LogFile -ErrorAction 'Stop')).Length/1KB) | Should -Be 0
        }
    }

    Context 'Write-Log $Message -WriteHost $true' {
        BeforeAll {
            ${env:Write-Log} = ConvertTo-Json @{'WriteHost'=$true} -Compress
        }

        Mock Write-Host { return $script:Message }

        It "Should write to host" {
            Write-Log $script:Message | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Write-Log $Message -ContinueOnError $false' {
        Mock Write-Host { return $script:Message }

        It "Should not return an error" {
            ${env:Write-Log} = ConvertTo-Json @{'LogFileDirectory'='C:\C:\Temp'} -Compress
            Write-Log $script:Message | Should -BeNullOrEmpty
        }

        It "Should return an error" {
            ${env:Write-Log} = ConvertTo-Json @{'LogFileDirectory'='C:\C:\Temp'; 'ContinueOnError'=$false} -Compress
            Write-Log $script:Message | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Write-Log $Message -PassThru' {
        It "Should return '$script:Message'" {
            ${env:Write-Log} = ConvertTo-Json @{'PassThru'=$true} -Compress
            Write-Log $script:Message | Should -BeExactly $script:Message
        }
    }

    Context 'Write-Log $Message -DebugMessage' {
        BeforeEach {
            ${env:Write-Log} = ConvertTo-Json @{'DebugMessage'=$true} -Compress
            Write-Log $script:Message
        }

        It "Should not create the log file '$script:DefaultLog'" {
            $script:DefaultLog | Should -Not Exist
        }
    }

    Context 'Write-Log $Message -DebugMessage -LogDebugMessage $true' {
        BeforeEach {
            ${env:Write-Log} = ConvertTo-Json @{'DebugMessage'=$true; 'LogDebugMessage'=$true} -Compress
            Write-Log $script:Message
        }

        It "Should create the log file '$script:DefaultLog'" {
            $script:DefaultLog | Should -Exist
        }
    }
}