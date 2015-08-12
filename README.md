Write messages to a log file in CMTrace.exe compatible format or Legacy text file format.

# Description

Write messages to a log file in CMTrace.exe compatible format or Legacy text file format and optionally display in the console.

Can also specify parameters via `${env:Write-Log}` variable. Store variables in as JSON. [More in the wiki.](../../wiki/WriteLog-Environment-Variable)

[The wiki contains complete documentation.](../../wiki)

# Usage

I import this into my scripts with the following:

```posh
if (-not (Get-Command 'Write-Log' -ErrorAction Ignore)) {
    $write_log_version = '1.1'
    $write_log_url = 'https://github.com/VertigoRay/Write-Log/archive/v{0}.zip' -f $write_log_version

    if (-not (Test-Path ('.\Write-Log-{0}\Write-Log.ps1' -f $write_log_version) -ErrorAction Ignore)) {
        Invoke-WebRequest ($write_log_url) -OutFile 'Write-Log.zip' -UseBasicParsing
        Add-Type -Assembly 'System.IO.Compression.FileSystem'
        [IO.Compression.ZipFile]::ExtractToDirectory((Resolve-Path 'Write-Log.zip'), (Get-Location))
    }

    . ('.\Write-Log-{0}\Write-Log.ps1' -f $write_log_version)
}
```

Works fine for me with RemoteSigned execution policy.  If you run into issues where the downloaded file is blocked, try using the `Unblock-File` command.
