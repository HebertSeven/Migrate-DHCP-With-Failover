<#

.SYNOPSIS
  DHCP Audit.

.DESCRIPTION
  This script audits changes made to the DHCP server such as scopes, IP reservations, etc. 

.OUTPUTS
  The log file will be created in HTML model in the same directory from this script.

.NOTES
  Version:  1.0.0
  Author:   Hebert Seven
  Date:     07/05/2025
  Site:     https://hebertseven.com
  Github:   https://github.com/hebertseven
  
#>

#---------------------------------------------------------[Initializations]--------------------------------------------------------


############################################
############################################

# Defining UTF-8 encode for imput and output
[Console]::InputEncoding = [System.Text.Encoding]::UTF8
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

############################################
############################################


<# Validade if the script is running with administratitve privileges

if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    
    Write-Host "This script requires administrative privileges. Running elevation..." -ForegroundColor Yellow
    
    Start-Process powershell.exe -Verb RunAs -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`" -WindowStyle Normal"
    
    Exit
}
#>

############################################
############################################

# Console Customization
function Set-ConsoleCustomization {
    $Host.UI.RawUI.ForegroundColor = "White"
    $Host.UI.RawUI.BackgroundColor = "Black"
    Clear-Host
}

# Applying Console Customization
Set-ConsoleCustomization

############################################
############################################

function Show-Header {
    Clear-Host
    Write-Host "==============================================" -ForegroundColor Cyan
    Write-Host "       DHCP MIGRATION - WITH FAILOVER         " -ForegroundColor Yellow
    Write-Host "==============================================" -ForegroundColor Cyan
    Write-Host " Owner:  Hebert Seven"                          -ForegroundColor Green
    Write-Host " Site:   https://hebetseven.com"                -ForegroundColor Green
    Write-Host " GitHub: https://github.com/hebertseven"        -ForegroundColor Green
    Write-Host "=============================================="
}

function Show-Menu {
    Write-Host "Select one option:" -ForegroundColor Yellow
    Write-Host "==============================================" -ForegroundColor Cyan
    Write-Host "1 - Install DHCP Server"     -ForegroundColor White
    Write-Host "2 - Create DHCP Failover"    -ForegroundColor White
    Write-Host "3 - Remove DHCP Failover"    -ForegroundColor White
    Write-Host "4 - Export DHCP Settings"    -ForegroundColor White
    Write-Host "5 - Import DHCP Settings"    -ForegroundColor White
    Write-Host "6 - Authorize DHCP Server"   -ForegroundColor White
    Write-Host "7 - Unauthorize DHCP Server" -ForegroundColor White
    Write-Host "0 - Sair do script"          -ForegroundColor Red
    Write-Host "==============================================" -ForegroundColor Cyan
}

############################################
############################################

function Install-DHCP-Role {
Write-Host "`n Installing DHCP Role.`n" -ForegroundColor Green

Add-WindowsFeature Dhcp –IncludeManagementTools 

Write-Host "`n Adding security DHCP Groups.`n" -ForegroundColor Green

Start-Sleep -Seconds 3

Add-DhcpServerSecurityGroup

Write-Host "`n Authorize DHCP Server in domain.`n" -ForegroundColor Green

Start-Sleep -Seconds 3

Add-DhcpServerInDC

Start-Sleep -Seconds 3

#=======================================
# Setting Server manager to not show
# warning about additional configuration
#=======================================

Set-ItemProperty –Path registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\ServerManager\Roles\12 –Name ConfigurationState –Value 2

Write-Host "`n A instalação foi bem-sucedida.`n" -ForegroundColor Green

}

function Create-DHCP-Failover {

Write-Host "`n Criando Failover.`n" -ForegroundColor Green

# Define o parceiro de failover
$Parceiro = Read-Host "Digite o nome do Parceiro (ex: dhcp1.seven.corp)"

# Nome da parceria de failover
$NomeFailover = Read-Host "Digite o nome do Failover"

# Método de failover: Load Balancing (Balanceamento de Carga)
# Define a porcentagem de equilíbrio do Load Balancing
$LoadBalancePercent = 50

# Define a senha secreta
$SharedSecret = Read-Host "Digite a senha do Secret" -AsSecureString

# Obtém todos os escopos DHCP configurados no servidor local
$Escopos = (Get-DhcpServerv4Scope).ScopeId

# Verifica se há escopos antes de prosseguir
if ($Escopos.Count -eq 0) {
    Write-Host "Nenhum escopo DHCP encontrado no servidor. Encerrando o script." -ForegroundColor Yellow
    return
}

# Cria a parceria de failover

Add-DhcpServerv4Failover -Name $NomeFailover -PartnerServer $Parceiro -ScopeId $Escopos -LoadBalancePercent $LoadBalancePercent -AutoStateTransition $True -SharedSecret $SharedSecret

Write-Host "`n Parceria de failover '$NomeFailover' criada com sucesso entre este servidor e $Parceiro.`n" -ForegroundColor Green

Write-Host "`n Todos os escopos foram processados para failover.`n" -ForegroundColor Green


}

function Remove-DHCP-Failover {

# Define o parceiro de failover

$FailoverName = Read-Host "Type the name of failover to be removed:"

Remove-DhcpServerv4Failover –Name $FailoverName

Write-Host "`n Failover was removed successfully.`n" -ForegroundColor Green

Get-DhcpServerv4Failover

}

function Export-DHCP-Settings {

Clear

Write-Host "`n Creating folder to export configuration.`n" -ForegroundColor Green
mkdir C:\DHCP-MIGRATION
mkdir C:\DHCP-MIGRATION\EXPORT-SETTINGS
mkdir C:\DHCP-MIGRATION\BACKUP-ACTUAL-CONFIGURATION

Export-DhcpServer –File C:\DHCP-MIGRATION\EXPORT-SETTINGS\Export-Settings.xml -Verbose

Write-Host "`n Export was realized successfully. Data was saved in C:\DHCP-MIGRATION`n" -ForegroundColor Green

}

function Import-DHCP-Settings {

Import-DhcpServer –File C:\DHCP-MIGRATION\EXPORT-SETTINGS\Export-Settings.xml -BackupPath C:\DHCP-MIGRATION\BACKUP-ACTUAL-CONFIGURATION -ServerConfigOnly -Verbose -Force

Write-Host "`n Import was realized successfully.`n" -ForegroundColor Green

}

function Authorize-DHCP-Server {

Add-DhcpServerInDC

Write-Host "`n DHCP server was authorized.`n" -ForegroundColor Green

}

function Unauthorize-DHCP-Server {

Remove-DhcpServerInDC

Write-Host "`n DHCP server was desauthorized.`n" -ForegroundColor Green

}

############################################
############################################

# Loop do menu
do {
    Show-Header
    Show-Menu
    $input = Read-Host "Digite o número correspondente à opção desejada: "
    switch ($input) {
        '1' { Install-DHCP-Role }
        '2' { Create-DHCP-Failover }
        '3' { Remove-DHCP-Failover }
        '4' { Export-DHCP-Settings }
        '5' { Import-DHCP-Settings }
        '6' { Authorize-DHCP-Server }
        '7' { Unauthorize-DHCP-Server }
        '0' { Write-Host "Saindo do script..." -ForegroundColor Red }
        default { Write-Host "Opção inválida, tente novamente." -ForegroundColor Red }
    }
    if ($input -ne '0') {
        Write-Host "Pressione Enter para continuar..." -ForegroundColor Gray
        $null = Read-Host
    }
} until ($input -eq '0')

############################################
############################################