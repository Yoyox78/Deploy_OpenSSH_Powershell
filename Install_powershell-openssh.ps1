# Je defini le protocole de communication en tls1.2 pour le https
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# je reset les errors
$Error.Clear()
# Je télécharge openssh
Invoke-WebRequest -URI "https://github.com/PowerShell/PowerShell/releases/download/v7.5.0/PowerShell-7.5.0-win-x64.msi" -OutFile "$env:TEMP\ServeurSSH.msi" -UseBasicParsing
msiexec.exe /package "$env:TEMP\ServeurSSH.msi" /quiet

# Si Invoke genere une erreur alors on quitte
if ($Error.count -ne 0)
{
    write-host "Problème de téléchargement du serveur ssh"
    Exit
}
# je met un sleep pour patientez le temps que le service s'active etc
sleep 15

# je reset les errors
$Error.Clear()
# Je télécharge powershell, pensez a mettre à jour les version via les nouvelle URL
Invoke-WebRequest -URI "https://github.com/PowerShell/PowerShell/releases/download/v7.5.0/PowerShell-7.5.0-win-x64.msi"  -OutFile "$env:TEMP\Powershell.msi" -UseBasicParsing

# On verifie que le fichier c'est bien dll
if ($Error.count -ne 0)
{
    write-host "Problème de téléchargement de powershell"
    Exit
}
# j'install powershell https://learn.microsoft.com/fr-fr/powershell/scripting/install/installing-powershell-on-windows?view=powershell-7.4
msiexec.exe /package "$env:TEMP\Powershell.msi" /quiet ENABLE_PSREMOTING=1 USE_MU=1 ENABLE_MU=1 ADD_PATH=1

# Je backup le fichier de conf
Copy-Item "C:\ProgramData\ssh\sshd_config" "C:\ProgramData\ssh\sshd_config.sav"


# Variable contenant le contenue du fichier sshd_config
$sshd = @'
# This is the sshd server system-wide configuration file.  See
# sshd_config(5) for more information.

# The strategy used for options in the default sshd_config shipped with
# OpenSSH is to specify options with their default value where
# possible, but leave them commented.  Uncommented options override the
# default value.

#Port 22
#AddressFamily any
#ListenAddress 0.0.0.0
#ListenAddress ::

#HostKey __PROGRAMDATA__/ssh/ssh_host_rsa_key
#HostKey __PROGRAMDATA__/ssh/ssh_host_dsa_key
#HostKey __PROGRAMDATA__/ssh/ssh_host_ecdsa_key
#HostKey __PROGRAMDATA__/ssh/ssh_host_ed25519_key

# Ciphers and keying
#RekeyLimit default none

# Logging
#SyslogFacility AUTH
#LogLevel INFO

# Authentication:

#LoginGraceTime 2m
#PermitRootLogin prohibit-password
#StrictModes yes
#MaxAuthTries 6
#MaxSessions 10

#PubkeyAuthentication yes

# The default is to check both .ssh/authorized_keys and .ssh/authorized_keys2
# but this is overridden so installations will only check .ssh/authorized_keys
AuthorizedKeysFile	.ssh/authorized_keys

#AuthorizedPrincipalsFile none

#Décommentez la ligne dessous pour authoriser un groupe ad à se connecter à la machine
#AllowGroups domain\nom-du-groupe
# attention en anglais sa sera surement administrators
AllowGroups administrateurs


# For this to work you will also need host keys in %programData%/ssh/ssh_known_hosts
#HostbasedAuthentication no
# Change to yes if you don't trust ~/.ssh/known_hosts for
# HostbasedAuthentication
#IgnoreUserKnownHosts no
# Don't read the user's ~/.rhosts and ~/.shosts files
#IgnoreRhosts yes

# To disable tunneled clear text passwords, change to no here!
#PasswordAuthentication yes
#PermitEmptyPasswords no

#AllowAgentForwarding yes
#AllowTcpForwarding yes
#GatewayPorts no
#PermitTTY yes
#PrintMotd yes
#PrintLastLog yes
#TCPKeepAlive yes
#UseLogin no
#PermitUserEnvironment no
#ClientAliveInterval 0
#ClientAliveCountMax 3
#UseDNS no
#PidFile /var/run/sshd.pid
#MaxStartups 10:30:100
#PermitTunnel no
#ChrootDirectory none
#VersionAddendum none

# no default banner path
#Banner none

# override default of no subsystems
Subsystem	sftp	sftp-server.exe
#Subsystem powershell c:/progra~1/powershell/7/pwsh.exe -sshs -nologo

# Example of overriding settings on a per-user basis
#Match User anoncvs
#	AllowTcpForwarding no
#	PermitTTY no
#	ForceCommand cvs server

# Commenter les deux lignes suivante, si vous souhaitez autoriser la connection via clé privée, sinon seul les admin auront le droit
#Match Group administrators
#    AuthorizedKeysFile __PROGRAMDATA__/ssh/administrators_authorized_keys
'@

# Je crée le fichier avec le contenue de la variable crée plus haut
set-Content -Path "C:\ProgramData\ssh\sshd_config" -value $sshd

# La commande est utilisée pour définir le type de démarrage du service SSH sur
# automatique.
set-service -name (Get-Service  |  Where-Object {$_.name -match "sshd"}).Name -startuptype automatic

# restart du service SSH sur la machine.
restart-service (Get-Service  |  Where-Object {$_.name -match "sshd"}).Name

# Crée une regle firewal, a actrivé si vous ne le faite pas via GPO
#New-NetFirewallRule -DisplayName "SSH" -Direction inbound -Profile Domain,private -Action Allow -LocalPort 22 -Protocol TCP

Remove-ItemProperty -Path "HKLM:\SOFTWARE\OpenSSH\" -Name "DefaultShell"
# Création de la clé de registre contenant le shell par defaut lors de la connexion ssh
New-ItemProperty -Force -Path "HKLM:\SOFTWARE\OpenSSH" -Name "DefaultShell" -Value "C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe" -PropertyType "String"

# Si vous n'avez pas renommé votre compte admin, enlever le deuxieme chemin ainsi que la virgule
$UserFolder = 'C:\Users\Administrateur','C:\Users\Adminrenommer'

foreach ($i in $UserFolder)
{
    if (Test-Path  $i)
    {
        if (Test-Path  "$i\.ssh")
        {
            Remove-Item -Recurse -force "$i\.ssh"
        }
        
        # Je récup le nom de l'utilisateur dans le chemin via une regex
        $user = ($i | select-string -pattern '[\w\-]+$').Matches.Value

        New-Item -Force "$i\.ssh" -itemType Directory

        # création de la clé public dans le repertoire .ssh de administrateur 
        New-Item  -Force -Path "$i\.ssh" -Name "authorized_keys" -ItemType "file" -Value "ssh-rsa ACLEPUB"
        
        # Modification des droit d ela clé ssh
        icacls.exe "$i\.ssh\authorized_keys" /setowner $user
        icacls.exe "$i\.ssh\authorized_keys" /inheritance:r /grant "SYSTEM:RX" /grant "${user}:F" 
    }
}
