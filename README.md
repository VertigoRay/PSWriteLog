Write messages to a log file in CMTrace.exe compatible format or Legacy text file format.

# Description

Write messages to a log file in CMTrace.exe compatible format or Legacy text file format and optionally display in the console.

Can also specify parameters via `${env:Write-Log}` variable. Store variables in as JSON. [More in the wiki.](../../wiki/WriteLog-Environment-Variable)

[The wiki contains complete documentation.](../../wiki)

# Usage

I import this into my scripts with [REQUIREMENTS.json](/UNT-CAS-ITS/REQUIREMENTS.json):

```json
[
    {
        "Command": "Write-Log",
        "Version": "1.1.1",
        "URL": "https://github.com/UNT-CAS-ITS/Write-Log/archive/v{0}.zip",
        "URL_f": "$requirement.Version",
        "Path": "{0}\\github_release_cache\\Write-Log-{1}\\Write-Log.ps1",
        "Path_f": "@($env:Temp , $requirement.Version)"
    }
]
```

Try adding this to your script:

```posh
Invoke-Expression (Invoke-WebRequest 'https://raw.githubusercontent.com/UNT-CAS-ITS/REQUIREMENTS.json/v1.1/requirements.ps1' -UseBasicParsing).Content
```

Works fine for me with RemoteSigned execution policy.  If you run into issues where the downloaded file is blocked, try using the `Unblock-File` command.
