<#
.SYNOPSIS
    Ferramenta para geração de Certificados Digitais A1 mockados (PFX) para testes.

.DESCRIPTION
    Gera certificados A1 autoassinados a partir de arquivos .cnf padronizados.
    Convenção de nomes:
      - Config:  configs/cert_config_{CNPJ_SEM_PONTUACAO}.cnf
      - Saída:   output/cert_a1_mock_{CNPJ_SEM_PONTUACAO}.pfx

.PARAMETER Cnpj
    CNPJ sem pontuação (somente números e letras). Ex: 02G0NC3Z000173

.PARAMETER Senha
    Senha do arquivo PFX. Padrão: Iob@2026

.PARAMETER ValidadeDias
    Validade do certificado em dias. Padrão: 365

.EXAMPLE
    .\gerar_cert_a1_mock.ps1 -Cnpj 02G0NC3Z000173
    .\gerar_cert_a1_mock.ps1 -Cnpj 02G0NC3Z000173 -Senha "MinhaSenha123"
    .\gerar_cert_a1_mock.ps1 -Cnpj 02G0NC3Z000173 -Senha "Iob@2026" -ValidadeDias 730
#>

param(
    [Parameter(Mandatory = $true, Position = 0, HelpMessage = "CNPJ sem pontuação (ex: 02G0NC3Z000173)"]
    [ValidatePattern('^[0-9A-Za-z]{14}$')]
    [string]$Cnpj,

    [Parameter(Mandatory = $false)]
    [string]$Senha = "Iob@2026",

    [Parameter(Mandatory = $false)]
    [int]$ValidadeDias = 365
)

# ============================================================
# Configurações e caminhos
# ============================================================
$ErrorActionPreference = "Stop"
$ScriptDir   = Split-Path -Parent $MyInvocation.MyCommand.Definition
$ConfigDir   = Join-Path $ScriptDir "configs"
$OutputDir   = Join-Path $ScriptDir "output"
$TempDir     = Join-Path $ScriptDir "temp"

$CnpjUpper   = $Cnpj.ToUpper()
$CnfFile     = Join-Path $ConfigDir "cert_config_${CnpjUpper}.cnf"
$PfxFile     = Join-Path $OutputDir "cert_a1_mock_${CnpjUpper}.pfx"
$KeyFile     = Join-Path $TempDir   "cert_a1_mock_${CnpjUpper}.key"
$CrtFile     = Join-Path $TempDir   "cert_a1_mock_${CnpjUpper}.crt"

# ============================================================
# Banner
# ============================================================
function Write-Banner {
    Write-Host ""
    Write-Host "  +==================================================+" -ForegroundColor Cyan
    Write-Host "  |   Gerador de Certificado A1 Mockado (PFX)       |" -ForegroundColor Cyan
    Write-Host "  |   Para testes e validacao de aplicacoes          |" -ForegroundColor Cyan
    Write-Host "  +==================================================+" -ForegroundColor Cyan
    Write-Host ""
}

# ============================================================
# Funções auxiliares
# ============================================================
function Write-Step  { param([string]$msg) Write-Host "  [*] $msg" -ForegroundColor Yellow }
function Write-Ok    { param([string]$msg) Write-Host "  [OK] $msg" -ForegroundColor Green  }
function Write-Err   { param([string]$msg) Write-Host "  [ERRO] $msg" -ForegroundColor Red    }
function Write-Info  { param([string]$msg) Write-Host "  [i] $msg" -ForegroundColor Gray   }

function Assert-OpenSSL {
    try {
        $null = & openssl version 2>&1
        return $true
    }
    catch {
        return $false
    }
}

function Format-CnpjDisplay {
    param([string]$cnpj)
    if ($cnpj.Length -eq 14) {
        return "$($cnpj.Substring(0,2)).$($cnpj.Substring(2,3)).$($cnpj.Substring(5,3))/$($cnpj.Substring(8,4))-$($cnpj.Substring(12,2))"
    }
    return $cnpj
}

# ============================================================
# Execução principal
# ============================================================
Write-Banner

# --- Verificar OpenSSL ---
Write-Step "Verificando OpenSSL..."
if (-not (Assert-OpenSSL)) {
    Write-Err "OpenSSL nao encontrado no PATH!"
    Write-Info "Instale com: winget install ShiningLight.OpenSSL.Light"
    Write-Info "Apos instalar, feche e reabra o terminal."
    exit 1
}
$opensslVersion = (& openssl version 2>&1) | Out-String
Write-Ok "OpenSSL encontrado: $($opensslVersion.Trim())"

# --- Verificar arquivo CNF ---
Write-Step "Buscando configuracao: cert_config_${CnpjUpper}.cnf"
if (-not (Test-Path $CnfFile)) {
    Write-Err "Arquivo de configuracao nao encontrado!"
    Write-Info "Esperado em: $CnfFile"
    Write-Info ""
    Write-Info "Crie o arquivo .cnf na pasta 'configs' seguindo o modelo."
    Write-Info "O nome deve ser: cert_config_${CnpjUpper}.cnf"
    exit 1
}
Write-Ok "Configuracao encontrada: $CnfFile"

# --- Criar diretórios ---
@($OutputDir, $TempDir) | ForEach-Object {
    if (-not (Test-Path $_)) {
        New-Item -ItemType Directory -Path $_ -Force | Out-Null
    }
}

# --- Remover PFX antigo se existir ---
if (Test-Path $PfxFile) {
    Write-Step "Removendo PFX anterior..."
    Remove-Item -Path $PfxFile -Force
    Write-Ok "PFX anterior removido."
}

# --- Gerar chave privada ---
Write-Step "Gerando chave privada RSA 2048..."
& openssl genrsa -out $KeyFile 2048 2>&1 | Out-Null
if (-not (Test-Path $KeyFile)) {
    Write-Err "Falha ao gerar chave privada!"
    exit 1
}
Write-Ok "Chave privada gerada."

# --- Gerar certificado autoassinado ---
Write-Step "Gerando certificado autoassinado (validade: $ValidadeDias dias)..."
& openssl req `
    -new `
    -x509 `
    -key $KeyFile `
    -out $CrtFile `
    -days $ValidadeDias `
    -config $CnfFile `
    -extensions v3_ext `
    -utf8 2>&1 | Out-Null

if (-not (Test-Path $CrtFile)) {
    Write-Err "Falha ao gerar certificado!"
    exit 1
}
Write-Ok "Certificado X.509 gerado."

# --- Empacotar PFX ---
Write-Step "Empacotando arquivo PFX (PKCS#12)..."
& openssl pkcs12 -export `
    -out $PfxFile `
    -inkey $KeyFile `
    -in $CrtFile `
    -name "Certificado A1 Mock - CNPJ ${CnpjUpper}" `
    -passout "pass:${Senha}" 2>&1 | Out-Null

if (-not (Test-Path $PfxFile)) {
    Write-Err "Falha ao gerar arquivo PFX!"
    exit 1
}
Write-Ok "Arquivo PFX gerado com sucesso!"

# --- Extrair informações do certificado para exibição ---
Write-Step "Extraindo informacoes do certificado..."
$certInfo = & openssl x509 -in $CrtFile -noout -subject -dates -serial 2>&1 | Out-String
$cnpjFormatado = Format-CnpjDisplay $CnpjUpper

# --- Limpar arquivos temporários ---
Write-Step "Limpando arquivos temporarios..."
Remove-Item -Path $KeyFile -Force -ErrorAction SilentlyContinue
Remove-Item -Path $CrtFile -Force -ErrorAction SilentlyContinue
Write-Ok "Temporarios removidos."

# --- Resumo final ---
Write-Host ""
Write-Host "  +==================================================+" -ForegroundColor Green
Write-Host "  |       CERTIFICADO GERADO COM SUCESSO!           |" -ForegroundColor Green
Write-Host "  +==================================================+" -ForegroundColor Green
Write-Host ""
Write-Host "  Arquivo PFX : " -NoNewline -ForegroundColor White
Write-Host "$PfxFile" -ForegroundColor Cyan
Write-Host "  CNPJ        : " -NoNewline -ForegroundColor White
Write-Host "$cnpjFormatado" -ForegroundColor Cyan
Write-Host "  Senha       : " -NoNewline -ForegroundColor White
Write-Host "$Senha" -ForegroundColor Cyan
Write-Host "  Validade    : " -NoNewline -ForegroundColor White
Write-Host "$ValidadeDias dias" -ForegroundColor Cyan
Write-Host ""
Write-Host "  --- Detalhes do Certificado ---" -ForegroundColor DarkGray
$certInfo.Trim().Split("`n") | ForEach-Object {
    Write-Host "  $_" -ForegroundColor DarkGray
}
Write-Host ""
