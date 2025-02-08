# Definir o fuso horário para Brasília (GMT-3)
Write-Host "Definindo o fuso horário para Brasília..."
Set-TimeZone -Id "E. South America Standard Time"

# Definir o idioma de exibição do sistema para português do Brasil
Write-Host "Definindo o idioma do sistema para Português (Brasil)..."
Set-WinUILanguageOverride -Language pt-BR
Set-WinUserLanguageList -LanguageList pt-BR -Force
Set-SystemPreferredUILanguage pt-BR
Set-WinHomeLocation -GeoId 32  # 32 é o código do Brasil
Set-Culture -CultureInfo pt-BR
Set-WinUserLanguageList pt-BR -Force

# Perguntar ao usuário se deseja reiniciar agora
$reiniciar = Read-Host "As alterações foram aplicadas. Deseja reiniciar agora? (S/N)"

if ($reiniciar -match "^[sS]$") {
    Write-Host "Reiniciando o sistema em 10 segundos..."
    Start-Sleep -Seconds 10
    Restart-Computer -Force
} else {
    Write-Host "O sistema não será reiniciado agora. Algumas alterações podem requerer um reinício para serem aplicadas." -ForegroundColor Yellow
}
