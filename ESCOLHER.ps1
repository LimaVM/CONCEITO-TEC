# Lista de scripts disponíveis
$opcoes = @{
    "1" = "https://raw.githubusercontent.com/LimaVM/CONCEITO-TEC/refs/heads/main/CRIADOR-LOAD.ps1"
    "2" = "https://raw.githubusercontent.com/LimaVM/CONCEITO-TEC/refs/heads/main/UNI%20SCRIPT.ps1"
    "3" = "https://raw.githubusercontent.com/LimaVM/CONCEITO-TEC/refs/heads/main/PTBR.ps1"
}

# Exibir opções para o usuário
Write-Host "`n=========== MENU DE SCRIPTS ===========" -ForegroundColor Cyan
Write-Host "1 - Criador de Usuários com Load Balance" -ForegroundColor Green
Write-Host "2 - Adicionar Bloco de Volume Virtual a Todos os Usuários" -ForegroundColor Green
Write-Host "3 - Ajustar Horário do Servidor (PT-BR)" -ForegroundColor Green
Write-Host "========================================`n"

# Capturar escolha do usuário
$escolha = Read-Host "Digite o número correspondente ao script desejado"

# Verificar se a escolha é válida
if ($opcoes.ContainsKey($escolha)) {
    $url = $opcoes[$escolha]
    Write-Host "`nBaixando e executando o script selecionado..." -ForegroundColor Yellow

    try {
        # Executar o script via IRM
        Invoke-Expression (Invoke-RestMethod -Uri $url)
    } catch {
        Write-Host "Erro ao baixar ou executar o script. Verifique sua conexão e tente novamente." -ForegroundColor Red
    }
} else {
    Write-Host "`n[ERRO] Opção inválida. Execute o script novamente e escolha uma opção válida." -ForegroundColor Red
}
