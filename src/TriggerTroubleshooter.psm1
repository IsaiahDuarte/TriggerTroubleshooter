Get-ChildItem -Path $PSScriptRoot\Public\*.ps1, $PSScriptRoot\Private\*.ps1 -Recurse |
ForEach-Object {
    . $_.FullName
}