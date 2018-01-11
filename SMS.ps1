########################################################################################################
########                                                                                       #########
######## Nexmo SMS Gateway                                                                     #########
######## Written by Gareth www.virtualisedfruit.co.uk                                          #########
######## Version 1.0 11/02/2018                                                                #########
######## Parts inspired by                                                                     #########
######## https://gallery.technet.microsoft.com/scriptcenter/Powershell-script-to-5edcdaea      #########
########                                                                                       #########
########################################################################################################


if(!(Test-Path .\smsconfig.xml))
{
    Write-Host "smsconfig.xml Config file doesn't exist in root location." ; exit
}
$xml = [XML](Get-Content .\smsconfig.xml)

$ApiKey = $xml.variables.ApiKey
$APISecret = $xml.variables.APISecret
$ADServer= $xml.variables.ADServer
$CC= $xml.variables.CountryCode
$SMS = $args[1]
$SMSFrom = $args[2]
$UserGroup = $args[0]


function Get-TimeStamp {
    
    return "[{0:MM/dd/yy} {0:HH:mm:ss}]" -f (Get-Date)
    
}

function Send-SMSUsers {

$SMSUsers | ForEach-Object { 

if ($_.Mobile.StartsWith(7) -and $CC -eq 'ChangeMe') {Write-Host 'Please set the country code in the config file'}

if ($_.Mobile.StartsWith(7) -and $CC -ne 'ChangeMe') {
$url = 'https://rest.nexmo.com/sms/json?api_key=' + $ApiKey + '&api_secret=' + "$APISecret" + '&to=' + $CC + $_.Mobile + '&from=' + $SMSFrom + '&text=Hi+' + $_."First Name"+ '+' + $sms 
Invoke-WebRequest –Uri $url

Write-Output "$(Get-TimeStamp) " $url | Out-file .\SMSlog$(Get-Date -f dd-MM-yyyy).txt -append }

if ($_.Mobile.StartsWith(0) -and $CC -eq 'ChangeMe') {Write-Host 'Please set the country code in the config file'}

if ($_.Mobile.StartsWith(0) -and $CC -ne 'ChangeMe') {$url = 'https://rest.nexmo.com/sms/json?api_key=' + $ApiKey + '&api_secret=' + "$APISecret" + '&to=' + $CC + $_.Mobile.substring(1) + '&from=' + $SMSFrom + '&text=Hi+' + $_."First Name"+ '+' + $sms 
Invoke-WebRequest –Uri $url

Write-Output "$(Get-TimeStamp) " $url | Out-file .\SMSlog$(Get-Date -f dd-MM-yyyy).txt -append}
if ($_.Mobile.StartsWith('+')) {$url = 'https://rest.nexmo.com/sms/json?api_key=' + $ApiKey + '&api_secret=' + "$APISecret" + '&to=' + $_.Mobile + '&from=' + $SMSFrom + '&text=Hi+' + $_."First Name"+ '+' + $sms 
Invoke-WebRequest –Uri $url

Write-Output "$(Get-TimeStamp) " $url | Out-file .\SMSlog$(Get-Date -f dd-MM-yyyy).txt -append}
}
} 

function Send-AllSMSUsers {
if ($ADServer -eq 'SetMe') {Write-Host "Please go set the AD Server in the Config File" ; exit }
$SearchBase = $xml.variables.SearchBase
if ($SearchBase -eq 'SetMe') {Write-Host "Please go set the Search Base DN in the Config File" ; exit }
Write-Output "$(Get-TimeStamp) <<Staring Mass AD SMS>> " | Out-file .\SMSlog$(Get-Date -f dd-MM-yyyy).txt -append

$AllADUsers = Get-ADUser -server $ADServer `
-Credential $GetAdminact -searchbase $SearchBase `
-Filter * -Properties * | ? {$_.mobilePhone -ne $null}

$SMSUsers = $AllADUsers | Select-Object @{Label = "First Name";Expression = {$_.GivenName}},
@{Label = "Last Name";Expression = {$_.Surname}},
@{Label = "Mobile";Expression = {$_.mobilePhone}}, 
@{Label = "Account Status";Expression = {if (($_.Enabled -eq 'TRUE')  ) {'Enabled'} Else {'Disabled'}}}, # the 'if statement# replaces $_.Enabled
@{Label = "Last LogOn Date";Expression = {$_.lastlogondate}} 





Write-Output "$(Get-TimeStamp) <<Sending to the following users>> " | Out-file .\SMSlog$(Get-Date -f dd-MM-yyyy).txt -append
Write-Output "$(Get-TimeStamp)  " $SMSUsers| Out-file .\SMSlog$(Get-Date -f dd-MM-yyyy).txt -append




Send-SMSUsers 

Write-Output "$(Get-TimeStamp) <<Ending Mass AD Send>> " | Out-file .\SMSlog$(Get-Date -f dd-MM-yyyy).txt -append
}

function Send-GroupSMSUsers {
Write-Output "$(Get-TimeStamp) <<Starting Group Mesage Send>> " | Out-file .\SMSlog$(Get-Date -f dd-MM-yyyy).txt -append

$AllADUsers = Get-ADGroupMember “$UserGroup” | Get-ADUser -Properties EmailAddress, GivenName, mobilePhone | ? {$_.mobilePhone -ne $null}

$SMSUsers = $AllADUsers |
Select-Object @{Label = "First Name";Expression = {$_.GivenName}},
@{Label = "Last Name";Expression = {$_.Surname}},
@{Label = "Mobile";Expression = {$_.mobilePhone}}, 
@{Label = "Account Status";Expression = {if (($_.Enabled -eq 'TRUE')  ) {'Enabled'} Else {'Disabled'}}}, # the 'if statement# replaces $_.Enabled
@{Label = "Last LogOn Date";Expression = {$_.lastlogondate}} 

#Create Text

Write-Output "$(Get-TimeStamp) <<Sending the following SMS>> " | Out-file .\SMSlog$(Get-Date -f dd-MM-yyyy).txt -append
Write-Output "$(Get-TimeStamp) $SMS" | Out-file .\SMSlog$(Get-Date -f dd-MM-yyyy).txt -append

Write-Output "$(Get-TimeStamp) <<Sending to the following users>> " | Out-file .\SMSlog$(Get-Date -f dd-MM-yyyy).txt -append
Write-Output "$(Get-TimeStamp) " $SMSUsers | Out-file .\SMSlog$(Get-Date -f dd-MM-yyyy).txt -append

Send-SMSUsers
Write-Output "$(Get-TimeStamp) <<Ending Group Mesage Send>> " | Out-file .\SMSlog$(Get-Date -f dd-MM-yyyy).txt -append 
}


Write-Output "$(Get-TimeStamp) <<Starting Run>> " | Out-file .\SMSlog$(Get-Date -f dd-MM-yyyy).txt -append

if ($args[0] -eq 'help' ) {Write-Host $xml.variables.HelpInfo ; exit }


if ($ApiKey -eq 'SetMe') {Write-Host "Please go set the API key in the Config File" ; exit }
if ($APISecret -eq 'SetMe') {Write-Host "Please go set the API Secret in the Config File" ; exit }
if ($args[2] -eq $null -and $xml.variables.SMSFrom -eq 'ChangeMe') {Write-Host "Oops you forgot to set who this is from!" ; exit }
if ($args[2] -eq $null -and $xml.variables.SMSFrom -ne 'ChangeMe') {$SMSFrom = $xml.variables.SMSFrom}


if ($args[0] -eq 'searchgroup' ) {$searchterm = Read-Host –Prompt 'Please Enter Group Search Term' ; dsquery group domainroot -name $searchterm* ; exit }
if ($args[0] -eq 'searchuser' ) {$searchterm = Read-Host –Prompt 'Please Enter User Search Term e.g. your name not user.name' ; dsquery user domainroot -name $searchterm* ; exit }
if ($args[2] -eq $null -and $xml.variables.SMSFrom -eq 'ChangeMe') {Write-Host "Oops you forgot to set who this is from!" ; exit }
if ($args[2] -eq $null -and $xml.variables.SMSFrom -ne 'ChangeMe') {$SMSFrom = $xml.variables.SMSFrom}

if ($args[0] -eq $null) {Write-Host "Oops you forgot to input the group, remember to add the ' around this. If you you help with the 
script just run the script with help at the end" ; exit }
if ($args[0] -eq 'all' -and $SMS -eq $null) {Write-Host "Oops you forgot to input your SMS!" ; exit }
if ($args[0] -eq 'all') {Write-host "Would you really like me to send an SMS to everyone I can in AD? (Default is No)" -ForegroundColor Yellow 
    $Readhost = Read-Host " ( y / n ) " 
    Switch ($ReadHost) 
     { 
       Y {Write-host "Ok, I am about to send, hold onto your seabelts" -ForegroundColor Blue; Write-Output "$(Get-TimeStamp) <<Sending the following SMS>> " | Out-file .\SMSlog$(Get-Date -f dd-MM-yyyy).txt -append
; Write-Output "$(Get-TimeStamp)   $SMS" | Out-file .\SMSlog$(Get-Date -f dd-MM-yyyy).txt -append ; Send-AllSMSUsers ; exit} 
       N {Write-Host "No, Mission Aborted!!!" -ForegroundColor Red ; exit} 
       Default {Write-Host "Default, Mission Aborted!!! You Didn't let me know!" -ForegroundColor Green ;exit} 
     }  }

if ($args[1] -eq $null) {Write-Host "Oops you forgot to input your SMS!" ; exit }


Write-Output "$(Get-TimeStamp) Running with the below varibles" | Out-file .\SMSlog$(Get-Date -f dd-MM-yyyy).txt -append
Write-Output "$(Get-TimeStamp)  $SMSFrom" | Out-file .\SMSlog$(Get-Date -f dd-MM-yyyy).txt -append
Write-Output "$(Get-TimeStamp)  $UserGroup" | Out-file .\SMSlog$(Get-Date -f dd-MM-yyyy).txt -append
Write-Output "$(Get-TimeStamp)  $args[2]" | Out-file .\SMSlog$(Get-Date -f dd-MM-yyyy).txt -append
Write-Output "$(Get-TimeStamp)  $ApiKey" | Out-file .\SMSlog$(Get-Date -f dd-MM-yyyy).txt -append
Write-Output "$(Get-TimeStamp)  $APISecret"  | Out-file .\SMSlog$(Get-Date -f dd-MM-yyyy).txt -append
Write-Output "$(Get-TimeStamp)  $ADServer" | Out-file .\SMSlog$(Get-Date -f dd-MM-yyyy).txt -append



Write-Host -ForegroundColor Green "Running with the below variables..." 
Write-Host -ForegroundColor Yellow $SMSFrom
Write-Host -ForegroundColor Yellow $UserGroup
Write-Host -ForegroundColor Yellow $args[2]
#Write-Host -ForegroundColor Yellow $ApiKey
#Write-Host -ForegroundColor Yellow $APISecret 
Write-Host -ForegroundColor Yellow $ADServer
#import the ActiveDirectory Module

Import-Module ActiveDirectory

Send-GroupSMSUsers



