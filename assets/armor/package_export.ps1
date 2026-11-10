$ErrorActionPreference = 'Stop'
$packageRoot = Join-Path $PSScriptRoot 'roblox'
$validation = Get-Content (Join-Path $packageRoot 'validation.json') -Raw | ConvertFrom-Json
$manifest = Get-Content (Join-Path $packageRoot 'manifest.json') -Raw | ConvertFrom-Json
if (-not $validation.ok -or $validation.files.Count -ne 33 -or $manifest.count -ne 32) {
    throw 'Export validation is incomplete.'
}
$required = @('armaduras-32.fbx', 'armaduras_palette.png', 'armaduras_roughness.png', 'armaduras_metalness.png', 'armaduras-export.blend', 'manifest.json', 'validation.json', 'IMPORTAR-ROBLOX.md')
$required += @($manifest.assets | ForEach-Object { $_.file })
foreach ($entry in $validation.sha256.PSObject.Properties) {
    $actual = (Get-FileHash -LiteralPath (Join-Path $packageRoot $entry.Name) -Algorithm SHA256).Hash
    if ($actual -ne $entry.Value) { throw "File changed after validation: $($entry.Name)" }
}
Add-Type -AssemblyName System.IO.Compression.FileSystem
$zipPath = Join-Path $PSScriptRoot ('armaduras-roblox-' + [guid]::NewGuid().ToString('N') + '.zip')
$zip = [IO.Compression.ZipFile]::Open($zipPath, [IO.Compression.ZipArchiveMode]::Create)
try {
    foreach ($relative in $required) {
        $source = Join-Path $packageRoot $relative
        [IO.Compression.ZipFileExtensions]::CreateEntryFromFile($zip, $source, $relative.Replace('\', '/'), [IO.Compression.CompressionLevel]::Optimal) | Out-Null
    }
} finally { $zip.Dispose() }
$check = [IO.Compression.ZipFile]::OpenRead($zipPath)
try {
    if ($check.Entries.Count -ne 40) { throw 'Incorrect ZIP file count.' }
    foreach ($entry in $check.Entries) {
        if ($entry.Length -ne (Get-Item -LiteralPath (Join-Path $packageRoot $entry.FullName)).Length) { throw "ZIP entry size mismatch: $($entry.FullName)" }
    }
} finally { $check.Dispose() }
$destination = Join-Path $PSScriptRoot 'armaduras-roblox.zip'
Move-Item -LiteralPath $zipPath -Destination $destination -Force
Get-Item -LiteralPath $destination | Select-Object FullName, Length, LastWriteTime
Write-Output 'PACKAGE_OK: 40 files; 33 validated FBXs; 32 equipment models.'
