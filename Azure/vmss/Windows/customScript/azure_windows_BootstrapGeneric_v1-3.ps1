# Suhail Choudhury (chouds27) 08/11/2017
# v1-3 - enabled the AD DNS name change
#Set-ExecutionPolicy Unrestricted

Param(
  [parameter(Mandatory=$true,Position=1)] 
  [string]$pp_region,
  [parameter(Mandatory=$true,Position=2)] 
  [string]$pp_environment,
  [parameter(Mandatory=$true,Position=3)] 
  [string]$pp_role,
  [parameter(Mandatory=$true,Position=4)] 
  [string]$diskmounts,
  [string]$vmss = ""
)

$computerName = $env:computername
$computerName = $computerName.ToLower()
$logfile = "C:\ProvisioningLogs\bootstrap.log"
$DNSServer = "10.64.192.4"
$DNSSuffix = "azure.uk.centricaplc.com"
$suffix1 = "azure.uk.centricaplc.com"
$suffix2 = "uk.centricaplc.com"
$suffix3 = "aws.uk.centricaplc.com"
$proxy_host = "10.65.192.4"
$proxy_port = "8080"
$puppet_logfile = "C:\ProvisioningLogs\puppet_install_run.log"
$puppetmasterserver = "puppet.aws.uk.centricaplc.com"
$puppet_certname = $computerName
$puppetCertificateLocation = "c:\ProgramData\PuppetLabs\puppet\etc\"
$puppet_agent_url = "https://downloads.puppetlabs.com/windows/puppet-agent-1.6.1-x64.msi" 
$puppet_agent_location = "C:\Windows\Temp\puppet-agent-1.6.1-x64.msi" 

# Logging install process
md C:\ProvisioningLogs
Start-Transcript -Path $logfile 

# Update AD DNS Name
$ad_username = "zz_awcoreauto@uk.centricaplc.com"
$ad_password = "KXRgQXpX@#vr2lZO2O"
$secureStringPwd = ($ad_password | ConvertTo-SecureString -AsPlainText -Force)
$creds = (New-Object System.Management.Automation.PSCredential -ArgumentList $ad_username, $secureStringPwd)
$ad_command = (Set-ADComputer -Identity $computerName -DNSHostName "$computerName.$DNSSuffix" -Credential $creds)
$ad_command

# Set Time Zone to Europe\London
tzutil /s "GMT Standard Time"

# Update primary DNS Suffix for FQDN
Set-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\" -Name Domain -Value $DNSSuffix
Set-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\" -Name "NV Domain" -Value $DNSSuffix

# Set DNS Connection specific suffix and set dynamic DNS registration
#Set-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\" -Name SearchList -Value $suffix1

# Register A record on DNS
$networkConfig = Get-WmiObject Win32_NetworkAdapterConfiguration -filter "ipenabled = 'true'"
$networkConfig.SetDnsDomain("azure.uk.centricaplc.com")
$networkConfig.SetDynamicDNSRegistration($true,$true)
ipconfig /RegisterDns

# Set proxy settings
Set-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings" -Name ProxyEnable -Value 1
Set-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings" -Name ProxyServer -Value $proxy_host":"$proxy_port
Set-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings" -Name ProxyOverride -Value ".centricaplc.com, 10.60.192.231, localhost, 169.254.169.254"

# Install Root Certificate
#Import-Certificate -Filepath "<full path to certificate, maybe in storage account??>" -CertStoreLocation "Root"

# Get UUID
#$computerSystemProduct = Get-WmiObject -class Win32_ComputerSystemProduct -namespace root\CIMV2
#UUID = $computerSystemProduct.UUID

# Format and Drive Letters
Out-File -filepath "C:\ProvisioningLogs\windows_drives.txt" -encoding UTF8 -inputobject $diskmounts

$a = Get-Content C:\ProvisioningLogs\windows_drives.txt
$a -replace '"',"" | Out-File C:\ProvisioningLogs\out1.txt
$b = Get-Content C:\ProvisioningLogs\out1.txt
$b -replace ',',"`n" | Out-File C:\ProvisioningLogs\out2.txt
$c = Get-Content C:\ProvisioningLogs\out2.txt
$d = Select-String 'lun0' C:\ProvisioningLogs\out2.txt -notmatch | % {$_.Line} | Out-File C:\ProvisioningLogs\out3.txt
$d = Select-String 'lun1' C:\ProvisioningLogs\out3.txt -notmatch | % {$_.Line} | Out-File C:\ProvisioningLogs\out4.txt
$e = Select-String 'lun2' C:\ProvisioningLogs\out4.txt -notmatch | % {$_.Line} | Out-File C:\ProvisioningLogs\out5.txt
$f = Get-Content C:\ProvisioningLogs\out5.txt
$g = $f -replace "lun", "" | Out-File C:\ProvisioningLogs\windows_drives_by_line.txt

$output = 
foreach($line in Get-Content  C:\ProvisioningLogs\windows_drives_by_line.txt)
{
 $disk = $line | %{ $_.Split(':')[0]; }
 $letter = $line | %{ $_.Split(':')[1]; }
 $label = $line | %{ $_.Split(':')[2]; }
 "Initialize-Disk -Number $disk; New-Partition -DiskNumber $disk -UseMaximumSize -DriveLetter $letter; Format-Volume -DriveLetter $letter -FileSystem NTFS -NewFileSystemLabel `"$label`" -Confirm:`$false"
}

$output | Out-File C:\ProvisioningLogs\format.ps1
C:\ProvisioningLogs\format.ps1

# Puppet certificate
  $CSR_ATTRIBUTES = @"
extension_requests:
  pp_instance_id: $puppet_certname
  pp_image_name: MicrosoftWindowsServer:WindowsServer:2012-R2-Datacenter:latest
  pp_preshared_key: 88d35a1a1fb2ba59ea57b056993f3552
  pp_hostname: $puppet_certname
  pp_cloudplatform: azure
  pp_region : $pp_region
  pp_environment : $pp_environment
  pp_role: $pp_role
"@

New-Item $puppetCertificateLocation -itemtype directory -force
Out-File -filepath "c:\ProgramData\PuppetLabs\puppet\etc\csr_attributes.yaml" -encoding UTF8 -inputobject $CSR_ATTRIBUTES

# Remove signing request file
#Remove-Item -Path $puppetCertificateLocation -Force

# Download Latest Version of Puppet Agent
#Invoke-WebRequest -Uri $puppet_agent_url -OutFile $puppet_agent_location
$wc = New-Object System.Net.WebClient
$wp = New-Object System.Net.WebProxy("$proxy_host",$proxy_port)
$wc.Proxy = $wp
$wc.DownloadFile($puppet_agent_url, $puppet_agent_location)

# Install Puppet Agent
Start-Process -FilePath "msiexec" -ArgumentList "/qn /L*V $puppet_logfile ALLUSERS=1 /norestart /i $puppet_agent_location PUPPET_MASTER_SERVER=$puppetmasterserver PUPPET_AGENT_CERTNAME=$puppet_certname" -wait
Start-Sleep -s 30

# Run Puppet Agent
#start /B "puppet agent -t"

# Install software so we can update AD DNSHostname attribute
Add-WindowsFeature RSAT-AD-PowerShell

#gpupdate /force

$onlyScriptURI = $vmss.Split(" ")[0]
$onlyFileName = $onlyScriptURI.Split("\/")[-1]
$localScriptLocation = "C:\Windows\Temp\" + $onlyFileName

Invoke-WebRequest -Uri $onlyScriptURI -OutFile $localScriptLocation
Invoke-Expression $localScriptLocation $vmss.Split(" ")[1..($vmss.Split(" ").Length)]

# Restart server and exit
shutdown /r /t 30
Exit
