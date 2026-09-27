$scriptpath = $MyInvocation.MyCommand.Path
$dir = Split-Path $scriptpath
Push-Location $dir

odin run . -collection:raytmfkit=..\..\src -collection:deps=..\..\deps

Pop-Location
