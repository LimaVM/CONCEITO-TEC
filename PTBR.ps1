# Definir o fuso horário para Brasília (GMT-3)
Write-Host "Definindo o fuso horário para Brasília..."
Set-TimeZone -Id "E. South America Standard Time"

# Perguntar ao usuário se deseja reiniciar agora
$reiniciar = Read-Host "O fuso horário foi ajustado. Deseja reiniciar agora? (S/N)"

if ($reiniciar -match "^[sS]$") {
    Write-Host "Reiniciando o sistema em 10 segundos..."
    Start-Sleep -Seconds 10
    Restart-Computer -Force
} else {
    Write-Host "O sistema não será reiniciado agora. Algumas alterações podem requerer um reinício para serem aplicadas." -ForegroundColor Yellow
}
