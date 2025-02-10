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
$password = Read-Host "Digite a senha para todos os usuários" -AsSecureString

# Criar usuários numerados sem criar pastas automaticamente
for ($i = 1; $i -le $quantidade; $i++) {
    $num = "{0:D2}" -f $i  # Garante que o número tenha dois dígitos (01, 02, 03...)
    $username = "$prefix$num"

    # Verificar se o usuário já existe
    if (Get-LocalUser -Name $username -ErrorAction SilentlyContinue) {
        Write-Host "O usuário $username já existe! Pulando para o próximo." -ForegroundColor Red
    } else {
        # Criar usuário no Windows sem perfil de diretório criado automaticamente
        New-LocalUser -Name $username -Password $password -FullName $username -PasswordNeverExpires:$true -NoProfile
        
        # Impedir que o usuário altere a senha
        net user $username /Passwordchg:no

        # Adicionar o usuário ao grupo "Usuários" (grupo padrão em português)
        Add-LocalGroupMember -Group "Usuários" -Member $username

        Write-Host "Usuário $username criado com sucesso!" -ForegroundColor Green
    }
}

# Adicionar o endereço file:\\10.0.1.57 à Intranet Local
$site = "file:\\10.0.1.57"
$path = "HKLM:\Software\Microsoft\Windows\CurrentVersion\Internet Settings\ZoneMap\Domains\10.0.1.57"

if (!(Test-Path $path)) {
    New-Item -Path $path -Force | Out-Null
}
New-ItemProperty -Path $path -Name "*" -Value 1 -PropertyType DWORD -Force | Out-Null
Write-Host "Adicionado $site à Intranet Local." -ForegroundColor Yellow

# Configurar o compartilhamento como confiável no Internet Explorer (Zona de Sites Confiáveis)
$internetSettings = "HKLM:\Software\Microsoft\Windows\CurrentVersion\Internet Settings\ZoneMap\Domains\10.0.1.57"
if (!(Test-Path $internetSettings)) {
    New-Item -Path $internetSettings -Force | Out-Null
}
New-ItemProperty -Path $internetSettings -Name "file" -Value 2 -PropertyType DWORD -Force | Out-Null
Write-Host "Compartilhamento adicionado como confiável no Internet Explorer." -ForegroundColor Green

# Configurar mapeamento de unidade para todos os usuários via script de inicialização
$startupBatPath = "$env:ProgramData\Microsoft\Windows\Start Menu\Programs\Startup\MapDriveA.bat"
$batContent = @"
@echo off
net use A: /delete /y 2>nul
net use A: \\10.0.1.57\smb_share /persistent:yes
"@

Set-Content -Path $startupBatPath -Value $batContent -Encoding ASCII
Write-Host "Script de inicialização configurado para mapear a unidade A: para todos os usuários." -ForegroundColor Green

# PAUSAR NO FINAL PARA VER ERROS OU CONFIRMAR QUE TUDO DEU CERTO
Read-Host "Pressione ENTER para finalizar"
