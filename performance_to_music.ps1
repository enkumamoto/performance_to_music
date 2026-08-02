param(
    [string[]]$PreservePaths = @(
        'C:\Users\netok\Documentos',
        'C:\Cakewalk Projects',
        'C:\Cakewalk Content',
        'C:\Arquivos de Programaa\Ableton',
        'C:\Arquivos de Programaa\Cakewalk'
    ),
    [switch]$FullScan,
    [switch]$DryRun,
    [switch]$NonInteractive,
    [string[]]$ScanRoots,
    [switch]$DisableWindowsAI,
    [string]$RemoveWindowsAIScriptPath
)

if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]'Administrator')) {
    $paramStr = $MyInvocation.BoundParameters.GetEnumerator() | ForEach-Object {
        $key = $_.Key
        $val = $_.Value
        switch ($val) {
            { $val -is [switch] -or $val -is [bool] } { if ($val) { "-$key" }; break }
            { $val -is [array] } { "-$key `"$($val -join '","')`""; break }
            default { "-$key `"$val`"" }
        }
    }
    $arglist = "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`" $($paramStr -join ' ')"
    Start-Process PowerShell.exe -ArgumentList $arglist -Verb RunAs
    exit
}

$Timestamp = Get-Date -Format 'yyyyMMdd_HHmmss'
$ErrorLogDir = Join-Path $PSScriptRoot 'error_log'
$SuccessLogDir = Join-Path $PSScriptRoot 'success_log'
New-Item -ItemType Directory -Path $ErrorLogDir -Force -ErrorAction SilentlyContinue | Out-Null
New-Item -ItemType Directory -Path $SuccessLogDir -Force -ErrorAction SilentlyContinue | Out-Null
$ErrorLogFile = Join-Path $ErrorLogDir "error_$Timestamp.log"
$SuccessLogFile = Join-Path $SuccessLogDir "success_$Timestamp.log"

function Write-Log {
    param(
        [string]$Message,
        [string]$Color = 'Gray',
        [ValidateSet('Info', 'Success', 'Error')]
        [string]$Level = 'Info'
    )
    $line = "[$(Get-Date -Format 'HH:mm:ss')] $Message"
    Write-Host $line -ForegroundColor $Color
    if ($Level -eq 'Error') {
        Add-Content -Path $ErrorLogFile -Value $line
    }
    else {
        Add-Content -Path $SuccessLogFile -Value $line
    }
}

$MusicKeywords = @(
    'VST', 'VST2', 'VST3', 'AAX', 'AudioUnit', 'AU Plugin',
    'IK Multimedia', 'T-RackS', 'AmpliTube',
    'iZotope', 'RX ', 'Ozone', 'Nectar', 'Neutron',
    'LANDR',
    'Native Instruments', 'Kontakt', 'Komplete', 'Reaktor', 'Battery', 'Massive',
    'Neural DSP', 'Neural Amp Modeler', 'NeuralAmpModeler', 'NAM',
    'Steinberg', 'Cubase', 'Nuendo', 'WaveLab', 'HALion',
    'Ableton', 'Live 1', 'Live 9', 'Live 10', 'Live 11', 'Live 12',
    'FL Studio', 'Image-Line',
    'Studio One', 'PreSonus',
    'Reaper', 'Cockos',
    'Pro Tools', 'Avid',
    'Waves Audio', 'Waves ', 'SoundGrid',
    'Melodyne', 'Celemony',
    'Antares', 'Auto-Tune',
    'Arturia',
    'Universal Audio', 'UAD', 'Apollo',
    'Focusrite', 'Scarlett', 'Novation',
    'ASIO', 'ASIO4ALL',
    'Slate Digital',
    'Toontrack', 'Superior Drummer', 'EZdrummer',
    'XLN Audio', 'Addictive Drums',
    'Spitfire Audio',
    'Valhalla DSP',
    'FabFilter',
    'Soundtoys',
    'Plugin Alliance', 'Brainworx'
)

$MusicFileExtensions = @(
    '*.als', '*.flp', '*.cpr', '*.npr', '*.rpp', '*.rpp-bak', '*.ptx', '*.ptf',
    '*.logicx', '*.band', '*.song',
    '*.vst', '*.vst3', '*.aaxplugin', '*.component',
    '*.nki', '*.nkm', '*.nkc', '*.nka',
    '*.fxp', '*.fxb'
)

$BrowserKeywords = @(
    'Microsoft Edge', 'Google Chrome', 'Mozilla Firefox', 'Opera', 'Opera GX',
    'Brave', 'Vivaldi', 'Internet Explorer'
)

$OfficeKeywords = @(
    'Microsoft Office', 'Microsoft 365', 'Office16', 'Office15', 'Microsoft Outlook',
    'Microsoft Access', 'Microsoft Publisher', 'Microsoft OneNote'
)

$HPKeywords = @(
    'HP ', 'Hewlett-Packard', 'HP Smart', 'HP Support Assistant', 'HP Officejet',
    'HP LaserJet', 'HP DeskJet', 'HP ENVY', 'HP Print', 'HP Scan', 'HPPrint'
)

$RemovalKeywordSets = @{
    'Navegador' = $BrowserKeywords
    'Office'    = $OfficeKeywords
    'HP'        = $HPKeywords
}

function Test-MatchesAny {
    param([string]$Text, [string[]]$Keywords)
    if ([string]::IsNullOrWhiteSpace($Text)) { return $false }
    foreach ($kw in $Keywords) {
        if ($Text -like "*$kw*") { return $true }
    }
    return $false
}

function Test-IsPreserved {
    param([string]$Path)
    if ([string]::IsNullOrWhiteSpace($Path)) { return $false }
    foreach ($preserved in $PreservePaths) {
        if ($Path.TrimEnd('\') -like "$($preserved.TrimEnd('\'))*") { return $true }
    }
    return $false
}

function Get-InstalledPrograms {
    $paths = @(
        'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*',
        'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*',
        'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*'
    )
    Get-ItemProperty $paths -ErrorAction SilentlyContinue |
        Where-Object { $_.DisplayName -and -not $_.SystemComponent } |
        Select-Object DisplayName, UninstallString, QuietUninstallString, InstallLocation, PSPath, PSChildName |
        Sort-Object DisplayName -Unique
}

Write-Log 'Lendo lista de programas instalados...' 'Cyan'
$installed = Get-InstalledPrograms

$protectedPrograms = @()
$removalCandidates = @()

foreach ($prog in $installed) {
    $isMusic = Test-MatchesAny -Text $prog.DisplayName -Keywords $MusicKeywords
    if ($isMusic) {
        $protectedPrograms += $prog
        continue
    }
    foreach ($category in $RemovalKeywordSets.Keys) {
        if (Test-MatchesAny -Text $prog.DisplayName -Keywords $RemovalKeywordSets[$category]) {
            $removalCandidates += [PSCustomObject]@{
                Category = $category
                Program  = $prog
            }
            break
        }
    }
}

Write-Log 'Lendo pacotes AppX instalados...' 'Cyan'
$appxPackages = Get-AppxPackage -AllUsers -ErrorAction SilentlyContinue
$removalAppx = @()
foreach ($appx in $appxPackages) {
    $isMusic = Test-MatchesAny -Text $appx.Name -Keywords $MusicKeywords
    if ($isMusic) { continue }
    foreach ($category in $RemovalKeywordSets.Keys) {
        if (Test-MatchesAny -Text $appx.Name -Keywords $RemovalKeywordSets[$category]) {
            $removalAppx += [PSCustomObject]@{ Category = $category; Package = $appx }
            break
        }
    }
}

$protectedFiles = @()
if ($FullScan) {
    Write-Log 'Iniciando varredura completa de arquivos (pode demorar)...' 'Cyan'
    if (-not $ScanRoots -or $ScanRoots.Count -eq 0) {
        $ScanRoots = (Get-PSDrive -PSProvider FileSystem | Where-Object { $_.Free -ne $null }).Root
    }
    $excludeDirs = @('\Windows\', '\$Recycle.Bin\', '\ProgramData\Package Cache\', '\System Volume Information\')
    foreach ($root in $ScanRoots) {
        Write-Log "  Varrendo $root ..." 'DarkGray'
        Get-ChildItem -Path $root -Include $MusicFileExtensions -Recurse -File -Force -ErrorAction SilentlyContinue |
            Where-Object {
                $full = $_.FullName
                -not (Test-IsPreserved $full) -and -not ($excludeDirs | Where-Object { $full -like "*$_*" })
            } |
            ForEach-Object { $protectedFiles += $_.FullName }
    }
    Write-Log "Varredura completa encontrou $($protectedFiles.Count) arquivo(s) de musica." 'Green'
}

Write-Host ''
Write-Host '=================== RELATORIO ===================' -ForegroundColor Yellow
Write-Host ''
Write-Host '[PROTEGIDO] Pastas preservadas integralmente:' -ForegroundColor Green
$PreservePaths | ForEach-Object { Write-Host "  - $_" -ForegroundColor Green }
Write-Host ''
Write-Host '[PROTEGIDO] Software de musica detectado (nao sera tocado):' -ForegroundColor Green
if ($protectedPrograms.Count -eq 0) { Write-Host '  (nenhum encontrado)' -ForegroundColor DarkGray }
$protectedPrograms | ForEach-Object { Write-Host "  - $($_.DisplayName)" -ForegroundColor Green }

if ($FullScan) {
    Write-Host ''
    Write-Host "[PROTEGIDO] Arquivos de projeto/plugins encontrados na varredura: $($protectedFiles.Count)" -ForegroundColor Green
}

Write-Host ''
Write-Host '[REMOVER] Programas candidatos a desinstalacao:' -ForegroundColor Red
if ($removalCandidates.Count -eq 0 -and $removalAppx.Count -eq 0) {
    Write-Host '  (nenhum encontrado)' -ForegroundColor DarkGray
}
foreach ($item in $removalCandidates) {
    Write-Host "  - [$($item.Category)] $($item.Program.DisplayName)" -ForegroundColor Red
}
foreach ($item in $removalAppx) {
    Write-Host "  - [$($item.Category)/AppX] $($item.Package.Name)" -ForegroundColor Red
}
Write-Host ''
Write-Host '===================================================' -ForegroundColor Yellow
Write-Host ''

foreach ($item in $removalCandidates) { Write-Log "Candidato a remocao [$($item.Category)]: $($item.Program.DisplayName)" }
foreach ($item in $removalAppx) { Write-Log "Candidato a remocao [$($item.Category)/AppX]: $($item.Package.Name)" }

if ($removalCandidates.Count -eq 0 -and $removalAppx.Count -eq 0) {
    Write-Log 'Nada a remover. Encerrando.' 'Green'
    if (-not $NonInteractive) { Read-Host 'Pressione Enter para sair' | Out-Null }
    exit 0
}

$proceed = $false
if ($DryRun) {
    Write-Log 'Modo -DryRun: nada sera removido de fato.' 'Yellow'
    $proceed = $false
}
elseif ($NonInteractive) {
    $proceed = $true
}
else {
    $answer = Read-Host 'Confirma a remocao de TODOS os itens listados acima em [REMOVER]? (sim/nao)'
    $proceed = $answer.Trim().ToLower() -in @('s', 'sim', 'y', 'yes')
}

if (-not $proceed) {
    Write-Log 'Operacao cancelada pelo usuario (ou modo DryRun). Nenhum programa foi removido.' 'Yellow'
    if (-not $NonInteractive) { Read-Host 'Pressione Enter para sair' | Out-Null }
    exit 0
}

function Uninstall-Program {
    param($Program)

    $name = $Program.DisplayName
    Write-Log "Removendo: $name" 'Magenta'

    if ($name -like '*Microsoft Edge*' -and $name -notlike '*WebView*') {
        $setup = Get-ChildItem "$env:ProgramFiles (x86)\Microsoft\Edge\Application\*\Installer\setup.exe", "$env:ProgramFiles\Microsoft\Edge\Application\*\Installer\setup.exe" -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($setup) {
            Start-Process -FilePath $setup.FullName -ArgumentList '--uninstall --system-level --verbose-logging --force-uninstall' -Wait -ErrorAction SilentlyContinue
            return
        }
    }

    $cmd = $Program.QuietUninstallString
    if (-not $cmd) { $cmd = $Program.UninstallString }
    if (-not $cmd) { Write-Log "  Sem string de desinstalacao para $name, pulando." 'DarkYellow' -Level Error; return }

    try {
        if ($cmd -match 'msiexec') {
            $productCode = ($cmd | Select-String -Pattern '\{[0-9A-Fa-f\-]+\}').Matches.Value
            if ($productCode) {
                Start-Process msiexec.exe -ArgumentList "/x $productCode /qn /norestart" -Wait -ErrorAction SilentlyContinue
            }
            else {
                Start-Process cmd.exe -ArgumentList "/c $cmd /qn /norestart" -Wait -ErrorAction SilentlyContinue
            }
        }
        else {
            Start-Process cmd.exe -ArgumentList "/c `"$cmd`" /S /silent /quiet /norestart" -Wait -ErrorAction SilentlyContinue
        }
        Write-Log "  OK: $name removido (ou instalador de remocao executado)." 'Green' -Level Success
    }
    catch {
        Write-Log "  ERRO ao remover $name : $($_.Exception.Message)" 'Red' -Level Error
    }
}

foreach ($item in $removalCandidates) {
    Uninstall-Program -Program $item.Program
}

foreach ($item in $removalAppx) {
    try {
        Write-Log "Removendo pacote AppX: $($item.Package.Name)" 'Magenta'
        Remove-AppxPackage -Package $item.Package.PackageFullName -AllUsers -ErrorAction SilentlyContinue
        Write-Log "  OK: $($item.Package.Name) removido." 'Green' -Level Success
    }
    catch {
        Write-Log "  ERRO ao remover pacote AppX $($item.Package.Name): $($_.Exception.Message)" 'Red' -Level Error
    }
}

function Get-RemoveWindowsAIScriptPath {
    if ($RemoveWindowsAIScriptPath -and (Test-Path $RemoveWindowsAIScriptPath)) { return $RemoveWindowsAIScriptPath }

    $candidates = @(
        (Join-Path $PSScriptRoot 'RemoveWindowsAI\RemoveWindowsAi.ps1'),
        (Join-Path (Split-Path $PSScriptRoot -Parent) 'RemoveWindowsAI\RemoveWindowsAi.ps1')
    )
    foreach ($c in $candidates) {
        if (Test-Path $c) { return $c }
    }

    $tempScript = Join-Path $env:TEMP 'RemoveWindowsAi.ps1'
    try {
        Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/zoicware/RemoveWindowsAI/main/RemoveWindowsAi.ps1' -OutFile $tempScript -UseBasicParsing -ErrorAction Stop
        return $tempScript
    }
    catch {
        return $null
    }
}

function Disable-WindowsAI {
    Write-Log 'Preparando remocao/desativacao de recursos de IA do Windows (RemoveWindowsAI)...' 'Cyan'
    $scriptPath = Get-RemoveWindowsAIScriptPath
    if (-not $scriptPath) {
        Write-Log 'Nao foi possivel localizar nem baixar o RemoveWindowsAi.ps1. Etapa de IA pulada.' 'Red' -Level Error
        return
    }
    try {
        & $scriptPath -nonInteractive -AllOptions
        Write-Log 'Recursos de IA do Windows (Copilot, Recall, componentes AI) processados via RemoveWindowsAI.' 'Green' -Level Success
    }
    catch {
        Write-Log "ERRO ao executar RemoveWindowsAI: $($_.Exception.Message)" 'Red' -Level Error
    }
}

$runAIRemoval = $false
if ($DryRun) {
    if ($DisableWindowsAI) { Write-Log 'Modo -DryRun: recursos de IA do Windows NAO serao desativados.' 'Yellow' }
}
elseif ($NonInteractive) {
    $runAIRemoval = $DisableWindowsAI
}
elseif ($DisableWindowsAI) {
    $runAIRemoval = $true
}
else {
    Write-Host ''
    Write-Host '[OPCIONAL] O RemoveWindowsAI tambem pode desativar/remover: Copilot, Recall, componentes de IA do Windows, pacotes CBS de IA e politicas relacionadas.' -ForegroundColor Cyan
    $answerAI = Read-Host 'Deseja tambem desativar os recursos de Inteligencia Artificial do Windows agora? (sim/nao)'
    $runAIRemoval = $answerAI.Trim().ToLower() -in @('s', 'sim', 'y', 'yes')
}

if ($runAIRemoval) {
    Disable-WindowsAI
}

Write-Log 'Concluido. Recomenda-se reiniciar o computador.' 'Cyan'
Write-Log "Log de sucessos salvo em: $SuccessLogFile" 'Cyan'
Write-Log "Log de erros salvo em: $ErrorLogFile" 'Cyan'
if (-not $NonInteractive) { Read-Host 'Pressione Enter para sair' | Out-Null }
