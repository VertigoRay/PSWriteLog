# Documentation: https://git.cas.unt.edu/posh/write-log/wikis/WriteLog-Tests

$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path).Replace(".Tests.", ".")
. "$here\$sut"

$VerbosePreference = 'SilentlyContinue'
# $VerbosePreference = 'Continue'

Describe 'Write-Log with parameters' {
    $DefaultLog = "${env:SystemRoot}\Logs\Write-Log.log"
    $Message = 'Hello World!!'

    AfterEach {
        @(
            $DefaultLog,
            "${env:Temp}\$(Split-Path $DefaultLog -Leaf)",
            "${env:Temp}\Test.log",
            "${env:Temp}\Test.lo_"
        ) | %{
            if (Test-Path $_) {
                $File = [System.IO.FileInfo](Get-ChildItem -Path $_ -ErrorAction 'Stop')
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
    }

    Context 'Write-Log $Message ' {
        BeforeEach {
            Write-Log $Message
        }

        It "Creates ${DefaultLog}" {
            $DefaultLog | Should Exist
        }

        It "Writes '${Message}' to ${DefaultLog}" {
            $DefaultLog | Should ContainExactly ([regex]::Escape($Message))
        }
    }

    Context 'Write-Log $Message -LogType Legacy' {
        BeforeEach {
            Write-Log $Message -LogType Legacy
        }

        It "Creates ${DefaultLog}" {
            $DefaultLog | Should Exist
        }

        It "Writes '${Message}' to ${DefaultLog}" {
            $DefaultLog | Should ContainExactly ([regex]::Escape($Message))
        }

        It "Does not writes '<![LOG[' to ${DefaultLog}" {
            $DefaultLog | Should Not ContainExactly ([regex]::Escape('<![LOG['))
        }
    }

    Context 'Write-Log $Message -Severity 1' {
        BeforeEach {
            Write-Log $Message -Severity 1
        }

        It "Writes 'type=`"1`" ' to ${DefaultLog}" {
            $DefaultLog | Should ContainExactly ([regex]::Escape('type="1" '))
        }
    }

    Context 'Write-Log $Message -Severity 1 -LogType Legacy' {
        BeforeEach {
            Write-Log $Message -Severity 1 -LogType Legacy
        }

        It "Writes '[Info]' to ${DefaultLog}" {
            $DefaultLog | Should ContainExactly ([regex]::Escape('[Info]'))
        }
    }

    Context 'Write-Log $Message -Severity 2' {
        BeforeEach {
            Write-Log $Message -Severity 2
        }

        It "Writes 'type=`"2`" ' to ${DefaultLog}" {
            $DefaultLog | Should ContainExactly ([regex]::Escape('type="2" '))
        }
    }

    Context 'Write-Log $Message -Severity 2 -LogType Legacy' {
        BeforeEach {
            Write-Log $Message -Severity 2 -LogType Legacy
        }

        It "Writes '[Warning]' to ${DefaultLog}" {
            $DefaultLog | Should ContainExactly ([regex]::Escape('[Warning]'))
        }
    }

    Context 'Write-Log $Message -Severity 3' {
        BeforeEach {
            Write-Log $Message -Severity 3
        }

        It "Writes 'type=`"3`" ' to ${DefaultLog}" {
            $DefaultLog | Should ContainExactly ([regex]::Escape('type="3" '))
        }
    }

    Context 'Write-Log $Message -Severity 3 -LogType Legacy' {
        BeforeEach {
            Write-Log $Message -Severity 3 -LogType Legacy
        }

        It "Writes '[Error]' to ${DefaultLog}" {
            $DefaultLog | Should ContainExactly ([regex]::Escape('[Error]'))
        }
    }

    Context 'Write-Log $Message -Source HELLO_WORLD' {
        BeforeEach {
            Write-Log $Message -Source HELLO_WORLD
        }

        It "Writes 'file=`"HELLO_WORLD`" ' to ${DefaultLog}" {
            $DefaultLog | Should ContainExactly ([regex]::Escape('file="HELLO_WORLD"'))
        }
    }

    Context 'Write-Log $Message -Source HELLO_WORLD -LogType Legacy' {
        BeforeEach {
            Write-Log $Message -Source HELLO_WORLD -LogType Legacy
        }

        It "Writes '[HELLO_WORLD]' to ${DefaultLog}" {
            $DefaultLog | Should ContainExactly ([regex]::Escape('[HELLO_WORLD]'))
        }
    }

    Context 'Write-Log $Message -Component Pester' {
        BeforeEach {
            Write-Log $Message -Component Pester
        }

        It "Writes 'component=`"Pester`" ' to ${DefaultLog}" {
            $DefaultLog | Should ContainExactly ([regex]::Escape("component=""Pester"""))
        }
    }

    Context 'Write-Log $Message -Component Pester -LogType Legacy' {
        BeforeEach {
            Write-Log $Message -Component Pester -LogType Legacy
        }

        It "Writes '[Pester]' to ${DefaultLog}" {
            $DefaultLog | Should ContainExactly ([regex]::Escape(" [Pester]"))
        }
    }

    Context 'Write-Log $Message -LogFileDirectory $env:Temp' {
        $LogFile = "${env:Temp}\$(Split-Path $DefaultLog -Leaf)"

        BeforeEach {
            Write-Log $Message -LogFileDirectory $env:Temp
        }

        It "Creates ${LogFile}" {
            $LogFile | Should Exist
        }

        It "Writes '${Message}' to ${LogFile}" {
            $LogFile | Should ContainExactly ([regex]::Escape($Message))
        }
    }

    Context 'Write-Log $Message -LogFileDirectory $env:Temp -LogType Legacy' {
        $LogFile = "${env:Temp}\$(Split-Path $DefaultLog -Leaf)"

        BeforeEach {
            Write-Log $Message -LogFileDirectory $env:Temp -LogType Legacy
        }

        It "Creates ${LogFile}" {
            $LogFile | Should Exist
        }

        It "Writes '${Message}' to ${LogFile}" {
            $LogFile | Should ContainExactly ([regex]::Escape($Message))
        }
    }

    Context 'Write-Log $Message -LogFileDirectory $env:Temp -LogFileName Test.log' {
        $LogFile = Join-Path -Path $env:Temp -ChildPath Test.log

        BeforeEach {
            Write-Log $Message -LogFileDirectory $env:Temp -LogFileName Test.log
        }

        It "Creates ${LogFile}" {
            $LogFile | Should Exist
        }

        It "Writes '${Message}' to ${LogFile}" {
            $LogFile | Should ContainExactly ([regex]::Escape($Message))
        }
    }

    Context 'Write-Log $Message -LogFileDirectory $env:Temp -LogFileName Test.log -LogType Legacy' {
        $LogFile = Join-Path -Path $env:Temp -ChildPath Test.log

        BeforeEach {
            Write-Log $Message -LogFileDirectory $env:Temp -LogFileName Test.log -LogType Legacy
        }

        It "Creates ${LogFile}" {
            $LogFile | Should Exist
        }

        It "Writes '${Message}' to ${LogFile}" {
            $LogFile | Should ContainExactly ([regex]::Escape($Message))
        }
    }

    Context 'Write-Log $Message -LogFileDirectory $env:Temp -LogFileName Test.log -MaxLogFileSizeMB .1' {
        $LogFile = Join-Path -Path $env:Temp -ChildPath Test.log
        $LogFileArchived = $([System.IO.Path]::ChangeExtension($LogFile, 'lo_'))

        BeforeEach {
            Do {
                Write-Log $Message -LogFileDirectory $env:Temp -LogFileName Test.log -MaxLogFileSizeMB 0
            } Until (([System.IO.FileInfo](Get-ChildItem -Path $LogFile -ErrorAction 'Stop')).Length -gt .1MB)
        }

        It "Creates ${LogFileArchived}" {
            Write-Log $Message -LogFileDirectory $env:Temp -LogFileName Test.log -MaxLogFileSizeMB .1
            $LogFileArchived | Should Exist
        }

        It "The new '${LogFile}' is now very small." {
            Write-Log $Message -LogFileDirectory $env:Temp -LogFileName Test.log -MaxLogFileSizeMB .1
            [int](([System.IO.FileInfo](Get-ChildItem -Path $LogFile -ErrorAction 'Stop')).Length/1KB) | Should Be 0
        }
    }

    Context 'Write-Log $Message -WriteHost $true' {
        Mock Write-Host { return $Message }

        It "Should write to host" {
            Write-Log $Message -WriteHost $true | Should Not BeNullOrEmpty
        }
    }

    Context 'Write-Log $Message -ContinueOnError $false' {
        Mock Write-Host { return $Message }

        It "Should not return an error" {
            Write-Log $Message -LogFileDirectory C:\C:\Temp | Should BeNullOrEmpty
        }

        It "Should return an error" {
            Write-Log $Message -LogFileDirectory C:\C:\Temp -ContinueOnError $false | Should Not BeNullOrEmpty
        }
    }

    Context 'Write-Log $Message -PassThru' {
        It "Should return '$Message'" {
            Write-Log $Message -PassThru $true | Should BeExactly $Message
        }
    }

    Context 'Write-Log $Message -DebugMessage' {
        BeforeEach {
            Write-Log $Message -DebugMessage
        }

        It "Should not create the log file '$DefaultLog'" {
            $DefaultLog | Should Not Exist
        }
    }

    Context 'Write-Log $Message -DebugMessage -LogDebugMessage $true' {
        BeforeEach {
            Write-Log $Message -DebugMessage -LogDebugMessage $true
        }

        It "Should create the log file '$DefaultLog'" {
            $DefaultLog | Should Exist
        }
    }
}

Describe 'Write-Log with $env:Write-Log' {
    $DefaultLog = "${env:SystemRoot}\Logs\Write-Log.log"
    $Message = 'Hello World!!'

    AfterEach {
        @(
            $DefaultLog,
            "${env:Temp}\$(Split-Path $DefaultLog -Leaf)",
            "${env:Temp}\Test.log",
            "${env:Temp}\Test.lo_"
        ) | %{
            if (Test-Path $_) {
                $File = [System.IO.FileInfo](Get-ChildItem -Path $_ -ErrorAction 'Stop')
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
            Write-Log $Message
        }

        It "Creates ${DefaultLog}" {
            $DefaultLog | Should Exist
        }

        It "Writes '${Message}' to ${DefaultLog}" {
            $DefaultLog | Should ContainExactly ([regex]::Escape($Message))
        }
    }

    Context 'Write-Log $Message -LogType Legacy' {
        BeforeEach {
            ${env:Write-Log} = ConvertTo-Json @{'LogType'='Legacy'} -Compress
            Write-Log $Message
        }

        It "Creates ${DefaultLog}" {
            $DefaultLog | Should Exist
        }

        It "Writes '${Message}' to ${DefaultLog}" {
            $DefaultLog | Should ContainExactly ([regex]::Escape($Message))
        }

        It "Does not writes '<![LOG[' to ${DefaultLog}" {
            $DefaultLog | Should Not ContainExactly ([regex]::Escape('<![LOG['))
        }
    }

    Context 'Write-Log $Message -Severity 1' {
        BeforeEach {
            ${env:Write-Log} = ConvertTo-Json @{'Severity'=1} -Compress
            Write-Log $Message
        }

        It "Writes 'type=`"1`" ' to ${DefaultLog}" {
            $DefaultLog | Should ContainExactly ([regex]::Escape('type="1" '))
        }
    }

    Context 'Write-Log $Message -Severity 1 -LogType Legacy' {
        BeforeEach {
            ${env:Write-Log} = ConvertTo-Json @{'Severity'=1; 'LogType'='Legacy'} -Compress
            Write-Log $Message
        }

        It "Writes '[Info]' to ${DefaultLog}" {
            $DefaultLog | Should ContainExactly ([regex]::Escape('[Info]'))
        }
    }

    Context 'Write-Log $Message -Severity 2' {
        BeforeEach {
            ${env:Write-Log} = ConvertTo-Json @{'Severity'=2} -Compress
            Write-Log $Message
        }

        It "Writes 'type=`"2`" ' to ${DefaultLog}" {
            $DefaultLog | Should ContainExactly ([regex]::Escape('type="2" '))
        }
    }

    Context 'Write-Log $Message -Severity 2 -LogType Legacy' {
        BeforeEach {
            ${env:Write-Log} = ConvertTo-Json @{'Severity'=2; 'LogType'='Legacy'} -Compress
            Write-Log $Message
        }

        It "Writes '[Warning]' to ${DefaultLog}" {
            $DefaultLog | Should ContainExactly ([regex]::Escape('[Warning]'))
        }
    }

    Context 'Write-Log $Message -Severity 3' {
        BeforeEach {
            ${env:Write-Log} = ConvertTo-Json @{'Severity'=3} -Compress
            Write-Log $Message
        }

        It "Writes 'type=`"3`" ' to ${DefaultLog}" {
            $DefaultLog | Should ContainExactly ([regex]::Escape('type="3" '))
        }
    }

    Context 'Write-Log $Message -Severity 3 -LogType Legacy' {
        BeforeEach {
            ${env:Write-Log} = ConvertTo-Json @{'Severity'=3; 'LogType'='Legacy'} -Compress
            Write-Log $Message
        }

        It "Writes '[Error]' to ${DefaultLog}" {
            $DefaultLog | Should ContainExactly ([regex]::Escape('[Error]'))
        }
    }

    Context 'Write-Log $Message -Source HELLO_WORLD' {
        BeforeEach {
            ${env:Write-Log} = ConvertTo-Json @{'Source'='HELLO_WORLD'} -Compress
            Write-Log $Message
        }

        It "Writes 'file=`"HELLO_WORLD`" ' to ${DefaultLog}" {
            $DefaultLog | Should ContainExactly ([regex]::Escape('file="HELLO_WORLD"'))
        }
    }

    Context 'Write-Log $Message -Source HELLO_WORLD -LogType Legacy' {
        BeforeEach {
            ${env:Write-Log} = ConvertTo-Json @{'Source'='HELLO_WORLD'; 'LogType'='Legacy'} -Compress
            Write-Log $Message
        }

        It "Writes '[HELLO_WORLD]' to ${DefaultLog}" {
            $DefaultLog | Should ContainExactly ([regex]::Escape('[HELLO_WORLD]'))
        }
    }

    Context 'Write-Log $Message -Component Pester' {
        BeforeEach {
            ${env:Write-Log} = ConvertTo-Json @{'Component'='Pester'} -Compress
            Write-Log $Message
        }

        It "Writes 'component=`"Pester`" ' to ${DefaultLog}" {
            $DefaultLog | Should ContainExactly ([regex]::Escape("component=""Pester"""))
        }
    }

    Context 'Write-Log $Message -Component Pester -LogType Legacy' {
        BeforeEach {
            ${env:Write-Log} = ConvertTo-Json @{'Component'='Pester'; 'LogType'='Legacy'} -Compress
            Write-Log $Message
        }

        It "Writes '[Pester]' to ${DefaultLog}" {
            $DefaultLog | Should ContainExactly ([regex]::Escape(" [Pester]"))
        }
    }

    Context 'Write-Log $Message -LogFileDirectory $env:Temp' {
        $LogFile = "${env:Temp}\$(Split-Path $DefaultLog -Leaf)"

        BeforeEach {
            ${env:Write-Log} = ConvertTo-Json @{'LogFileDirectory'=$env:Temp} -Compress
            Write-Log $Message
        }

        It "Creates ${LogFile}" {
            $LogFile | Should Exist
        }

        It "Writes '${Message}' to ${LogFile}" {
            $LogFile | Should ContainExactly ([regex]::Escape($Message))
        }
    }

    Context 'Write-Log $Message -LogFileDirectory $env:Temp -LogType Legacy' {
        $LogFile = "${env:Temp}\$(Split-Path $DefaultLog -Leaf)"

        BeforeEach {
            ${env:Write-Log} = ConvertTo-Json @{'LogFileDirectory'=$env:Temp; 'LogType'='Legacy'} -Compress
            Write-Log $Message
        }

        It "Creates ${LogFile}" {
            $LogFile | Should Exist
        }

        It "Writes '${Message}' to ${LogFile}" {
            $LogFile | Should ContainExactly ([regex]::Escape($Message))
        }
    }

    Context 'Write-Log $Message -LogFileDirectory $env:Temp -LogFileName Test.log' {
        $LogFile = Join-Path -Path $env:Temp -ChildPath Test.log

        BeforeEach {
            ${env:Write-Log} = ConvertTo-Json @{'LogFileDirectory'=$env:Temp; 'LogFileName'='Test.log'} -Compress
            Write-Log $Message
        }

        It "Creates ${LogFile}" {
            $LogFile | Should Exist
        }

        It "Writes '${Message}' to ${LogFile}" {
            $LogFile | Should ContainExactly ([regex]::Escape($Message))
        }
    }

    Context 'Write-Log $Message -LogFileDirectory $env:Temp -LogFileName Test.log -LogType Legacy' {
        $LogFile = Join-Path -Path $env:Temp -ChildPath Test.log

        BeforeEach {
            ${env:Write-Log} = ConvertTo-Json @{'LogFileDirectory'=$env:Temp; 'LogFileName'='Test.log'; 'LogType'='Legacy'} -Compress
            Write-Log $Message
        }

        It "Creates ${LogFile}" {
            $LogFile | Should Exist
        }

        It "Writes '${Message}' to ${LogFile}" {
            $LogFile | Should ContainExactly ([regex]::Escape($Message))
        }
    }

    Context 'Write-Log $Message -LogFileDirectory $env:Temp -LogFileName Test.log -MaxLogFileSizeMB .1' {
        $LogFile = Join-Path -Path $env:Temp -ChildPath Test.log
        $LogFileArchived = $([System.IO.Path]::ChangeExtension($LogFile, 'lo_'))

        BeforeEach {
            Do {
                Write-Log $Message -LogFileDirectory $env:Temp -LogFileName Test.log -MaxLogFileSizeMB 0
            } Until (([System.IO.FileInfo](Get-ChildItem -Path $LogFile -ErrorAction 'Stop')).Length -gt .1MB)
        }

        It "Creates ${LogFileArchived}" {
            ${env:Write-Log} = ConvertTo-Json @{'LogFileDirectory'=$env:Temp; 'LogFileName'='Test.log'; 'MaxLogFileSizeMB'=.1} -Compress
            Write-Log $Message
            $LogFileArchived | Should Exist
        }

        It "The new '${LogFile}' is now very small." {
            ${env:Write-Log} = ConvertTo-Json @{'LogFileDirectory'=$env:Temp; 'LogFileName'='Test.log'; 'MaxLogFileSizeMB'=.1} -Compress
            Write-Log $Message
            [int](([System.IO.FileInfo](Get-ChildItem -Path $LogFile -ErrorAction 'Stop')).Length/1KB) | Should Be 0
        }
    }

    Context 'Write-Log $Message -WriteHost $true' {
        ${env:Write-Log} = ConvertTo-Json @{'WriteHost'=$true} -Compress
        Mock Write-Host { return $Message }

        It "Should write to host" {
            Write-Log $Message | Should Not BeNullOrEmpty
        }
    }

    Context 'Write-Log $Message -ContinueOnError $false' {
        Mock Write-Host { return $Message }

        It "Should not return an error" {
            ${env:Write-Log} = ConvertTo-Json @{'LogFileDirectory'='C:\C:\Temp'} -Compress
            Write-Log $Message | Should BeNullOrEmpty
        }

        It "Should return an error" {
            ${env:Write-Log} = ConvertTo-Json @{'LogFileDirectory'='C:\C:\Temp'; 'ContinueOnError'=$false} -Compress
            Write-Log $Message | Should Not BeNullOrEmpty
        }
    }

    Context 'Write-Log $Message -PassThru' {
        It "Should return '$Message'" {
            ${env:Write-Log} = ConvertTo-Json @{'PassThru'=$true} -Compress
            Write-Log $Message | Should BeExactly $Message
        }
    }

    Context 'Write-Log $Message -DebugMessage' {
        BeforeEach {
            ${env:Write-Log} = ConvertTo-Json @{'DebugMessage'=$true} -Compress
            Write-Log $Message
        }

        It "Should not create the log file '$DefaultLog'" {
            $DefaultLog | Should Not Exist
        }
    }

    Context 'Write-Log $Message -DebugMessage -LogDebugMessage $true' {
        BeforeEach {
            ${env:Write-Log} = ConvertTo-Json @{'DebugMessage'=$true; 'LogDebugMessage'=$true} -Compress
            Write-Log $Message
        }

        It "Should create the log file '$DefaultLog'" {
            $DefaultLog | Should Exist
        }
    }
}