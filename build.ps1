# WinRAR SFX Batch Builder (ASCII-safe)
param([string]$Pass="x77syq", [string]$Author="blazeX77", [string]$URL="https://www.wave-mod.top/")

$ErrorActionPreference = "Continue"
$gbk = [System.Text.Encoding]::GetEncoding("GBK")

# Chinese text via base64(GBK) to avoid encoding issues
$b64_1 = "18rUtNPJ"
$b64_2 = "1fu6z6Osw9zC686q"
$b64_3 = "v+zK1g=="
$b64_4 = "bW9k1vfVvs341rcudXJs"
$b64_5 = "IHwgbW9k1vfVvqO6"
$b64_6 = "IHwg09K8/Li01sbN+Na30tS3w87KbW9k1vfVvg=="

$t1 = $gbk.GetString([Convert]::FromBase64String($b64_1))
$t2 = $gbk.GetString([Convert]::FromBase64String($b64_2))
$t3 = $gbk.GetString([Convert]::FromBase64String($b64_3))
$t4 = $gbk.GetString([Convert]::FromBase64String($b64_4))
$t5 = $gbk.GetString([Convert]::FromBase64String($b64_5))
$t6 = $gbk.GetString([Convert]::FromBase64String($b64_6))

$fullAuthor = $t3 + " " + $Author

$cfg = "Title=" + $t1 + $fullAuthor + $t2 + $Pass + "`r`n"
$cfg += "Text=" + $t1 + $fullAuthor + $t2 + $Pass + $t5 + $URL + $t6 + "`r`n"
$cfg += "Silent=0`r`n"
$cfg += "Overwrite=1`r`n"

Set-Location $PSScriptRoot
Write-Host "============================================" -ForegroundColor Cyan
Write-Host " WinRAR SFX Builder" -ForegroundColor Cyan
Write-Host " Author: " -NoNewline; Write-Host $fullAuthor -ForegroundColor Yellow
Write-Host "============================================" -ForegroundColor Cyan

$dirs = Get-ChildItem -Directory | Where-Object {
    $_.Name -notlike "_*" -and $_.Name -notlike "lzma_*" -and $_.Name -notlike "test_*"
}
if (@($dirs).Count -eq 0) { Write-Host "No folders." -ForegroundColor Yellow; exit 0 }

foreach ($d in $dirs) {
    # Auto-fix: if folder contains only a single subfolder with similar name, use that instead
    $items = Get-ChildItem $d.FullName
    $subDirs = @($items | Where-Object { $_.PSIsContainer })
    if ($subDirs.Count -eq 1) {
        $simpleName = $d.Name -replace 'copy$','' -replace '\s+$',''
        $subName = $subDirs[0].Name -replace '\s+$',''
        if ($subName -like "*$simpleName*" -or $simpleName -like "*$subName*") {
            Write-Host "(flattened: using inner folder)" -ForegroundColor DarkGray
            $d = $subDirs[0]
        }
    }

    # Clean ALL existing .url files in source folder (keep only the one we create)
    Get-ChildItem $d.FullName -Recurse -Filter "*.url" -ErrorAction SilentlyContinue | Remove-Item -Force

    $urlFile = Join-Path $d.FullName $t4
    $urlContent = "[InternetShortcut]`r`nURL=$URL`r`n"
    [System.IO.File]::WriteAllText($urlFile, $urlContent, [System.Text.Encoding]::ASCII)

    $exe = "$($d.Name).exe"
    Write-Host "Building: $($d.Name) " -NoNewline -ForegroundColor Cyan
    $cfgPath = "$PSScriptRoot\_tc.txt"
    [System.IO.File]::WriteAllBytes($cfgPath, $gbk.GetBytes($cfg))
    Remove-Item "$PSScriptRoot\$exe" -Force -ErrorAction SilentlyContinue
    $null = & "D:\WinRAR\Rar.exe" a -sfx -ep1 -m5 "-hp$Pass" "-z$cfgPath" "$PSScriptRoot\$exe" $d.FullName 2>&1
    if (Test-Path "$PSScriptRoot\$exe") {
        Write-Host "$([math]::Round((Get-Item "$PSScriptRoot\$exe").Length/1MB,2)) MB" -ForegroundColor Green
    } else { Write-Host "FAILED" -ForegroundColor Red }
    Remove-Item $urlFile -Force -ErrorAction SilentlyContinue
    Remove-Item $cfgPath -Force -ErrorAction SilentlyContinue
}
Write-Host "Done! Password: $Pass" -ForegroundColor Yellow
