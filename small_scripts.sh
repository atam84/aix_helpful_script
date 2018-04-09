# ALIAS
alias lls='/usr/linux/bin/ls -F --color=auto'
alias ldf='/usr/linux/bin/df -lh'
or
alias lls='/opt/freeware/bin/ls -F --color=auto'
alias ldf='/opt/freeware/bin/df -lh'
# Terminal Color
## Reset to normal: \033[0m
NORM="\033[0m"
## Colors:
BLACK="\033[0;30m"
GRAY="\033[1;30m"
RED="\033[0;31m"
LRED="\033[1;31m"
GREEN="\033[0;32m"
LGREEN="\033[1;32m"
YELLOW="\033[0;33m"
LYELLOW="\033[1;33m"
BLUE="\033[0;34m"
LBLUE="\033[1;34m"
PURPLE="\033[0;35m"
PINK="\033[1;35m"
CYAN="\033[0;36m"
LCYAN="\033[1;36m"
LGRAY="\033[0;37m"
WHITE="\033[1;37m"
echo "\033[0;32mtest\033[0m"
## Backgrounds
BLACKB="\033[0;40m"
REDB="\033[0;41m"
GREENB="\033[0;42m"
YELLOWB="\033[0;43m"
BLUEB="\033[0;44m"
PURPLEB="\033[0;45m"
CYANB="\033[0;46m"
GREYB="\033[0;47m"
## Attributes:
UNDERLINE="\033[4m"
BOLD="\033[1m"
INVERT="\033[7m"
## Cursor movements
CUR_UP="\033[1A"
CUR_DN="\033[1B"
CUR_LEFT="\033[1D"
CUR_RIGHT="\033[1C"
## Start of display (top left)
SOD="\033[1;1f"
#########
# du -gs with color
function ndf {
	df -gs | awk '{
		if (NR == 1) {
			print "\033[0;36m"$0"\033[0m";
		} else {
			gsub("%", "", $4);
			if ($4 ~ /[0-9]/) {
				if ($4 < 80) {
					printf "%-22s %10s %10s %5s%% %10s %5s %-6s\n", $1, $2, $3, $4, $5, $6, $7;
				} else if ($4 >= 80 && $4 < 90) {
					printf "\033[0;33m%-22s %10s %10s %5s%% %10s %5s %-4s\n\033[0m", $1, $2, $3, $4, $5, $6, $7;;
				} else if ($4 >= 90) {
					printf "\033[0;31m%-22s %10s %10s %5s%% %10s %5s %-4s\n\033[0m", $1, $2, $3, $4, $5, $6, $7;;
				}
			} else {
				printf "%-22s %10s %10s %5s %10s %5s  %-4s\n", $1, $2, $3, $4, $5, $6, $7;
			}
		}
	}'
}
#
#
#= List all path
for disk in `lspath | awk '{print $2}' | sort -u`; do echo "HDisk: ${disk} "
	for vCARDS in `lspath | awk '{print $3}' | sort -u`; do
		PATH_STATUS=`lspath -l ${disk} | grep ${vCARDS} | awk 'BEGIN {U=0;F=0;T=0;} $1 ~ /Enabled/ {U++} $1 !~ /Enabled/ {F++} END{print U"/"U+F" Enabled paths\n"}'`
		echo ' `--> '${vCARDS}' - '${PATH_STATUS}
		lspath -l ${disk} -F "status:connection:path_id:parent" | grep ${vCARDS} | awk -F: '{print "   `-----> "$1 "  ("$2")"}'
	done
	echo "";
done
#= List quickly enabled path
for disk in `lspath | awk '{print $2}' | sort -u`; do echo "HDisk: ${disk} "
	for vCARDS in `lspath | awk '{print $3}' | sort -u`; do
		PATH_STATUS=`lspath -l ${disk} | grep ${vCARDS} | awk 'BEGIN {U=0;F=0;T=0;} $1 ~ /Enabled/ {U++} $1 !~ /Enabled/ {F++} END{print U"/"U+F" Enabled paths\n"}'`
		echo ' `--> '${vCARDS}' - '${PATH_STATUS}
	done
	echo "";
done
#= List relation between fcs and fscsi
for vCard in `lspath | awk '{print $3}' | sort -u`; do
	set -A vCard_Str `lscfg -vl ${vCard} | awk '{print $1" "$2}'`
	for FC in `lsdev -Cc adapter | awk '$1 ~ /^fc/ && $2 ~ /Available/ {print $1}'`; do
		set -A FC_Str `lscfg -vl $FC | awk '$1 ~ /fcs/ {print $0}'`
		if [[ ${FC_Str[1]} = ${vCard_Str[1]} ]]; then
			WWN=`lscfg -vl ${FC_Str[0]} | grep Network | awk -F. '{print $NF}' | sed 's/.\{2\}/&:/g' | tr '[:upper:]' '[:lower:]'`
			echo "${vCard_Str[0]} <===> ${FC_Str[0]}  [WWN: ${WWN%:}]"
		fi
	done
done
#= List HBA Hw location and WWN
for FC in `lsdev -Cc adapter | awk '$1 ~ /^fc/ && $2 ~ /Available/ {print $1}'`; do
	set -A FC_Str `lscfg -vl $FC | awk '$1 ~ /fcs/ {print $0}'`;
	WWN=`lscfg -vl ${FC_Str[0]} | grep Network | awk -F. '{print $NF}' | sed 's/.\{2\}/&:/g' | tr '[:upper:]' '[:lower:]'`
	echo "${FC_Str[0]}  [Hw: ${FC_Str[1]}] [WWN: ${WWN%:}]"
done
####= NEW VERSION
for FC in `lsdev -Cc adapter | awk '$1 ~ /^fc/ && $2 ~ /Available/ {print $1}'`; do
	lscfg -vl ${FC} | awk '$1 ~ /fcs/ {printf $1"  [HW Addr: "$2"] "} $1 ~ /Network/ && $2 ~ /Address/ {FS=".";gsub("..", "&:", $NF);gsub(":$", "", $NF);print tolower($NF);}'
done


#= Remove failed path
lspath -s failed -F "name connection parent status" | grep -i failed | while read hdisk connection parent status; do
	rmpath -l $hdisk -p $parent -w $connection -d
done

#
#
#
#
#= List VG and PV
for VG in `lsvg`; do lsvg -p $VG | egrep -v ^PV_NAME; echo ""; done
#= List VG and PV
for VG in `lsvg`; do echo $VG; lsvg -p $VG | egrep -v "^PV_NAME|^$VG" | while read line; do echo '  `--> '$line; done; echo ""; done
#= List VG, PV and FS
for VG in `lsvg`; do
echo $VG
echo '  |'
lsvg -p $VG | egrep -v "^PV_NAME|^$VG" | while read line; do
	echo $line | awk '{printf "  `--> %-9s %-10s %-7s %-7s\n",$1,$2,$3,$4}'
	done
echo '    |'
lsvg -l $VG | egrep -v "^LV NAME|^$VG" | while read line; do
	echo $line | awk '{printf "    `--> %-12s %-7s %-7s %-7s %-15s %s\n",$1,$2,$3,$4,$6,$7}'
	done
echo ""
done
#= same but in megabite
for VG in `lsvg`; do
echo $VG
pp_size=`lsvg rootvg | grep "PP SIZE" | awk '{printf "%s", $(NF-1)}'`
echo '  |'
lsvg -p $VG | egrep -v "^PV_NAME|^$VG" | while read line; do
	echo $line | awk -v p="${pp_size}" '{printf "  `--> %-9s %-10s %-7.2f %-7.2f\n",$1,$2,($3*p)/1024,($4*p)/1024}'
	done
echo '    |'
lsvg -l $VG | egrep -v "^LV NAME|^$VG" | while read line; do
	echo $line | awk -v p="${pp_size}" '{printf "    `--> %-12s %-7s %-7s %-7s %-15s %s\n",$1,$2,$3*p,$4*p,$6,$7}'
	done
echo ""
done
#= LIST VG WITH GB SIZE AND SOME INFORMATIONs
for VG in `lsvg`; do
	lsvg $VG | awk -v vg=${VG} 'BEGIN{pp_size=0;size=0;used=0;free=0;lvs=0;state=unkwone; id=unkwone}
	$4 ~ /VG/ && $5 ~ /IDENTIFIER/ {id=$6}
	$1 ~ /VG/ && $2 ~ /STATE/ {state=$3}
	$4 ~ /PP/ && $5 ~ /SIZE/ {pp_size=$6}
	$4 ~ /TOTAL/ && $5 ~ /PPs/ {size=$6}
	$4 ~ /FREE/ && $5 ~ /PPs/ {free=$6}
	$3 ~ /USED/ && $4 ~ /PPs/ {used=$5}
	$1 ~ /LVs/ {lvs=$2}
	END {printf "%-10s SIZE: %7.2fg  USED: %7.2fg (%6.2f%%)  FREE: %5.2fg  LVs: %-3s ST: %-10s ID: %s\n", vg, (size*pp_size)/1024, (used*pp_size)/1024, (used*100)/size, (free*pp_size)/1024, lvs, state, id}'
done
#= DISPLAY INTERFACE NAME , IP ADDRESS AND MAC ADDRESS
\033[0;33m yellow
\033[0m  normal
\033[0;32m green
\033[0;36m CYAN
\033[1;37m WHITE
function _network_info {
	uname -n | awk '{printf "\033[0;32m%s\033[0m\n", $0}'
	for eth in `lsdev -Cc if | grep Available | grep -v 'lo0' | awk '{print $1}'`; do
		lsattr -El ${eth} | egrep -w 'netaddr' | awk -v eth=${eth} '{printf "\033[0;36m%s\033[0m: %s ", eth, $2}'
		entstat -d ${eth} | grep "Hardware Address" | awk 'BEGIN {printf "\033[0;36m[ \033[0m";} {printf "%s ", $3;} END {printf "\033[0;36m]\033[0m\n"}'
	done
	printf "\n\033[0;33mEtherChannel devices: \033[0m"
	lsdev -Cc adapter | grep ^en | grep Available | awk 'BEGIN{printf "[";}$0 ~ /EtherChannel/ {printf "%s ", $1} END {printf "]\n"}'
	for ent in `lsdev -Cc adapter | grep ^en | grep Available | grep -v EtherChannel | awk '{print $1}'`; do
		lscfg -vpl `echo ${ent}` | awk -v ent=${ent} 'BEGIN{printf "\033[0;36m%s\033[0m  ", ent;} $0 ~ /Physical Location:/ {printf "\033[0;36m [\033[0m\033[1;37mphysical_location:\033[0m %s\033[0;36m]\033[0m\n", $3;}$0 ~ /Network Address/ {FS="."; printf "\033[1;37mMac Address:\033[0m %s ", $NF;FS=" ";}'
	done
}
