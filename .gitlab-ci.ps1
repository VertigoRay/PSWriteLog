param(
    [Parameter(Mandatory=$true, Position=0)]
    [ValidateNotNullorEmpty()]
    [string]
    $Action
    ,
    [Parameter(Mandatory=$false, Position=1)]
    [ValidateNotNullorEmpty()]
    [hashtable]
    $Options
)

$ErrorActionPreference = 'Stop'

function Write-HostHeader {
    param(
        [Parameter(Mandatory=$true, Position=0)]
        [ValidateNotNullorEmpty()]
        [string[]]
        $Message
    )

    Write-Host -ForegroundColor Cyan '###################################################'
    $Message | %{ Write-Host -ForegroundColor Cyan "# ${_}" }
    Write-Host -ForegroundColor Cyan '###################################################'
}

Write-HostHeader $MyInvocation.MyCommand, ($MyInvocation.BoundParameters | ConvertTo-Json -Compress )
Write-Host -ForegroundColor Magenta "Username: ${env:Username}"
Write-Host -ForegroundColor Magenta "UserProfile: ${env:UserProfile}"
Write-Host -ForegroundColor Magenta "PSModulePath: ${env:PSModulePath}"

$PSModulePath = $env:PSModulePath.Split(';').Trim() | ?{ $_ -like "${env:UserProfile}\*" }
if (-not $PSModulePath) {
    [System.Collections.ArrayList] $PSModulePaths = $env:PSModulePath.Split(';').Trim()
    $UserPSModulePath = "${env:UserProfile}\Documents\WindowsPowerShell\Modules"
    $PSModulePaths.Add($UserPSModulePath) | Out-Null
    $env:PSModulePath = $PSModulePaths -join ';'
    $PSModulePath = $env:PSModulePath.Split(';').Trim() | ?{ $_ -like "${env:UserProfile}\*" }
    Write-Host -ForegroundColor Magenta "PSModulePath: ${env:PSModulePath}"
}

if (-not (Test-Path $PSModulePath)) {
    New-Item -ItemType Directory $PSModulePath -Force -ErrorAction 'Ignore' | Out-Null
}

Write-Host -ForegroundColor Magenta "User PSModulePath (Exists: $(Test-Path $PSModulePath)): ${PSModulePath}"

Write-HostHeader $Action
switch ($Action) {
    'before_script' {
        try {
            $git = (Resolve-Path 'C:\Program Files (x86)\Git\bin\git.exe').Path
        } catch [System.Management.Automation.ItemNotFoundException] {
            $git = (Resolve-Path 'C:\Program Files\Git\bin\git.exe').Path
        }

        $latest_tag = & $git describe --tags
        Write-Host -ForegroundColor Magenta "Latest Tag: ${latest_tag}"
        try {
            & $git checkout $latest_tag
        } catch [System.Management.Automation.RemoteException] {
            Write-Host -ForegroundColor Magenta $_.Exception.Message
        }
    }
    'pester_prep' {
        if (Get-Module Pester -ListAvailable | ?{ $_.Version -eq [version]$Options.PESTER_VERSION }) {
            Write-Host -ForegroundColor Magenta "Pester $($Options.PESTER_VERSION) is already available."
        } else {
            $pester_local = "${PSModulePath}\Pester"
            Write-Host -ForegroundColor Magenta "Pester Location: ${pester_local}"
            Remove-Item $pester_local -Recurse -Force -ErrorAction 'Ignore' | Out-Null
            New-Item -ItemType Directory $pester_local -ErrorAction 'Ignore' | Out-Null
            Write-Host -ForegroundColor Magenta "Pester Location Exists: $(Test-Path $pester_local)"

            $url = ($Options.PESTER_URL -f $Options.PESTER_VERSION)
            Write-Host -ForegroundColor Magenta "Pester URL: ${url}"
            $pester_leaf = Split-Path $url -Leaf
            Write-Host -ForegroundColor Magenta "Pester Zip: ${pester_leaf}"
            $pester_temp = "${env:Temp}\$([guid]::NewGuid())"
            Write-Host -ForegroundColor Magenta "Pester Temp Path: ${pester_temp}"
            New-Item -ItemType Directory $pester_temp -ErrorAction 'Ignore' | Out-Null
            Write-Host -ForegroundColor Magenta "Pester Temp Path Exists: $(Test-Path $pester_temp)"
            $pester_zip_path = "${pester_temp}\${pester_leaf}"
            Write-Host -ForegroundColor Magenta "Pester Zip Path: ${pester_zip_path}"
            
            (New-Object System.Net.WebClient).DownloadFile($url, $pester_zip_path)
            Write-Host -ForegroundColor Magenta "Pester Downloaded: $(Test-Path $pester_zip_path)"

            Write-HostHeader "Unzipping"
            $shell = New-Object -ComObject 'Shell.Application'
            Write-Host -ForegroundColor Magenta "Shell Object: $($shell.Application)"
            $zip = $shell.NameSpace($pester_zip_path)
            Write-Host -ForegroundColor Magenta "Zip Namespace: $($zip.Title)"
            foreach ($item in $zip.Items()) {
                Write-Host -ForegroundColor Magenta "Zip Item: $($Item.Name)"
                $shell.NameSpace($pester_temp).CopyHere($item)
            }

            Write-HostHeader "Moving to correct location and cleanup"
            $pester_downloaded_to = (Get-ChildItem $pester_temp -Filter 'Pester.psm1' -Recurse).DirectoryName.Trim()
            Move-Item "${pester_downloaded_to}\*" $pester_local -Force
            Remove-Item $pester_temp -Recurse -Force

            Write-HostHeader "Confirm"
            if (Get-Module Pester -ListAvailable | ?{ $_.Version -eq [version]$Options.PESTER_VERSION }) {
                Write-Host -ForegroundColor Magenta "Pester $($Options.PESTER_VERSION) is now available."
            } else {
                Throw [System.Management.Automation.ItemNotFoundException] "Pester $($Options.PESTER_VERSION) is still NOT available."
            }
        }
    }
    'pester_tests' {
        Get-ChildItem -Filter '*.Tests.ps1' -File -Recurse | %{ Invoke-Pester $_.FullName -CodeCoverage $_.FullName.Replace('.Tests.ps1', '.ps1') -EnableExit }
    }
}