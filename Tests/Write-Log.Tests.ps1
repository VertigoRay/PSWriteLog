$script:psProjectRoot = ([IO.DirectoryInfo] $PSScriptRoot).Parent
. ('{0}\PSWriteLog\Private\Write-Log.ps1' -f $psProjectRoot.FullName)

Describe 'Write-Log with parameters' {
    BeforeAll {
        $script:DefaultLog = "${TestDrive}\Logs\Write-Log.log"
        $script:DefaultLog = [IO.Path]::Combine($env:Temp, ('PowerShell {0} {1} {2}.log' -f $PSVersionTable.PSEdition, $PSVersionTable.PSVersion, $MyInvocation.CommandOrigin))
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
            Remove-Item $script:DefaultLog -Force -ErrorAction 'Ignore' | Out-Null
            $sw = [System.Diagnostics.Stopwatch]::new()
            $sw.Start()
            Do {
                if ($sw.Elapsed.TotalSeconds -gt 15) {
                    break
                }
                Write-Log $script:Message -FilePath $script:LogFile.FullName -MaxLogFileSizeMB .1
                $script:LogFile.Refresh()
                $script:LogFileArchived.Refresh()
            } Until ($script:LogFileArchived.Exists)
        }

        It "Creates ${script:LogFileArchived}" {
            Write-Log $script:Message -FilePath $script:LogFile.FullName -MaxLogFileSizeMB .1
            $script:LogFileArchived | Should -Exist
        }

        It "The new '${script:LogFile}' is now very small." {
            Write-Log $script:Message -FilePath $script:LogFile.FullName -MaxLogFileSizeMB .1
            $script:LogFile.Refresh()
            [int] ($script:LogFile.Length/1KB) | Should -BeLessThan 50
        }
    }
}

Describe 'Write-Log with $PSDefaultParameterValues' {
    BeforeAll {
        $script:DefaultLog = "${TestDrive}\Logs\Write-Log.log"
        $script:DefaultLog = [IO.Path]::Combine($env:Temp, ('PowerShell {0} {1} {2}.log' -f $PSVersionTable.PSEdition, $PSVersionTable.PSVersion, $MyInvocation.CommandOrigin))
        # Write-Host ('DefaultLog: {0}' -f $script:DefaultLog) -Fore 'Black' -Back 'Green'
        $script:Message = 'Hello World!!'
        # Write-Host ('Message: {0}' -f $script:Message) -Fore 'Black' -Back 'Green'
    }

    Context 'Write-Log $Message -LogType Legacy' {
        BeforeEach  {
            Remove-Item $script:DefaultLog -Force -ErrorAction 'Ignore' | Out-Null
            $PSDefaultParameterValues = @{}
            $PSDefaultParameterValues.Set_Item('Write-Log:LogType', 'Legacy')
            Write-Log "$script:Message"
        }

        It "Creates ${script:DefaultLog}" {
            $script:DefaultLog | Should -Exist
        }

        It "Writes '${script:Message}' to ${script:DefaultLog}" {
            $script:DefaultLog | Should -FileContentMatch ([regex]::Escape($script:Message))
        }

        It "Does not writes '<![LOG[' to ${script:DefaultLog}" {
            $script:DefaultLog | Should -Not -FileContentMatch ('^{0}' -f [regex]::Escape('<![LOG['))
        }
    }

    Context 'Write-Log $Message -Severity 1' {
        BeforeEach {
            Remove-Item $script:DefaultLog -Force -ErrorAction 'Ignore' | Out-Null
            $PSDefaultParameterValues = @{}
            $PSDefaultParameterValues.Set_Item('Write-Log:Severity', 1)
            Write-Log $script:Message
        }

        It "Writes 'type=`"1`" ' to ${script:DefaultLog}" {
            $script:DefaultLog | Should -FileContentMatch ([regex]::Escape('type="1" '))
        }
    }

    Context 'Write-Log $Message -Severity 1 -LogType Legacy' {
        BeforeEach {
            Remove-Item $script:DefaultLog -Force -ErrorAction 'Ignore' | Out-Null
            $PSDefaultParameterValues = @{}
            $PSDefaultParameterValues.Set_Item('Write-Log:Severity', 1)
            $PSDefaultParameterValues.Set_Item('Write-Log:LogType', 'Legacy')
            Write-Log $script:Message
        }

        It "Writes '[Info]' to ${script:DefaultLog}" {
            $script:DefaultLog | Should -FileContentMatch ([regex]::Escape('[Info]'))
        }
    }

    Context 'Write-Log $Message -Severity 2' {
        BeforeEach {
            Remove-Item $script:DefaultLog -Force -ErrorAction 'Ignore' | Out-Null
            $PSDefaultParameterValues = @{}
            $PSDefaultParameterValues.Set_Item('Write-Log:Severity', 2)
            Write-Log $script:Message
        }

        It "Writes 'type=`"2`" ' to ${script:DefaultLog}" {
            $script:DefaultLog | Should -FileContentMatch ([regex]::Escape('type="2" '))
        }
    }

    Context 'Write-Log $Message -Severity 2 -LogType Legacy' {
        BeforeEach {
            Remove-Item $script:DefaultLog -Force -ErrorAction 'Ignore' | Out-Null
            $PSDefaultParameterValues = @{}
            $PSDefaultParameterValues.Set_Item('Write-Log:Severity', 2)
            $PSDefaultParameterValues.Set_Item('Write-Log:LogType', 'Legacy')
            Write-Log $script:Message
        }

        It "Writes '[Warning]' to ${script:DefaultLog}" {
            $script:DefaultLog | Should -FileContentMatch ([regex]::Escape('[Warning]'))
        }
    }

    Context 'Write-Log $Message -Severity 3' {
        BeforeEach {
            Remove-Item $script:DefaultLog -Force -ErrorAction 'Ignore' | Out-Null
            $PSDefaultParameterValues = @{}
            $PSDefaultParameterValues.Set_Item('Write-Log:Severity', 3)
            Write-Log $script:Message
        }

        It "Writes 'type=`"3`" ' to ${script:DefaultLog}" {
            $script:DefaultLog | Should -FileContentMatch ([regex]::Escape('type="3" '))
        }
    }

    Context 'Write-Log $Message -Severity 3 -LogType Legacy' {
        BeforeEach {
            Remove-Item $script:DefaultLog -Force -ErrorAction 'Ignore' | Out-Null
            $PSDefaultParameterValues = @{}
            $PSDefaultParameterValues.Set_Item('Write-Log:Severity', 3)
            $PSDefaultParameterValues.Set_Item('Write-Log:LogType', 'Legacy')
            Write-Log $script:Message
        }

        It "Writes '[Error]' to ${script:DefaultLog}" {
            $script:DefaultLog | Should -FileContentMatch ([regex]::Escape('[Error]'))
        }
    }

    Context 'Write-Log $Message -Source HELLO_WORLD' {
        BeforeEach {
            Remove-Item $script:DefaultLog -Force -ErrorAction 'Ignore' | Out-Null
            $PSDefaultParameterValues = @{}
            $PSDefaultParameterValues.Set_Item('Write-Log:Source', 'HELLO_WORLD')
            Write-Log $script:Message
        }

        It "Writes 'file=`"HELLO_WORLD`" ' to ${script:DefaultLog}" {
            $script:DefaultLog | Should -FileContentMatch ([regex]::Escape('file="HELLO_WORLD"'))
        }
    }

    Context 'Write-Log $Message -Source HELLO_WORLD -LogType Legacy' {
        BeforeEach {
            Remove-Item $script:DefaultLog -Force -ErrorAction 'Ignore' | Out-Null
            $PSDefaultParameterValues = @{}
            $PSDefaultParameterValues.Set_Item('Write-Log:Source', 'HELLO_WORLD')
            $PSDefaultParameterValues.Set_Item('Write-Log:LogType', 'Legacy')
            Write-Log $script:Message
        }

        It "Writes '[HELLO_WORLD]' to ${script:DefaultLog}" {
            $script:DefaultLog | Should -FileContentMatch ([regex]::Escape('[HELLO_WORLD]'))
        }
    }

    Context 'Write-Log $Message -Component Pester' {
        BeforeEach {
            Remove-Item $script:DefaultLog -Force -ErrorAction 'Ignore' | Out-Null
            $PSDefaultParameterValues = @{}
            $PSDefaultParameterValues.Set_Item('Write-Log:Component', 'Pester')
            Write-Log $script:Message
        }

        It "Writes 'component=`"Pester`" ' to ${script:DefaultLog}" {
            $script:DefaultLog | Should -FileContentMatch ([regex]::Escape("component=""Pester"""))
        }
    }

    Context 'Write-Log $Message -Component Pester -LogType Legacy' {
        BeforeEach {
            Remove-Item $script:DefaultLog -Force -ErrorAction 'Ignore' | Out-Null
            $PSDefaultParameterValues = @{}
            $PSDefaultParameterValues.Set_Item('Write-Log:Component', 'Pester')
            $PSDefaultParameterValues.Set_Item('Write-Log:LogType', 'Legacy')
            Write-Log $script:Message
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
            $PSDefaultParameterValues = @{}
            $PSDefaultParameterValues.Set_Item('Write-Log:FilePath', ([IO.Path]::Combine($TestDrive, 'Test.Log')))
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
            Remove-Item $script:DefaultLog -Force -ErrorAction 'Ignore' | Out-Null
            $PSDefaultParameterValues = @{}
            $PSDefaultParameterValues.Set_Item('Write-Log:FilePath', ([IO.Path]::Combine($TestDrive, 'Test.Log')))
            $PSDefaultParameterValues.Set_Item('Write-Log:LogType', 'Legacy')
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
            [IO.FileInfo] $script:LogFile = [IO.Path]::Combine($TestDrive, 'Test.log')
            [IO.FileInfo] $script:LogFileArchived = $([IO.Path]::ChangeExtension($LogFile, 'lo_'))
        }

        BeforeEach {
            Remove-Item $script:DefaultLog -Force -ErrorAction 'Ignore' | Out-Null
            $PSDefaultParameterValues = @{}
            $PSDefaultParameterValues.Set_Item('Write-Log:FilePath', ([IO.Path]::Combine($TestDrive, 'Test.Log')))
            $PSDefaultParameterValues.Set_Item('Write-Log:MaxLogFileSizeMB', .1)
            $sw = [System.Diagnostics.Stopwatch]::new()
            $sw.Start()
            Do {
                if ($sw.Elapsed.TotalSeconds -gt 15) {
                    break
                }
                Write-Log $script:Message
                $script:LogFile.Refresh()
                $script:LogFileArchived.Refresh()
            } Until ($script:LogFileArchived.Exists)
        }

        It "Creates ${LogFileArchived}" {
            Write-Log $script:Message
            $LogFileArchived | Should -Exist
        }

        It "The new '${script:LogFile}' is now very small." {
            Write-Log $script:Message
            $script:LogFile.Refresh()
            [int] ($script:LogFile.Length/1KB) | Should -BeLessThan 50
        }
    }
}