# Verifica se o script está rodando como Administrador
$admin = [System.Security.Principal.WindowsPrincipal] [System.Security.Principal.WindowsIdentity]::GetCurrent()
if (-not $admin.IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "Este script precisa ser executado como Administrador!" -ForegroundColor Red
    
    # Reexecuta o script com permissões elevadas
    Start-Process powershell -ArgumentList ("-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"") -Verb RunAs
    exit
}

# Solicitar o prefixo do usuário e a quantidade de usuários
$prefix = Read-Host "Digite o prefixo do usuário"
$quantidade = Read-Host "Digite a quantidade de usuários a serem criados"

# Solicitar a senha única para todos os usuários
$password = Read-Host "Digite a senha para todos os usuários" -AsSecureString

# Criar usuários numerados
for ($i = 1; $i -le $quantidade; $i++) {
    $num = "{0:D2}" -f $i  # Garante que o número tenha dois dígitos (01, 02, 03...)
    $username = "$prefix$num"

    # Verificar se o usuário já existe
    if (Get-LocalUser -Name $username -ErrorAction SilentlyContinue) {
        Write-Host "O usuário $username já existe! Pulando para o próximo." -ForegroundColor Red
    } else {
        # Criar usuário no Windows
        New-LocalUser -Name $username -Password $password -FullName $username -PasswordNeverExpires:$true

        # Impedir que o usuário altere a senha
        Set-LocalUser -Name $username -PasswordNeverExpires:$true

        # Adicionar o usuário ao grupo "Users"
        Add-LocalGroupMember -Group "Users" -Member $username

        Write-Host "Usuário $username criado com sucesso!" -ForegroundColor Green

        # Criar diretório do usuário em C:\Users
        $userDir = "C:\Users\$username"
        if (!(Test-Path $userDir)) {
            New-Item -ItemType Directory -Path $userDir -Force | Out-Null
            Write-Host "Diretório do usuário criado em $userDir" -ForegroundColor Green
        }

        # Definir permissões de acesso ao diretório
        icacls $userDir /grant "$username`:(OI)(CI)F" /T /Q
    }
}

# PAUSAR NO FINAL PARA VER ERROS OU CONFIRMAR QUE TUDO DEU CERTO
Write-Host "Pressione ENTER para sair..." -ForegroundColor Cyan
Read-Host | Out-Null
