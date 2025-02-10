# Verifica se o script está rodando como Administrador
$admin = [System.Security.Principal.WindowsPrincipal] [System.Security.Principal.WindowsIdentity]::GetCurrent()
if (-not $admin.IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "Este script precisa ser executado como Administrador!" -ForegroundColor Red
    Start-Process powershell -ArgumentList ("-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"") -Verb RunAs
    exit
}

# Função para exibir erros detalhados
function Show-Error {
    param (
        [string]$ErrorMessage
    )
    Write-Host "ERRO: $ErrorMessage" -ForegroundColor Red
    Write-Host "Detalhes do erro: $($Error[0].Exception.Message)" -ForegroundColor Yellow
    Read-Host "Pressione ENTER para continuar..."
}

# Solicitar o prefixo do usuário e a quantidade de usuários
try {
    $prefix = Read-Host "Digite o prefixo do usuário"
    $quantidade = [int](Read-Host "Digite a quantidade de usuários a serem criados")
    if ($quantidade -le 0) {
        throw "A quantidade de usuários deve ser maior que zero."
    }
} catch {
    Show-Error "Entrada inválida para quantidade de usuários."
    exit
}

# Solicitar a senha única para todos os usuários
try {
    $password = Read-Host "Digite a senha para todos os usuários"
} catch {
    Show-Error "Erro ao capturar a senha."
    exit
}

# Criar usuários numerados sem criar pastas automaticamente
for ($i = 1; $i -le $quantidade; $i++) {
    $num = "{0:D2}" -f $i  # Garante que o número tenha dois dígitos (01, 02, 03...)
    $username = "$prefix$num"

    try {
        # Verificar se o usuário já existe
        if (Get-LocalUser -Name $username -ErrorAction SilentlyContinue) {
            Write-Host "O usuário $username já existe! Pulando para o próximo." -ForegroundColor Red
        } else {
            # Criar usuário no Windows sem perfil de diretório criado automaticamente
            $securePassword = ConvertTo-SecureString $password -AsPlainText -Force
            New-LocalUser -Name $username -Password $securePassword -FullName $username -PasswordNeverExpires:$true
            
            # Impedir que o usuário altere a senha
            net user $username /Passwordchg:no

            # Adicionar o usuário ao grupo "Users" (grupo padrão em inglês)
            Add-LocalGroupMember -Group "Users" -Member $username

            Write-Host "Usuário $username criado com sucesso!" -ForegroundColor Green
            
            # Criar credencial no Windows Credential Manager para RDP
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

            # Conectar automaticamente ao usuário via RDP e fechar após 15 segundos
            $rdpProcess = Start-Process "mstsc.exe" -ArgumentList "$rdpFile" -PassThru
            Write-Host "Conectando via RDP com o usuário $username..." -ForegroundColor Cyan
            Start-Sleep -Seconds 15
            Stop-Process -Id $rdpProcess.Id -Force
            Write-Host "Sessão RDP para $username finalizada automaticamente após 15 segundos!" -ForegroundColor Red
        }
    } catch {
        Show-Error "Erro ao criar o usuário $username."
    }
}

# Adicionar o endereço file:\\10.0.1.57 à Intranet Local
try {
    $site = "file:\\10.0.1.57"
    $path = "HKLM:\Software\Microsoft\Windows\CurrentVersion\Internet Settings\ZoneMap\Domains\10.0.1.57"

    if (!(Test-Path $path)) {
        New-Item -Path $path -Force | Out-Null
    }
    New-ItemProperty -Path $path -Name "*" -Value 1 -PropertyType DWORD -Force | Out-Null
    Write-Host "Adicionado $site à Intranet Local." -ForegroundColor Yellow
} catch {
    Show-Error "Erro ao adicionar $site à Intranet Local."
}

# Configurar o compartilhamento como confiável no Internet Explorer (Zona de Sites Confiáveis)
try {
    $internetSettings = "HKLM:\Software\Microsoft\Windows\CurrentVersion\Internet Settings\ZoneMap\Domains\10.0.1.57"
    if (!(Test-Path $internetSettings)) {
        New-Item -Path $internetSettings -Force | Out-Null
    }
    New-ItemProperty -Path $internetSettings -Name "file" -Value 2 -PropertyType DWORD -Force | Out-Null
    Write-Host "Compartilhamento adicionado como confiável no Internet Explorer." -ForegroundColor Green
} catch {
    Show-Error "Erro ao configurar o compartilhamento como confiável no Internet Explorer."
}

# Configurar mapeamento de unidade para todos os usuários via script de inicialização
try {
    $startupBatPath = "$env:ProgramData\Microsoft\Windows\Start Menu\Programs\Startup\MapDriveA.bat"
    $batContent = @"
@echo off
net use A: /delete /y 2>nul
net use A: \\10.0.1.57\smb_share /persistent:yes
"@

    Set-Content -Path $startupBatPath -Value $batContent -Encoding ASCII
    Write-Host "Script de inicialização configurado para mapear a unidade A: para todos os usuários." -ForegroundColor Green
} catch {
    Show-Error "Erro ao configurar o mapeamento de unidade."
}

# PAUSAR NO FINAL PARA VER ERROS OU CONFIRMAR QUE TUDO DEU CERTO
Read-Host "Pressione ENTER para finalizar"
