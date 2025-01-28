Get-ChildItem -Path $PSScriptRoot\public\*.ps1, $PSScriptRoot\private\*.ps1 |
ForEach-Object {
    . $_.FullName
}