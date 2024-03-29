
$ScriptDirectory = Split-Path -Path $MyInvocation.MyCommand.Definition -Parent
try {
    .("$ScriptDirectory\Functions.ps1")
    .("$ScriptDirectory\Rules.ps1")
}
catch {
    Write-Host "Error while loading supporting PowerShell Scripts" 
}
Write-Host "$ScriptDirectory\Functions.ps1"



$TEXT="Set Pruefen state.
Code GLOBAL_LAYOUT_VARIANTE=00
Code HUD_VARIANTE= 6 ( HUD High 3+)
Code AG_MPA_MSP_VIEW = 01.
Code PIA_HUD_EIN_AUS=01
Code LDM_NHA_ENABLE = 1
Code LDM_NHA_ENABLE
SID_WRN_NHA_STATE = 1, SID_WRN_NHA_INFORMATION = 1, SID_WRN_NHA_HINT = 1, BR_KENNUNG =2
Code LDM_HUD_NHA_ENABLE = 01
LDM_XCC_ENABLE = 02 LDM_XCC_HUD_ANZ_ENABLE = 01 LDM_ANZEIGE_DAUER = 0F
"


$Result=Lexer $TEXT
foreach($line in $Result){
foreach($token in $line){
write-Host $token.Name
}}

Executor -file 'C:\Users\uia99339\Desktop\SSTS_Gen5CI_SPD - S7.seq'