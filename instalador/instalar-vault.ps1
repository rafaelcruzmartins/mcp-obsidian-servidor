<#
  Instalador do Vault da equipe (Syncthing) para Windows.

  O que faz, sem pedir administrador:
    1. Baixa o Syncthing oficial (versão fixa, com conferência do SHA-256) para a pasta do usuário.
    2. Coloca o Syncthing para iniciar com o Windows, sem janela.
    3. Desliga o UPnP (NAT traversal) e o envio de estatísticas.
    4. Adiciona o servidor do vault e cria a pasta do vault, já compartilhada com ele.
    5. Mostra (e copia) o código deste PC para mandar a quem administra o vault e espera a primeira sincronização.

  Pode ser executado de novo sem problema: o que já estiver feito é mantido.

#>
[CmdletBinding()]
param(
  [string]$PastaVault = '',
  [string]$PastaPrograma = (Join-Path $env:LOCALAPPDATA 'Programs\Syncthing'),
  [string]$PastaConfig = (Join-Path $env:LOCALAPPDATA 'Syncthing'),
  [switch]$SemInicioAutomatico,
  [switch]$SemEsperar,
  [switch]$SemPausa,
  # Migração (só para quem já tem o vault original): usa a pasta que já existe e só envia ao servidor.
  [switch]$UsarPastaExistente,
  [switch]$SomenteEnviar
)

# ====================== CONFIGURAÇÃO ======================
$ServidorDeviceId = 'XIID45O-T6LUNKT-LKSR6RZ-G2QETZH-BFCYSYX-S5LGG6A-JYDTFPE-W6X6JQ3'
$ServidorNome     = 'Servidor do vault'
$PastaId          = 'vault'
$PastaNome        = 'Vault'
$VersaoSyncthing  = '2.1.7'
# Mesmos padrões do .stglobalignore do servidor (estado da janela de cada pessoa, lixeira, temporários).
$PadroesIgnorados = @(
  '.obsidian/workspace.json',
  '.obsidian/workspace-mobile.json',
  '.obsidian/workspaces.json',
  '.obsidian/cache',
  '.trash',
  '(?d)Thumbs.db',
  '(?d)desktop.ini',
  '~$*',
  '*.tmp'
)
# ==============================================================================

$ErrorActionPreference = 'Stop'

# Pasta padrão: Documentos\Vault, a menos que Documentos esteja dentro do OneDrive
# (OneDrive e Syncthing sincronizando a mesma pasta geram conflitos). Nesse caso: C:\Users\<você>\Vault.
if (-not $PastaVault) {
  $docs = [Environment]::GetFolderPath('MyDocuments')
  if ($docs -match 'OneDrive') { $PastaVault = Join-Path $env:USERPROFILE 'Vault' } else { $PastaVault = Join-Path $docs 'Vault' }
}
if ($PastaVault -match 'OneDrive|Dropbox|Google Drive') {
  Write-Host "ERRO: a pasta do vault nao pode ficar dentro de OneDrive/Dropbox/Google Drive: $PastaVault" -ForegroundColor Red
  if (-not $SemPausa) { Read-Host "Aperte Enter para fechar" }; exit 1
}
$ProgressPreference = 'SilentlyContinue'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

function Passo($n, $texto) { Write-Host ""; Write-Host "[$n/5] $texto" -ForegroundColor Cyan }
function Ok($texto)        { Write-Host "      OK  $texto" -ForegroundColor Green }
function Info($texto)      { Write-Host "      $texto" }
function Falha($texto)     { Write-Host ""; Write-Host "ERRO: $texto" -ForegroundColor Red; Write-Host ""; if (-not $SemPausa) { Read-Host "Aperte Enter para fechar" }; exit 1 }

if ($ServidorDeviceId -notmatch '^[A-Z2-7]{7}(-[A-Z2-7]{7}){7}$') {
  Falha "o código do servidor não foi preenchido no instalador. Peça a versão certa a quem te mandou o link."
}

$exe = Join-Path $PastaPrograma 'syncthing.exe'

# ---------------------------------------------------------------- 1. instalar
Passo 1 "Instalando o Syncthing $VersaoSyncthing"
if (Test-Path $exe) {
  Ok "já instalado em $exe"
} else {
  $tmp = Join-Path $env:TEMP ("syncthing-inst-" + [guid]::NewGuid().ToString('N'))
  New-Item -ItemType Directory -Force $tmp | Out-Null
  try {
    $nomeZip = "syncthing-windows-amd64-v$VersaoSyncthing.zip"
    $base = "https://github.com/syncthing/syncthing/releases/download/v$VersaoSyncthing"
    $zip = Join-Path $tmp $nomeZip
    Info "baixando $nomeZip ..."
    Invoke-WebRequest "$base/$nomeZip" -OutFile $zip -UseBasicParsing
    $somas = (Invoke-WebRequest "$base/sha256sum.txt.asc" -UseBasicParsing).Content
    if ($somas -is [byte[]]) { $somas = [Text.Encoding]::ASCII.GetString($somas) }
    $linha = ($somas -split "`n") | Where-Object { $_ -match ("\s\*?" + [regex]::Escape($nomeZip) + "\s*$") } | Select-Object -First 1
    if (-not $linha) { Falha "não achei a soma de verificação oficial de $nomeZip." }
    $esperado = ($linha.Trim() -split '\s+')[0].ToLower()
    $obtido = (Get-FileHash $zip -Algorithm SHA256).Hash.ToLower()
    if ($esperado -ne $obtido) { Falha "o arquivo baixado não confere com a soma oficial (download corrompido ou adulterado)." }
    Ok "download conferido (SHA-256)"
    Expand-Archive $zip -DestinationPath $tmp -Force
    $baixado = Get-ChildItem $tmp -Recurse -Filter syncthing.exe | Select-Object -First 1
    if (-not $baixado) { Falha "syncthing.exe não encontrado dentro do zip." }
    New-Item -ItemType Directory -Force $PastaPrograma | Out-Null
    Copy-Item $baixado.FullName $exe -Force
    Ok "instalado em $exe"
  } finally {
    Remove-Item $tmp -Recurse -Force -ErrorAction SilentlyContinue
  }
}

# ---------------------------------------------------------------- 2. iniciar
Passo 2 "Iniciando o Syncthing e colocando para abrir com o Windows"
$argsSt = "--home=`"$PastaConfig`" --no-browser --no-console"
if (-not $SemInicioAutomatico) {
  $atalho = Join-Path ([Environment]::GetFolderPath('Startup')) 'Syncthing.lnk'
  $ws = New-Object -ComObject WScript.Shell
  $lnk = $ws.CreateShortcut($atalho)
  $lnk.TargetPath = Join-Path $env:WINDIR 'System32\conhost.exe'
  $lnk.Arguments = "--headless `"$exe`" $argsSt"
  $lnk.WorkingDirectory = $PastaPrograma
  $lnk.WindowStyle = 7
  $lnk.Description = 'Syncthing (vault da equipe)'
  $lnk.Save()
  Ok "atalho criado na pasta Inicializar"
}
$rodando = Get-Process syncthing -ErrorAction SilentlyContinue | Where-Object { $_.Path -eq $exe }
if ($rodando) {
  Ok "já está rodando"
} else {
  Start-Process -FilePath $exe -ArgumentList $argsSt -WindowStyle Hidden
  Ok "iniciado"
}

# Espera a API local responder
$cfgXml = Join-Path $PastaConfig 'config.xml'
$api = $null; $chave = $null
for ($i = 0; $i -lt 60; $i++) {
  if (Test-Path $cfgXml) {
    try {
      [xml]$x = Get-Content $cfgXml -Raw -Encoding UTF8
      $chave = $x.configuration.gui.apikey
      $end = $x.configuration.gui.address
      $esquema = if ($x.configuration.gui.tls -eq 'true') { 'https' } else { 'http' }
      if ($chave -and $end) {
        $api = "${esquema}://$end/rest"
        Invoke-RestMethod "$api/system/ping" -Headers @{ 'X-API-Key' = $chave } -TimeoutSec 3 | Out-Null
        break
      }
    } catch { }
  }
  Start-Sleep -Seconds 1
  $api = $null
}
if (-not $api) { Falha "o Syncthing não respondeu em 60 segundos. Reinicie o PC e rode o instalador de novo." }
$H = @{ 'X-API-Key' = $chave }

function Api($metodo, $caminho, $corpo) {
  $p = @{ Uri = "$api$caminho"; Method = $metodo; Headers = $H; TimeoutSec = 15 }
  if ($null -ne $corpo) {
    $p.Body = [Text.Encoding]::UTF8.GetBytes(($corpo | ConvertTo-Json -Depth 6 -Compress))
    $p.ContentType = 'application/json; charset=utf-8'
  }
  Invoke-RestMethod @p
}

# ---------------------------------------------------------------- 3. opções
Passo 3 "Ajustando segurança"
Api Patch '/config/options' @{ natEnabled = $false; urAccepted = -1; startBrowser = $false } | Out-Null
Ok "UPnP desligado (o Syncthing não abre portas no roteador)"
Ok "envio de estatísticas desligado"

# ---------------------------------------------------------------- 4. servidor e pasta
Passo 4 "Ligando ao servidor e criando a pasta do vault"
$devices = @(Api Get '/config/devices' $null)
if ($devices | Where-Object { $_.deviceID -eq $ServidorDeviceId }) {
  Ok "servidor já cadastrado"
} else {
  Api Post '/config/devices' @{ deviceID = $ServidorDeviceId; name = $ServidorNome; addresses = @('dynamic'); autoAcceptFolders = $false } | Out-Null
  Ok "servidor cadastrado"
}

$pastas = @(Api Get '/config/folders' $null)
$existente = $pastas | Where-Object { $_.id -eq $PastaId }
if ($existente) {
  $PastaVault = $existente.path
  Ok "pasta do vault já configurada em $PastaVault"
} else {
  if ($UsarPastaExistente) {
    if (-not (Test-Path $PastaVault)) { Falha "a pasta $PastaVault nao existe." }
  } elseif ((Test-Path $PastaVault) -and (Get-ChildItem $PastaVault -Force | Select-Object -First 1)) {
    Falha "a pasta $PastaVault já existe e não está vazia. Esvazie ou renomeie essa pasta e rode de novo."
  }
  New-Item -ItemType Directory -Force $PastaVault | Out-Null
  Api Post '/config/folders' @{
    id = $PastaId; label = $PastaNome; path = $PastaVault; type = $(if ($SomenteEnviar) { 'sendonly' } else { 'sendreceive' })
    fsWatcherEnabled = $true; rescanIntervalS = 3600
    devices = @(@{ deviceID = $ServidorDeviceId })
  } | Out-Null
  Ok "pasta criada em $PastaVault"
}
Api Post "/db/ignores?folder=$PastaId" @{ ignore = $PadroesIgnorados } | Out-Null
Ok "padrões ignorados aplicados"

# ---------------------------------------------------------------- 5. código do PC
Passo 5 "Código deste PC"
$meuId = (Api Get '/system/status' $null).myID
try { Set-Clipboard -Value $meuId } catch { }
Write-Host ""
Write-Host "   $meuId" -ForegroundColor Yellow
Write-Host ""
Info "Esse código já foi copiado. Mande para quem te mandou o link do tutorial (WhatsApp ou e-mail)."
Info "Assim que o seu PC for aceito no servidor, o vault começa a chegar em: $PastaVault"

if (-not $SemEsperar) {
  Write-Host ""
  Info "Aguardando o PC ser aceito no servidor e a primeira sincronização (pode fechar esta janela; a sincronização continua sozinha)..."
  $inicio = Get-Date
  $avisado = $false
  while (((Get-Date) - $inicio).TotalMinutes -lt 60) {
    Start-Sleep -Seconds 10
    try {
      $con = (Api Get '/system/connections' $null).connections.$ServidorDeviceId
      if (-not $con -or -not $con.connected) { continue }
      if (-not $avisado) { Ok "conectado ao servidor"; $avisado = $true }
      $st = Api Get "/db/status?folder=$PastaId" $null
      if ($st.globalFiles -gt 0 -and $st.needFiles -eq 0 -and $st.state -eq 'idle') {
        Ok "vault sincronizado ($($st.localFiles) arquivos)"
        break
      }
      if ($st.globalFiles -gt 0) { Info ("recebendo... {0} de {1} arquivos" -f $st.localFiles, $st.globalFiles) }
    } catch { }
  }
}

Write-Host ""
Write-Host "Pronto. Agora, no Obsidian: 'Open folder as vault' e escolha:" -ForegroundColor Green
Write-Host "   $PastaVault" -ForegroundColor Green
Write-Host "Interface do Syncthing (se precisar): $($api -replace '/rest$','')"
Write-Host ""
if (-not $SemPausa) { Read-Host "Aperte Enter para fechar" }
