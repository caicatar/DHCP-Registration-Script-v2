#Functions
#Registration Function
reg_dhcp () {
if [[ $check_mac -lt 1 ]]
then
    echo "Save device? Y/N"
    read choice
        case $choice in
                Y)
                   #checks for available IP and provides line
                   linenum=$(grep -n -s '#OPEN' hosts | gawk '{print $1}' FS=":" | head -1 )  
                   #get ip from that available IP 
                   getip=$(sed -n ${linenum}p hosts | awk -F '  '  '{print $1}' | cut -c2- | xargs )
                   
                   #get line from ethers that matches the available IP from hosts 
                   linenumeth=$(grep -n -s ${getip} ethers | gawk '{print $1}' FS=":" | head -1) 

                    #capture dhcp and mac name into variables
                    dhcp=$dhcpname
                    mac=$macaddress

                   #check if the are available IP in hosts file then modify and display results
                   if [[ $linenum -ge  1 && $linenumeth -ge 1 ]] 
                   then 
                        sed -i "${linenum}s/#OPEN/${dhcp}/" hosts
                        sed -i "${linenum}s/#//" hosts
                        sed -i "${linenumeth}s/#OPEN/${mac}/" ethers
                        lineresult=$(sed -n ${linenum}p hosts)
                        ethresult=$(sed -n ${linenumeth}p ethers)
                        systemctl restart dnsmasq
                        echo "Registered:" $lineresult "-" $macaddress "|" $now  >>  dhcp_logs
                        echo "--------------------------------------------------" 
                        echo "|Successfully registered IP:                     |"
                        echo "--------------------------------------------------"
                        #display results for host and ethers ( check if matches )    
                        echo "Hosts:" $lineresult
                        echo "-------------------------------------------------"
                        echo "Ethers:" $ethresult
                        echo "-------------------------------------------------"
                   else
                        echo "-----------------------------------------------------------------"
                        echo "|No available IPs found, please check /etc/hosts or /etc/ethers |"
                        echo "-----------------------------------------------------------------"
                        bash $0
                   fi
                ;;
                N)
                   exit
                ;;
                esac
else
        echo "-----------------------------------------------------------------"
        echo "| MAC already registered.                                       |"
        echo "-----------------------------------------------------------------"
        echo "MAC address already registered in IP(s) below:"
        #Loop and get other macs existing if multiple are found 
        declare -a arr=($multi_mac)
        for i in "${arr[@]}"
        do
                mac_ip=$(sed -n ${i}p ethers | cut -c18- | xargs )
                echo $mac_ip
        done    
        echo "Please check ethers and hosts"
        echo "-----------------------------------------------------------------"

fi
}

#Search_by_name function
search_host (){
        echo "--------------------------------------------------" 
        echo "|Search Host                                     |"
        echo "--------------------------------------------------"
        echo "Search Host Name or IP:"
        read searchhost
        search=$(grep -n -s -i ${searchhost} hosts |  gawk '{print $1}' FS=":")
        search_count=$(grep -n -s -i ${searchhost} hosts |  gawk '{print $1}' FS=":" | wc -l)
        search_check=$(grep -n -s -i ${searchhost} hosts |  gawk '{print $1}' FS=":" | head -1)
        echo "--------------------------------------------------"
        echo "|Search Result:                                  |"
        echo "--------------------------------------------------"
        if [[ $search_check -gt 1 ]]
        then
                declare -a arr=($search)
                for i in "${arr[@]}"
                do
                        search_res=$(sed -n ${i}p hosts |  xargs )
                        echo $search_res
                done
        else
                echo "No results."
        fi
        echo "--------------------------------------------------"
        echo "Total result count:" $search_count
        echo "--------------------------------------------------"
}

#Delete host Function
delete_dhcp () {
        echo "--------------------------------------------------" 
        echo "|Delete Host                                     |"
        echo "--------------------------------------------------"
        echo "Search IP:"
        read clearip
        echo "Clear IP?" $clearip "(Y/N)"
	read sel
	case $sel in 
                Y)
                #get IP from hosts and ethers
        	ipline=$(grep -n ${clearip} hosts | gawk '{print $1}' FS=":" | head -1)
   		iplineeth=$(grep -n ${clearip} ethers | gawk '{print $1}' FS=":" | head -1)
                #get IP from $ipline
                ipcheck=$(sed -n ${ipline}p hosts | cut -c1-14 | awk '{$1=$1;print}')

                if [[ $clearip == $ipcheck ]]
                then
                #get IP from ethers and hosts
          	hostrep=$(sed -n ${ipline}p hosts | cut -c 17-)
                ethrep=$(sed -n ${iplineeth}p ethers | rev | cut -c14- | rev | xargs | gawk '{print $1}' FS=" " )

                #replace MAC and HOST NAME based on ID with #OPEN
        	sed -i "${ipline}s/${hostrep}/#OPEN/" hosts
                sed -i "/^${clearip}/ s/./#&/" hosts
       	        sed -i "${iplineeth}s/${ethrep}/#OPEN/" ethers

         	echo "Cleared:" $clearip "-" $hostrep "-" $ethrep "|" $now  >>  dhcp_logs
         	echo "--------------------------------------------------" 
         	echo "|Successfully cleared IP:                        |"
         	echo "--------------------------------------------------"
        	 #display results for host and ethers ( check if matches )    
        	 echo "Hosts:" $clearip
        	 echo "-------------------------------------------------"
                else    
                     echo "IP not found!"
                     bash $0
                fi
	        ;;
                N)
                        exit
                ;;
                esac
}

#Logs option
logs_dhcp () {
echo "------------------------------------------------"
echo "|Logs Menu:                                    |"
echo "------------------------------------------------"
echo "1. View Logs"
echo "2. Clear Logs"
echo "Select Logs operation:"
read logs
case $logs in      
   1)
        echo "------------------------------------------------"
        echo "|Logs:                                         |"
        echo "------------------------------------------------"
        cat dhcp_logs
   ;;

   2)
       echo "------------------------------------------------"
       echo "|Clear Logs:                                   |"
       echo "------------------------------------------------"
       echo "Clear logs? (Y/N)"
       read sel
	case $sel in 
        Y)
                cat /dev/null > dhcp_logs
                echo "Cleared Logs"
	;;
        N)
                exit
                bash $0
        ;;
        esac
   ;;
esac
}

#Backup Options
backup_dhcp () {
echo "------------------------------------------------"
echo "|Backup Menu:                                   |"
echo "------------------------------------------------"
echo "1. Check backups"
echo "2. Backup Hosts and Ethers"
echo "Select backup operation:"
read backups
case $backups in      
   1)
        echo "------------------------------------------------"
        echo "|Backups:                                      |"
        echo "------------------------------------------------"
        ls backup
   ;;

   2)
       echo "------------------------------------------------"
       echo "|Backup Hosts and Ethers?                      |"
       echo "------------------------------------------------"
       echo "Backup host and ethers? (Y/N)"
       read sel
	case $sel in 
        Y)      
                if [[ -d "backup" ]]
                then
                    cp hosts backup/hosts-$datebackup
                    cp ethers backup/ethers-$datebackup
                    echo "Backup Success!"
                else   
                    mkdir backup
                    cp hosts backup/hosts-$datebackup
                    cp ethers backup/ethers-$datebackup
                    echo "Backup folder created, Backup Success!"
                fi

	;;
        N)
                exit
        ;;
        esac
   ;;
esac
}

#Interface menu
date
now=$(date)
datebackup=$(date +%m-%d-%y-%T)
green=`tput setaf 2`
echo "                            [DHCP Registration Script]                                      "
echo "[- If using different criteria for available IPs, please replace #OPEN in the source code  ]"
echo "[- Please make sure that criterias for open IPs are matched to avoid errors during operation ]"
echo "                              [- Choose operation: ]"
echo  "                              1. Register device"
echo  "                              2. Search Hosts"
echo  "                              3. Check Available IP"
echo  "                              4. Delete IP/Host"
echo  "                              5. Logs"
echo  "                              6. Backups"
echo  "                                                       "
echo  "                              7. Clear dnsmasq.leases"
echo  "                              8. Restart dnsmasq"
echo  "                              0. Exit"
echo "Select:"
read option
case $option in 

   #Registration   
   1)
    echo "Enter host name ( no spaces, alphanumeric and _ only ):" 
    read dhcpname
    echo "Enter mac address: ( mac address format only ):"
    read macaddress
    #validate hostname format
    hostformat=$(echo $dhcpname | sed "s/[^[:alnum:]_]//g")
    #validate Mac address format
    format1=$(echo $macaddress | sed "/^\([0-9Aa-Zz][0-9Aa-Zz]:\)\{5\}[0-9Aa-Zz][0-9A-Za-z]$/p" )
    format2=$(echo $format1 | rev | cut -c18- | rev | xargs)
    check_mac=$(grep -n -s ${macaddress} ethers |  gawk '{print $1}' FS=":" | head -1)
    multi_mac=$(grep -n -s ${macaddress} ethers |  gawk '{print $1}' FS=":")
    ex_mac_ip=$(sed -n ${check_mac}p ethers | cut -c18- | xargs )
    if [[ $macaddress == $format2 && $hostformat == $dhcpname ]]
    then
        reg_dhcp  
    else
        echo "-----------------------------------------------------------------"
        echo "| Invalid MAC address or hostname format                       |"
        echo "-----------------------------------------------------------------"
    fi
   ;;

   #Search Host option     
   2)
         search_host
   ;;

   #Available IPs
   3)
        echo "------------------------------------------------"
        echo "|Available IPs:                                |"
        echo "------------------------------------------------"
        grep -n '#OPEN' hosts | gawk '{print $1}' FS="  " | cut -c5-
	totalip=$(grep -n '#OPEN' hosts | gawk '{print $1}' FS="  " | cut -c5- | wc -l)
        echo "------------------------------------------------"
        echo "|Total available IPs:" $totalip               "|"
        echo "------------------------------------------------"
   ;;

   #Delete DHCP/IP
   4)
         delete_dhcp
   ;;

   #Logs
   5)
        logs_dhcp
   ;;
   
   #Backups 
   6)
        backup_dhcp
   ;;

   7)     
        systemctl stop dnsmasq
        cat /dev/null > var/lib/dnsmasq/dnsmasq.leases
        systemctl start dnsmasq
        
        echo "Cleared dnsmasq.leases and restarted dnsmasq service |" $now  >>  dhcp_logs
   ;;


   7)     
        systemctl restart dnsmasq
        echo "Restarted dnsmasq service |" $now >> dhcp_logs
   ;;


   0)
     exit
  ;;
 
 esac


