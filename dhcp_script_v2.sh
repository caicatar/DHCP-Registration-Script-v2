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
                   getip=$(sed -n ${linenum}p hosts | awk -F '   '  '{print $1}' | cut -c2- | xargs )
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
        echo "MAC address already registered on this IP:" $ex_mac_ip
        echo "Please check ethers and hosts"
        echo "-----------------------------------------------------------------"
        bash $0
fi
}

#Clear IP Function
clear_dhcp () {
        echo "--------------------------------------------------" 
        echo "|Clear IP                                        |"
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
                ipcheck=$(sed -n ${ipline}p hosts | cut -c1-13 | awk '{$1=$1;print}')

                if [[ $clearip == $ipcheck ]]
                then
                #get IP from ethers and hosts
          	hostrep=$(sed -n ${ipline}p hosts | cut -c 17-)
                ethrep=$(sed -n ${iplineeth}p ethers | rev | cut -c14- | rev | xargs )

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
                fi
	        ;;
                N)
                exit
                ;;
                esac
}

#Catch input
date
now=$(date)
echo "                           [DHCP Registration Script]                                       "
echo "[- If using different criteria for available IPs, please replace #OPEN in the source code  ]"
echo "[- Please make sure that criterias for open IPs are matched to avoid errors during operation ]"
echo "                              [- Choose operation: ]"
echo  "                              1. Register device"
echo  "                              2. Check available IP"
echo  "                              3. Delete Host/IP"
echo  "                              4. View Logs"
echo  "                              5. Clear Logs"
echo  "                              6. Clear dnsmasq.leases"
echo  "                              7. Restart dnsmasq"
echo  "                              0. Exit"
echo "Select:"
read option
case $option in 

   1)
    echo "Enter host name ( no spaces ):" 
    read dhcpname
    echo "Enter mac address: ( correct format no spaces ):"
    read macaddress
    #validate Mac address format
    format1=$(echo $macaddress | sed "/^\([0-9Aa-Zz][0-9Aa-Zz]:\)\{5\}[0-9Aa-Zz][0-9A-Za-z]$/p" )
    format2=$(echo $format1 | rev | cut -c18- | rev | xargs)
    check_mac=$(grep -n -s ${macaddress} ethers |  gawk '{print $1}' FS=":" | head -1)
    ex_mac_ip=$(sed -n ${check_mac}p ethers | cut -c18- | xargs )
    if [[ $macaddress == $format2 ]]
    then
        reg_dhcp  
    else
        echo "-----------------------------------------------------------------"
        echo "| Invalid MAC address format                                    |"
        echo "-----------------------------------------------------------------"
    fi
   ;;
    
   2)
        echo "------------------------------------------------"
        echo "|Available IPs:                                |"
        echo "------------------------------------------------"
	grep -n '#OPEN' hosts | gawk '{print $1}' FS="  " 
   ;;

  3)
        clear_dhcp
  ;;

  4)
       echo "------------------------------------------------"
       echo "|Logs:                                         |"
       echo "------------------------------------------------"
       cat dhcp_logs
 ;;

 5)
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
        ;;
        esac
 ;;

 6)     
        systemctl stop dnsmasq
        cat /dev/null > var/lib/dnsmasq/dnsmasq.leases
        systemctl start dnsmasq
        
        echo "Cleared dnsmasq.leases and restarted dnsmasq service"
 ;;


 7)     
        systemctl restart dnsmasq
        echo "Restarted dnsmasq service"
 ;;

  0)
     exit
  ;;
 
 esac


