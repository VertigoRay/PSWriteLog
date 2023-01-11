<#
.DESCRIPTION
    This script can be used as part of a configuration item to setup computers with PSWriteLog.
    This is much simpler than the Tools\Remediation.ps1.

    Just see if we have the latest version of PSWriteLog installed.
#>
(Get-Module 'PSWriteLog' -ListAvailable).Version -contains (Find-Module 'PSWriteLog' -ErrorAction 'Ignore').Version
