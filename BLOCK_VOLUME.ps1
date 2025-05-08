# ============================================
#          Configurações SMB e Segurança
# ============================================

# Libera convidado (guest) no SMB (equivalente ao GPEDIT)
Write-Host "⏳ Liberando autenticação de convidado (Guest) no SMB..."
Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\LanmanWorkstation\Parameters" -Name AllowInsecureGuestAuth -Value 1 -Type DWord -Force

# Habilita "Enviar resposta LM e NTLM - usar segurança de sessão NTLMv2 se negociado"
Write-Host "⏳ Configurando segurança de rede (LAN Manager)..."
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Lsa" /v LmCompatibilityLevel /t REG_DWORD /d 5 /f

# Permite fallback para sessão nula
Write-Host "⏳ Permitindo fallback para sessão nula..."
reg add "HKLM\SYSTEM\CurrentControlSet\Services\LanmanWorkstation\Parameters" /v EnablePlainTextPassword /t REG_DWORD /d 1 /f

# Habilita a conexão de arquivos de rede sem prompt de segurança
Write-Host "⏳ Removendo verificações de zona de segurança..."
New-Item -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Policies\Attachments" -Force
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Policies\Attachments" -Name SaveZoneInformation -Value 1 -Type DWord -Force

# Marca extensões como seguras (sem prompt de segurança)
Write-Host "⏳ Marcando arquivos de rede como seguros..."
New-Item -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Policies\Associations" -Force
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Policies\Associations" -Name LowRiskFileTypes -Value ".exe;.bat;.cmd;.reg;.vbs" -Type String

# Adiciona o hostname block_volume como Intranet Local (via file://)
Write-Host "⏳ Configurando block_volume como Intranet Local..."
New-Item -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings\ZoneMap\Domains\block_volume" -Force
New-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings\ZoneMap\Domains\block_volume" -Name file -Value 1 -PropertyType DWord -Force

# ============================================
#          Mapeamento da Unidade Z:
# ============================================
Write-Host "⏳ Mapeando Z: para \\block_volume\block_volume..."
Try { 
    net use Z: \\block_volume\block_volume /persistent:yes 
    Write-Host "✅ Unidade Z: mapeada com sucesso para \\block_volume\block_volume." -ForegroundColor Green
} Catch {
    Write-Host "❌ Falha ao mapear a unidade Z:. Verifique se o host está acessível." -ForegroundColor Red
}

# ============================================
#          Criar tarefa agendada
# ============================================
Write-Host "⏳ Configurando tarefa agendada para boot automático..."
$action = New-ScheduledTaskAction -Execute "PowerShell.exe" -Argument "-File `"$PWD\mapear_samba.ps1`""
$trigger = New-ScheduledTaskTrigger -AtStartup
$principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest
Register-ScheduledTask -Action $action -Trigger $trigger -Principal $principal -TaskName "Mapear_Samba_BlockVolume" -Description "Mapeia Z: automaticamente no boot"

Write-Host "✅ Tarefa agendada criada com sucesso. Tudo pronto!" -ForegroundColor Green
