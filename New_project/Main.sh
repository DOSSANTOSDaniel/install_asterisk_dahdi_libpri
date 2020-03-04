#!/bin/bash

#===============================================================================
#          FILE:  GetAsterisk16.sh
#         USAGE:  ./GetAsterisk_v1.sh
#
#   DESCRIPTION:  Script permettant d'installer Asterisk et ses modules.
#		  Permet aussi de configurer automatique des comptes SIP.
#
#       OPTIONS:  -i full     Installation d'Asterisk et des modules Dahdi et Libpri.
#                 -i dahdi    Installation d'Asterisk et du module Dahdi.
#                 -i noint    Installation d'Asterisk automatique, sans intéraction.
#                 -h          Affiche l'aide.
#                 -v          Affiche la version.
#
#  REQUIREMENTS:  ---
#          BUGS:  ---
#         NOTES:  ---
#        AUTHOR:  DOS SANTOS Daniel daniel.massy91@gmail.com
#       VERSION:  1.0
#       CREATED:  12/02/2020
#===============================================================================

### Déclaration de variables ###
declare -r User=$(w | awk '{print $1}' | awk 'NR==3')

### Variables ###
declare -r Ver='1.0'
declare -r Prog="$0"
declare SipUsers
# Asterisk
declare -r VerAst='asterisk-16.7.0'
declare -r KeyGpgAst='0x5D984BE337191CE7'
# DAHDI
declare -r VerDahdi='dahdi-linux-complete-3.1.0+3.1.0'
# Libpri
declare -r VerLibpri='libpri-1.6.0'
#Déclaration des variables de couleur
declare -r Green='\e[1;32m'
declare -r Neutral='\e[0;m'
declare -r Red='\e[0;31m'
#Récupération IP
declare -r IpCheck="$(hostname -i | awk '{print $1}')"

#Téléchargements
declare -r DownloadDahdi="https://downloads.asterisk.org/pub/telephony/dahdi-linux-complete/releases/"
declare -r DownloadLibpri="https://downloads.asterisk.org/pub/telephony/libpri/releases/"
declare -r DownloadAsterisk="http://downloads.asterisk.org/pub/telephony/asterisk/releases/"

### Déclaration des fonctions ###

usage() {
    cat <<USAGE
	Usage: ${prog} -option [arg] 
	Option 1:   -i     Types d'installation.
	Option 2:   -v     Version.
	Option 3:   -h     Aide.
	
	Argument 1:	[full]		Installation de Dahdi et Libpri.
	Argument 2:	[dahdi]		Installation de Dahdi.
	
	Argument 3:	[noint]		Installation d'asterisk non intéractive.
					La configuration des utilisateurs ne sera pas demmandé.

	Exemples:
	${prog}  -i full	
	${prog}  -i dahdi
	${prog}  -i noint
	${prog}			Installation d'Asterisk sans les modules Dahdi et Libpri.
	${prog}  -v
	${prog}  -h		
USAGE
}

version() {
cat <<Ver
  
	Script: ${0} Version: [${ver}]

Ver
}

Interface() {

declare -i imi=0
declare -i choix=0
declare -i exitstatus=0
declare -a tab
declare -i Exten=1000

while [ : ]
do
  if (whiptail --title "Boite de dialogue Oui / Non" --yesno "Voulez-vous ajouter des utilisateurs ?" 10 60)
  then
    Name=$(whiptail --title "Creation des comptes SIP" --inputbox "Entrer le nom utilisateur" 10 60 Daniel 3>&1 1>&2 2>&3)
    exitstatus="${?}"
  
    if [ "${exitstatus}" = 0 ]
    then
        choix="${choix}+1"
    else
        whiptail --title "Creation des comptes SIP" --msgbox "Vous avez annulez" 10 60
        unset ${tab[$imi]}
        continue
    fi
    Password=$(whiptail --title "Creation des comptes SIP" --passwordbox "Entrer le mot de passe utilisateur" 10 60 password 3>&1 1>&2 2>&3)
    exitstatus="${?}"
    if [ "${exitstatus}" = 0 ]
    then
        choix="${choix}+1"
    else
        whiptail --title "Creation des comptes SIP" --msgbox "Vous avez annulez" 10 60
        unset ${tab["$imi"]}
        continue
    fi
    
    if (whiptail --title "Creation des comptes SIP" --yesno "Verification: Nom:$Name / Extetion:$Exten / Password:$Password" 20 70 3>&1 1>&2 2>&3)
    then
      if(whiptail --title "Creation des comptes SIP" --yesno "Sauvegarder l'utilisateur: ${Name} ?" 10 60)
      then
        whiptail --title "Compte SIP" --msgbox "Extension pour l'utilisateur ${Name} : ${Exten}" 10 60
        tab["${imi}"]="${Name},${Exten},${Password}"
        Exten=${Exten}+1
        imi="$imi+1"
      else
	continue
      fi        
    else
      whiptail --title "Creation des comptes SIP" --msgbox "Ajout des comptes terminé, Demarrage de l'installation!" 10 60
      break
      unset ${tab[${imi}]}
    fi
  else
    whiptail --title "Asterisl Install" --msgbox "Demarrage de l'installation!" 10 60
    break
  fi
done
SipUsers=$(echo "${tab[@]}")
}

FailMes() {
  echo -e "\n ${Red} ### ${1} ### ${Neutral} \n"
}

InfoMes() {
  echo -e "\n ${Green} ### ${1} ### ${Neutral} \n"
}

# Quand il y un exit, on efface les ressources que nous avons utilisées 
Finish() {
  for ErrExit in 'tar.gz.asc' 'sha256' 'tar.gz'
  do
    rm -rf "/usr/local/src/${VerAst}.${ErrExit}"
  done
}

ExistInstall() {
	Inx="$(dpkg -s ${1} | grep Status | awk '{print $2}')"

	if [ "${Inx}" == "install" ]
	then
		FailMes "Attention ${1} est déjà installé"
    exit 9
	else 
    type -a "${1}"
    if [ "${?}" == "0" ]
	  then
		  FailMes "Attention ${1} est déjà installé"
      exit 9
	  else
      test -d "/usr/local/src/${VerAst}"
      if [ "${?}" == "0" ]
	    then
		    FailMes "Attention ${1} est déjà présent sur /usr/local/src/${VerAst}"
        exit 9
	    else
		    InfoMes "Ok ${1} n'est pas installé sur cette machine !"
      fi
    fi    
	fi
}

DownloadFile() {

  for FileEx in 'tar.gz.asc' 'sha256' 'tar.gz'
  do
    wget -c -t 3 --progress=bar -O "/usr/local/src/${VerAst}.${FileEx}" "http://downloads.asterisk.org/pub/telephony/asterisk/releases/${VerAst}.${FileEx}" && sleep 1
    if [ ${?} == 0 ]
    then
        InfoMes "Le téléchargement du fichier ${VerAst}.${FileEx} est terminé !"
    else
        FailMes "Erreur de téléchargement du fichier ${VerAst}.${FileEx} !"
        exit 0
    fi
  done
}

TestAuthen() {
  InfoMes "Test sha256sum :"
  cd /usr/local/src/
  sha256sum -c "/usr/local/src/${VerAst}.sha256"
  if [ ${?} == 0 ]
  then
    InfoMes "vérification de la somme de contrôle SHA256 OK !"
  else
    FailMes "Erreur sur la vérification de la somme de contrôle SHA256 du fichier ${VerAst}.tar.gz !"
    exit 1
  fi
  InfoMes "Test GPG :"
  gpg2 --keyserver 'hkp://keyserver.ubuntu.com' --recv-keys "${KeyGpgAst}"
  gpg2 --verify "/usr/local/src/${VerAst}.tar.gz.asc" "/usr/local/src/${VerAst}.tar.gz"
  if [ ${?} == 0 ]
  then
    InfoMes "vérification de la clé GPG OK !"
  else
    FailMes "Erreur de vérification de la clé GPG du fichier ${VerAst}.tar.gz !"
    exit 2
  fi
}

ExtractFile() {
  tar xzvf "/usr/local/src/${VerAst}.tar.gz"
  if [ ${?} == 0 ]
  then
    InfoMes "Décompression OK !"
  else
    FailMes "Erreur de décompression du fichier ${VerAst}.tar.gz !"
    exit 3
  fi
}

#Fonction permettant d'afficher un message, usage: MesInfo [couleur] [message]
MesInfo() {
echo -e "\n $orange ------------------------------------------------------- $neutral \n"
echo -e " $1           $2           $neutral "
echo -e "\n $orange ------------------------------------------------------- $neutral \n"
logger -t "${0}" "${2}"
}

# Quand il y un exit, on efface les ressources que nous avons utilisées 
Finish() {
# Efface les traces de l'installation d'Asterisk
  for Err in 'tar.gz.asc' 'sha256' 'tar.gz'
  do
    rm -rf "/usr/local/src/${VerAst}.${Err}"
  done
  cd /usr/local/src/${VerAst}
  if $(make uninstall)
  then
    make uninstall-all
  else
    rm -rf /usr/local/src/${VerAst}
  fi
  
# Efface les traces de l'installation de DAHDI 
  for Err in 'sha1' 'tar.gz'
  do
    rm -rf "/usr/local/src/${VerDahdi}.${Err}"
  done
  cd /usr/local/src/${VerDahdi}
  if $(make uninstall)
  then
    MesInfo $green 'Dahdi désinstalé!'
  else
    find / | grep dahdi > results
    xargs rm -R < results
  fi
  rm -rf /usr/local/src/${VerDahdi}
  
# Efface les traces de l'installation de Libpri 
  for Err in 'sha256' 'tar.gz'
  do
    rm -rf "/usr/local/src/${VerLibpri}.${Err}"
  done
  cd /usr/local/src/${VerLibpri}
  if $(make uninstall)
  then
    MesInfo $green 'Libpri désinstalé!'
  else
    find / | grep libpri > results
    xargs rm -R < results
  fi
  rm -rf /usr/local/src/${VerLibpri}
  
  # Désinstallation d'applications
  apt remove whiptail --purge
}

ExistInstall() {
  Inx="$(dpkg -s ${1} | grep Status | awk '{print $2}')"
  if [ "${Inx}" == "install" ]
  then
    MesInfo $red "Attention ${1} est déjà installé"
    exit 1
  else 
    type -a "${1}"
    if [ "${?}" == "0" ]
    then
      MesInfo $red "Attention ${1} est déjà installé"
      exit 1
    else
      test -d "/usr/local/src/${VerAst}"
      if [ "${?}" == "0" ]
      then
        MesInfo $red "Attention ${1} est déjà présent sur /usr/local/src/"
        exit 1
      else
        MesInfo $green "Ok ${1} n'est pas installé sur cette machine !"
      fi
    fi      
  fi
}

InstallAst() {
  set -e

CountryCode="33"

apt update && apt full-upgrade -y
apt install wget -y
apt install gpg -y
apt install vim -y
apt install dialog -y
apt install apt-utils -y
apt install systemd -y
apt install ufw -y
ufw enable
ufw status

wget https://downloads.asterisk.org/pub/telephony/asterisk/releases/asterisk-16.7.0.tar.gz -O /usr/local/src/asterisk-16.7.0.tar.gz
wget https://downloads.asterisk.org/pub/telephony/asterisk/releases/asterisk-16.7.0.sha256 -O /usr/local/src/asterisk-16.7.0.sha256
wget https://downloads.asterisk.org/pub/telephony/asterisk/releases/asterisk-16.7.0.tar.gz.asc -O /usr/local/src/asterisk-16.7.0.tar.gz.asc

cd /usr/local/src/
sha256sum -c /usr/local/src/asterisk-16.7.0.sha256
gpg --keyserver 'hkp://keyserver.ubuntu.com' --recv-keys '5D984BE337191CE7'
gpg --verify /usr/local/src/asterisk-16.7.0.tar.gz.asc /usr/local/src/asterisk-16.7.0.tar.gz

tar xzvf /usr/local/src/asterisk-16.7.0.tar.gz
echo "libvpb1 libvpb1/countrycode select $CountryCode" | debconf-set-selections
yes | bash /usr/local/src/asterisk-16.7.0/contrib/scripts/install_prereq install
cd /usr/local/src/asterisk-16.7.0/
./configure

make menuselect.makeopts
/usr/local/src/asterisk-16.7.0/menuselect/menuselect --enable-category MENUSELECT_ADDONS menuselect.makeopts
/usr/local/src/asterisk-16.7.0/menuselect/menuselect --disable CORE-SOUNDS-EN-GSM menuselect.makeopts
/usr/local/src/asterisk-16.7.0/menuselect/menuselect --enable CORE-SOUNDS-FR-WAV menuselect.makeopts
/usr/local/src/asterisk-16.7.0/menuselect/menuselect --enable CORE-SOUNDS-FR-ULAW menuselect.makeopts
/usr/local/src/asterisk-16.7.0/menuselect/menuselect --enable CORE-SOUNDS-FR-ALAW menuselect.makeopts
/usr/local/src/asterisk-16.7.0/menuselect/menuselect --enable MOH-OPSOUND-ULAW menuselect.makeopts
/usr/local/src/asterisk-16.7.0/menuselect/menuselect --enable MOH-OPSOUND-ALAW menuselect.makeopts 
/usr/local/src/asterisk-16.7.0/menuselect/menuselect --enable EXTRA-SOUNDS-FR-WAV menuselect.makeopts
/usr/local/src/asterisk-16.7.0/menuselect/menuselect --enable EXTRA-SOUNDS-FR-ULAW menuselect.makeopts
/usr/local/src/asterisk-16.7.0/menuselect/menuselect --enable EXTRA-SOUNDS-FR-ALAW menuselect.makeopts

contrib/scripts/get_mp3_source.sh
make
make install
make samples
make config
ldconfig

groupadd asterisk
useradd -r -d /var/lib/asterisk -g asterisk asterisk
usermod -aG audio,dialout asterisk
chown -R asterisk.asterisk /etc/asterisk
chown -R asterisk.asterisk /var/{lib,log,spool}/asterisk
chown -R asterisk.asterisk /usr/lib/asterisk

#Créer une sauvegarde des fichiers de configurations
cp /etc/asterisk/sip.conf /etc/asterisk/sip.conf.back
cp /etc/asterisk/users.conf /etc/asterisk/users.conf.back
cp /etc/asterisk/extensions.conf /etc/asterisk/extensions.conf.back
cp /etc/asterisk/voicemail.conf /etc/asterisk/voicemail.conf.back 

sed -i -e 's/^#AST_USER="asterisk"/AST_USER="asterisk"/g' /etc/default/asterisk
sed -i -e 's/^#AST_GROUP="asterisk"/AST_GROUP="asterisk"/g' /etc/default/asterisk

sed -i -e 's/^;runuser = asterisk/runuser = asterisk/g' /etc/asterisk/asterisk.conf
sed -i -e 's/^;rungroup = asterisk/rungroup = asterisk/g' /etc/asterisk/asterisk.conf

sed -i -e 's/^;languageprefix = yes/languageprefix = yes/g' /etc/asterisk/asterisk.conf

sed -i -e 's/^;defaultlanguage = en/defaultlanguage = fr/g' /etc/asterisk/asterisk.conf
sed -i -e 's/^documentation_language = en_US/documentation_language = fr_FR/g' /etc/asterisk/asterisk.conf

sed -i -e 's/^;language=en/language=fr/g' /etc/asterisk/sip.conf
sed -i -e 's/^;tonezone=se/tonezone=fr/g' /etc/asterisk/sip.conf

sed -i -e 's/^enabled = yes/enabled = no/g' /etc/asterisk/ari.conf

/etc/init.d/asterisk start

systemctl enable asterisk

ufw allow proto tcp from any to any port 5060,5061

/etc/init.d/asterisk status
}

InstallDahdi() {
  set -e
apt-get install linux-headers-$(uname -r)
wget https://downloads.asterisk.org/pub/telephony/dahdi-linux-complete/releases/dahdi-linux-complete-3.1.0+3.1.0.tar.gz -O /usr/local/src/dahdi-linux-complete-3.1.0+3.1.0.tar.gz
wget https://downloads.asterisk.org/pub/telephony/dahdi-linux-complete/releases/dahdi-linux-complete-3.1.0+3.1.0.tar.gz.sha1 -O /usr/local/src/dahdi-linux-complete-3.1.0+3.1.0.tar.gz.sha1

cd /usr/local/src/
sha1sum -c dahdi-linux-complete-3.1.0+3.1.0.tar.gz.sha1 >> info.txt

tar xzvf /usr/local/src/dahdi-linux-complete-3.1.0+3.1.0.tar.gz
cd /usr/local/src/dahdi-linux-complete-3.1.0+3.1.0/ 
make
make install
make config

lsmod | grep dahdi

/etc/init.d/dadhi start

/etc/init.d/asterisk status
}

InstallLibpri() {
  set -e

wget https://downloads.asterisk.org/pub/telephony/libpri/releases/libpri-1.6.0.sha256 -O /usr/local/src/libpri-1.6.0.sha256
wget https://downloads.asterisk.org/pub/telephony/libpri/releases/libpri-1.6.0.tar.gz -O /usr/local/src/libpri-1.6.0.tar.gz

cd /usr/local/src/
sha256sum -c libpri-1.6.0.sha256

tar xzvf /usr/local/src/libpri-1.6.0.tar.gz

cd /usr/local/src/libpri-1.6.0
make
make install
}

DownloadFile() {

  for FileEx in 'tar.gz.asc' 'sha256' 'tar.gz'
  do
    wget -c -t 3 --progress=bar -O "/usr/local/src/${VerAst}.${FileEx}" "http://downloads.asterisk.org/pub/telephony/asterisk/releases/${VerAst}.${FileEx}" && sleep 1
    if [ ${?} == 0 ]
    then
        InfoMes "Le téléchargement du fichier ${VerAst}.${FileEx} est terminé !"
    else
        FailMes "Erreur de téléchargement du fichier ${VerAst}.${FileEx} !"
        exit 0
    fi
  done
}

TestAuthen() {
  InfoMes "Test sha256sum :"
  cd /usr/local/src/
  sha256sum -c "/usr/local/src/${VerAst}.sha256"
  if [ ${?} == 0 ]
  then
    InfoMes "vérification de la somme de contrôle SHA256 OK !"
  else
    FailMes "Erreur sur la vérification de la somme de contrôle SHA256 du fichier ${VerAst}.tar.gz !"
    exit 1
  fi
  InfoMes "Test GPG :"
  gpg2 --keyserver 'hkp://keyserver.ubuntu.com' --recv-keys "${KeyGpgAst}"
  gpg2 --verify "/usr/local/src/${VerAst}.tar.gz.asc" "/usr/local/src/${VerAst}.tar.gz"
  if [ ${?} == 0 ]
  then
    InfoMes "vérification de la clé GPG OK !"
  else
    FailMes "Erreur de vérification de la clé GPG du fichier ${VerAst}.tar.gz !"
    exit 2
  fi
}

ExtractFile() {
  tar xzvf "/usr/local/src/${VerAst}.tar.gz"
  if [ ${?} == 0 ]
  then
    InfoMes "Décompression OK !"
  else
    FailMes "Erreur de décompression du fichier ${VerAst}.tar.gz !"
    exit 3
  fi
}

### Fonctions ###
FailMes() {
  echo -e "\n ${Red} ### ${1} ### ${Neutral} \n"
}

InfoMes() {
  echo -e "\n ${Green} ### ${1} ### ${Neutral} \n"
}

DownloadFile() {
for Tools in "${VerAsterisk}" "${VerLibpri}"
do
  for Ext in 'tar.gz.asc' 'sha256' 'tar.gz'
  do
    wget -c -t 3 --progress=bar -O "/usr/local/src/${Tools}.${Ext}" "${DownloadAsterisk}/${Tools}.${Ext}" && sleep 1
  done
done
}

### Code ###
clear

echo -e "\n ${Orange} ####################################################### ${Neutral} \n"
echo -e " ${Blue}     Installation et configuration d'Asterisk 16        ${Neutral} "
echo -e "\n ${Orange} ####################################################### ${Neutral} \n"
sleep 3

ExistInstall 'asterisk'

# vérifier utilisateur
if [[ $USER != "root" ]]
then 
  echo 'Attention ce script doit être démarré en root' 
  exit 1
fi 

# Installations d'applications
apt install whiptail -y
apt install sudo -y
apt install ufw -y
apt install fail2ban -y
apt install molly-guard -y
apt install rkhunter -y

# Récupération des options utilisateur
if (( $# > 2 ))
then
  echo "trop d'arguments !"
  exit 1
elif [[ $1 =~ ^[^-.] ]]
then
  echo "$1 n'est pas un option! "
fi
 
while getopts ":i: :h :v" opt
do
  case $opt in
    i)
      case $OPTARG in
	full)
		echo "Install tout"
	;;
        dahdi)
		echo "Install dahdi"
	;;
        noint)
		echo "Install non interact"
	;;
	*)
		echo "erreur d'arguments: $OPTARG"
		exit 1
	;;
      esac 
      ;;
    h)
      echo "-h aide aux commandes!" >&2
      ;;
    v)
      echo "-v version du script" >&2
      ;;
    \?)
      echo "Cette option est invalide: $OPTARG" >&2
      exit 1
      ;;
    :)
      echo "L'option $OPTARG nécessite un argument." >&2
      exit 1
      ;;
  esac
done

### Sécurisation ###
# ajout de l'utilisateur loggé au groupe sudo
usermod -aG sudo "$User"

# configuration de ufw 
ufw status
ufw enable
ufw status
ufw default deny incoming
ufw default allow outgoing
ufw allow ssh/tcp
ufw allow proto tcp from any to any port 5060,5061
ufw status verbose

# Configuration de Fail2ban
echo "
# ne pas éditer /etc/fail2ban/jail.conf
[DEFAULT]
destemail = root@gmail.com
sender = root@example.lan
ignoreip = 127.0.0.1/8 $ipnet $ipwifi
[sshd]
enabled = true
port = 22
maxretry = 10
findtime = 120
bantime = 1200
logpath = /var/log/auth.log
[sshd-ddos]
enabled = true
[recidive]
enabled = true
" > /etc/fail2ban/jail.d/defaults-debian.conf
sleep 1
systemctl restart fail2ban







# Effacer les traces
trap Finish EXIT
