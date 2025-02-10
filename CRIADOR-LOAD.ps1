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

# Criar usuários numerados sem criar pastas automaticamente
for ($i = 1; $i -le $quantidade; $i++) {
    $num = "{0:D2}" -f $i  # Garante que o número tenha dois dígitos (01, 02, 03...)
    $username = "$prefix$num"

    # Verificar se o usuário já existe
    if (Get-LocalUser -Name $username -ErrorAction SilentlyContinue) {
        Write-Host "O usuário $username já existe! Pulando para o próximo." -ForegroundColor Red
    } else {
        # Criar usuário no Windows sem perfil de diretório criado automaticamente
        $securePassword = ConvertTo-SecureString $password -AsPlainText -Force
        New-LocalUser -Name $username -Password $securePassword -FullName $username -PasswordNeverExpires:$true -NoProfile
        
        # Impedir que o usuário altere a senha
        net user $username /Passwordchg:no

        # Adicionar o usuário ao grupo "Users"
        Add-LocalGroupMember -Group "Users" -Member $username

        Write-Host "Usuário $username criado com sucesso!" -ForegroundColor Green
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

# Configurar o compartilhamento como confiável no Internet Explorer
$internetSettings = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings\ZoneMap\Domains\10.0.1.57"
if (!(Test-Path $internetSettings)) {
    New-Item -Path $internetSettings -Force | Out-Null
}
New-ItemProperty -Path $internetSettings -Name "file" -Value 1 -PropertyType DWORD -Force | Out-Null
Write-Host "Compartilhamento adicionado como confiável no Internet Explorer." -ForegroundColor Green

# Mapear unidade de rede A: para TODOS os usuários
$networkDrive = "A:"
$networkPath = "\\10.0.1.57\smb_share"

Write-Host "Mapeando unidade de rede $networkDrive para $networkPath..." -ForegroundColor Yellow

# Tenta remover a unidade anterior, caso já esteja mapeada
net use $networkDrive /delete /y 2>$null

# Mapear a nova unidade
$mapResult = net use $networkDrive $networkPath /persistent:yes

if ($mapResult -match "The command completed successfully") {
    Write-Host "Unidade de rede $networkDrive mapeada com sucesso para $networkPath!" -ForegroundColor Green
} else {
    Write-Host "Falha ao mapear unidade de rede. Verifique a conexão e permissões." -ForegroundColor Red
}

# PAUSAR NO FINAL PARA VER ERROS OU CONFIRMAR QUE TUDO DEU CERTO
Read-Host "Pressione ENTER para finalizar"
