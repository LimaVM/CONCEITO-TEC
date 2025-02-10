# Verifica se o script está rodando como Administrador
$admin = [System.Security.Principal.WindowsPrincipal] [System.Security.Principal.WindowsIdentity]::GetCurrent()
if (-not $admin.IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "Este script precisa ser executado como Administrador!" -ForegroundColor Red
    Start-Process powershell -ArgumentList ("-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"") -Verb RunAs
    exit
}

# Solicitar o prefixo do usuário e a quantidade de usuários
$prefix = Read-Host "Digite o prefixo do usuário"
$quantidade = Read-Host "Digite a quantidade de usuários a serem criados"

# Solicitar a senha única para todos os usuários
$password = Read-Host "Digite a senha para todos os usuários"

# Criar usuários numerados
for ($i = 1; $i -le $quantidade; $i++) {
    $num = "{0:D2}" -f $i  # Garante que o número tenha dois dígitos (01, 02, 03...)
    $username = "$prefix$num"

    # Verificar se o usuário já existe
    if (Get-LocalUser -Name $username -ErrorAction SilentlyContinue) {
        Write-Host "O usuário $username já existe! Pulando para o próximo." -ForegroundColor Red
    } else {
        # Criar usuário no Windows
        $securePassword = ConvertTo-SecureString $password -AsPlainText -Force
        New-LocalUser -Name $username -Password $securePassword -FullName $username -PasswordNeverExpires:$true

        # Impedir que o usuário altere a senha
        net user $username /Passwordchg:no

        # Adicionar o usuário ao grupo "Users"
        Add-LocalGroupMember -Group "Users" -Member $username

        Write-Host "Usuário $username criado com sucesso!" -ForegroundColor Green

        # Salvar credenciais temporariamente no Gerenciador de Credenciais
        cmdkey /generic:TERMSRV/127.0.0.1 /user:$username /pass:$password

        # Criar um arquivo RDP para login automático
        $rdpFile = "C:\Users\Public\$username.rdp"
        $rdpContent = @"
screen mode id:i:2
desktopwidth:i:1280
desktopheight:i:720
session bpp:i:32
auto connect:i:1
full address:s:127.0.0.1
username:s:$username
"@
        Set-Content -Path $rdpFile -Value $rdpContent
        Write-Host "Arquivo RDP criado para $username em $rdpFile" -ForegroundColor Yellow

        # Conectar automaticamente ao usuário via RDP
        Start-Process "mstsc.exe" -ArgumentList "$rdpFile"
        Write-Host "Conectando via RDP com o usuário $username para inicializar tudo..." -ForegroundColor Cyan

        # Aguarda 10 segundos e tenta fechar a conexão RDP apenas se ela estiver aberta
        Start-Sleep -Seconds 10
        $mstscProcess = Get-Process -Name "mstsc" -ErrorAction SilentlyContinue
        if ($mstscProcess) {
            Stop-Process -Name "mstsc" -Force
            Write-Host "Sessão RDP para $username finalizada automaticamente!" -ForegroundColor Red
        } else {
            Write-Host "Nenhum processo RDP encontrado para fechar." -ForegroundColor Yellow
        }
    }
}

# Adicionar APENAS o endereço file:\\10.0.1.57 à Intranet Local
$site = "file:\\10.0.1.57"
$path = "HKLM:\Software\Microsoft\Windows\CurrentVersion\Internet Settings\ZoneMap\EscDomains\10.0.1.57"

if (!(Test-Path $path)) {
    New-Item -Path $path -Force | Out-Null
}
New-ItemProperty -Path $path -Name "*" -Value 1 -PropertyType DWORD -Force | Out-Null
Write-Host "Adicionado $site à Intranet Local." -ForegroundColor Yellow

# Mapear unidade de rede A: para TODOS os usuários
$networkDrive = "A:"
$networkPath = "\\10.0.1.57\smb_share"

# Remover unidade existente (se houver)
if (Test-Path $networkDrive) {
    Write-Host "Removendo unidade de rede existente..." -ForegroundColor Yellow
    net use $networkDrive /delete /y
}

# Mapear o novo disco para TODOS OS USUÁRIOS
Write-Host "Mapeando unidade de rede $networkDrive para $networkPath para TODOS os usuários..." -ForegroundColor Yellow
New-Item -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" -Name "MapDrive" -Value "net use $networkDrive $networkPath /persistent:yes" -PropertyType String -Force

Write-Host "Unidade de rede $networkDrive mapeada com sucesso para $networkPath!" -ForegroundColor Green

# Criar um script para **LOGIN AUTOMÁTICO** na primeira inicialização
$logonScript = "C:\Users\Public\first_login.bat"
$logonContent = @"
@echo off
net use A: \\10.0.1.57\smb_share /persistent:yes
REG DELETE "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" /V MapDrive /F
DEL %0
"@
Set-Content -Path $logonScript -Value $logonContent

# Configurar o script para rodar no primeiro login
New-Item -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce" -Name "FirstLoginSetup" -Value $logonScript -PropertyType String -Force

Write-Host "Configuração para login automático na primeira inicialização feita com sucesso!" -ForegroundColor Green

# PAUSAR NO FINAL PARA VER ERROS OU CONFIRMAR QUE TUDO DEU CERTO
Read-Host "Pressione ENTER para finalizar"
