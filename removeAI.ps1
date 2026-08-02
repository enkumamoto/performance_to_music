param(
    [ValidateSet(
        'DisableRegKeys',
        'PreventAIPackageReinstall',
        'DisableCopilotPolicies',
        'RemoveAppxPackages',
        'RemoveRecallFeature',
        'RemoveCBSPackages',
        'RemoveAIFiles',
        'HideAIComponents',
        'DisableRewrite',
        'RemoveWindowsAITasks',
        'UpdateCleanupCheck'
    )]
    [string[]]$Options,
    [switch]$DryRun,
    [switch]$NonInteractive,
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
$ErrorLogFile = Join-Path $ErrorLogDir "error_removeAI_$Timestamp.log"
$SuccessLogFile = Join-Path $SuccessLogDir "success_removeAI_$Timestamp.log"

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

$AIOptionDescriptions = [ordered]@{
    'DisableRegKeys'            = 'Chaves de registro que ativam recursos de IA (Copilot, Recall, etc.)'
    'PreventAIPackageReinstall' = 'Bloqueio para impedir que pacotes de IA sejam reinstalados pelo Windows Update'
    'DisableCopilotPolicies'    = 'Politicas de grupo que habilitam o Copilot'
    'RemoveAppxPackages'        = 'Pacotes AppX relacionados a IA (Copilot, etc.)'
    'RemoveRecallFeature'       = 'Recurso opcional Windows Recall'
    'RemoveCBSPackages'         = 'Pacotes CBS (Component-Based Servicing) de IA'
    'RemoveAIFiles'             = 'Arquivos e pastas remanescentes de componentes de IA'
    'HideAIComponents'          = 'Atalhos/entradas visiveis de componentes de IA na interface'
    'DisableRewrite'            = 'Recurso de reescrita de texto assistida por IA (Rewrite)'
    'RemoveWindowsAITasks'      = 'Tarefas agendadas relacionadas a IA'
    'UpdateCleanupCheck'        = 'Verificacao/limpeza pos-atualizacao para reaplicar as remocoes acima'
}

if (-not $Options -or $Options.Count -eq 0) {
    $Options = $AIOptionDescriptions.Keys
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

Write-Host ''
Write-Host '=================== IA DO WINDOWS ===================' -ForegroundColor Yellow
Write-Host ''
Write-Host '[REMOVER] Recursos de IA que serao desativados/removidos:' -ForegroundColor Red
foreach ($opt in $Options) {
    Write-Host "  - [$opt] $($AIOptionDescriptions[$opt])" -ForegroundColor Red
}
Write-Host ''
Write-Host '======================================================' -ForegroundColor Yellow
Write-Host ''

foreach ($opt in $Options) { Write-Log "Candidato a remocao [IA]: $opt - $($AIOptionDescriptions[$opt])" }

$proceed = $false
if ($DryRun) {
    Write-Log 'Modo -DryRun: recursos de IA do Windows NAO serao alterados.' 'Yellow'
    $proceed = $false
}
elseif ($NonInteractive) {
    $proceed = $true
}
else {
    $answer = Read-Host 'Confirma a desativacao/remocao de TODOS os itens de IA listados acima? (sim/nao)'
    $proceed = $answer.Trim().ToLower() -in @('s', 'sim', 'y', 'yes')
}

if (-not $proceed) {
    Write-Log 'Operacao cancelada pelo usuario (ou modo DryRun). Nenhum recurso de IA foi alterado.' 'Yellow'
    if (-not $NonInteractive) { Read-Host 'Pressione Enter para sair' | Out-Null }
    exit 0
}

Write-Log 'Preparando desativacao/remocao de recursos de IA do Windows (RemoveWindowsAI)...' 'Cyan'
$scriptPath = Get-RemoveWindowsAIScriptPath
if (-not $scriptPath) {
    Write-Log 'Nao foi possivel localizar nem baixar o RemoveWindowsAi.ps1. Nenhuma alteracao foi feita.' 'Red' -Level Error
    if (-not $NonInteractive) { Read-Host 'Pressione Enter para sair' | Out-Null }
    exit 1
}

try {
    & $scriptPath -nonInteractive -Options $Options
    Write-Log "Recursos de IA do Windows processados via RemoveWindowsAI: $($Options -join ', ')" 'Green' -Level Success
}
catch {
    Write-Log "ERRO ao executar RemoveWindowsAI: $($_.Exception.Message)" 'Red' -Level Error
}

Write-Log 'Concluido. Recomenda-se reiniciar o computador.' 'Cyan'
Write-Log "Log de sucessos salvo em: $SuccessLogFile" 'Cyan'
Write-Log "Log de erros salvo em: $ErrorLogFile" 'Cyan'
if (-not $NonInteractive) { Read-Host 'Pressione Enter para sair' | Out-Null }
