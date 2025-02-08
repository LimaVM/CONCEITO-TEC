# Verifica se o script está rodando como Administrador
$janelaAdmin = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
if (-not $janelaAdmin.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "🚨 Este script precisa ser executado como Administrador!"
    Write-Host "🔄 Solicitando permissão..."
    Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    Exit
}

# Permite escolher a ação
$acao = Read-Host "Digite '1' para mapear uma unidade ou '2' para remover uma unidade"

# Se for para mapear uma nova unidade
if ($acao -eq "1") {
    # Pergunta a letra da unidade a ser mapeada
    $letraUnidade = Read-Host "Digite a letra da unidade que deseja mapear (Ex: Z:)"

    # Pergunta o IP do servidor e o diretório compartilhado
    $ipServidor = Read-Host "Digite o IP do servidor (Ex: 10.0.1.100)"
    $diretorioCompartilhado = Read-Host "Digite o diretório compartilhado no servidor (Ex: Compartilhamento)"
    $caminhoRede = "\\$ipServidor\$diretorioCompartilhado"

    Write-Host "⏳ Configurando unidade $letraUnidade para todos os usuários..."

    # Caminhos do Registro
    $regPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run"
    $netlogonPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer\Run"

    # Criar chaves se não existirem
    if (-not (Test-Path $regPath)) {
        New-Item -Path $regPath -Force | Out-Null
    }
    if (-not (Test-Path $netlogonPath)) {
        New-Item -Path $netlogonPath -Force | Out-Null
    }

    # Adiciona o mapeamento ao Registro para ser permanente
    Set-ItemProperty -Path $regPath -Name "Mapeamento_$letraUnidade" -Value "net use $letraUnidade $caminhoRede /persistent:yes"
    Set-ItemProperty -Path $netlogonPath -Name "Mapeamento_$letraUnidade" -Value "net use $letraUnidade $caminhoRede /persistent:yes"

    # Adiciona o servidor à Intranet Local no Registro do Windows
    $intranetZone = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings\ZoneMap\Domains\$ipServidor"
    if (-not (Test-Path $intranetZone)) {
        New-Item -Path $intranetZone -Force | Out-Null
    }
    Set-ItemProperty -Path $intranetZone -Name "*" -Value 1  # 1 = Intranet Local

    # Aplica o mapeamento imediatamente para a sessão atual
    net use $letraUnidade $caminhoRede /persistent:yes
    Write-Host "✅ Unidade $letraUnidade mapeada permanentemente para $caminhoRede!"
    Write-Host "✅ Servidor $ipServidor adicionado à zona de Intranet Local para execução de arquivos!"

} elseif ($acao -eq "2") {
    # Pergunta a letra da unidade a ser removida
    $letraUnidade = Read-Host "Digite a letra da unidade que deseja remover (Ex: Z:)"

    Write-Host "⏳ Removendo a unidade $letraUnidade de todos os usuários..."

    # Caminhos do Registro
    $regPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run"
    $netlogonPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer\Run"

    # Remove do registro para não ser mais recriada automaticamente
    if (Test-Path $regPath) {
        Remove-ItemProperty -Path $regPath -Name "Mapeamento_$letraUnidade" -ErrorAction SilentlyContinue
    }
    if (Test-Path $netlogonPath) {
        Remove-ItemProperty -Path $netlogonPath -Name "Mapeamento_$letraUnidade" -ErrorAction SilentlyContinue
    }

    # Remove da sessão atual
    net use $letraUnidade /delete /yes

    # Remove o servidor da Intranet Local
    $ipServidor = Read-Host "Digite o IP do servidor da unidade removida (Ex: 10.0.1.100)"
    $intranetZone = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings\ZoneMap\Domains\$ipServidor"
    if (Test-Path $intranetZone) {
        Remove-Item -Path $intranetZone -Recurse -Force
    }

    Write-Host "✅ Unidade $letraUnidade removida permanentemente!"
    Write-Host "✅ Servidor $ipServidor removido da zona de Intranet Local!"

} else {
    Write-Host "❌ Opção inválida. Execute o script novamente."
}
