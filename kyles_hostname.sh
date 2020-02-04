#!/bin/sh

jssUserPassHash=$4 #hash your username:password and paste into Policy
jssHost=$5 #put jssurl here, include the https:// or else



serial=$(ioreg -rd1 -c IOPlatformExpertDevice | awk -F'"' '/IOPlatformSerialNumber/{print $4}')

username=$(/usr/bin/curl -H "Accept: text/xml" -sfku "${jssUserPass}" "${jssHost}/JSSResource/computers/serialnumber/${serial}/subset/location" | xmllint --format - 2>/dev/null | awk -F'>|<' '/<username>/{print $3}'|cut -f1 -d"@")

city=$(/usr/bin/curl -H "Accept: text/xml" -sfku "${jssUserPass}" "${jssHost}/JSSResource/computers/serialnumber/${serial}/subset/location" | xmllint --format - 2>/dev/null | awk -F'>|<' '/<building>/{print $3}'|cut -f1 -d"@")

product_name=$(ioreg -l | awk '/product-name/ { split($0, line, "\""); printf("%s\n", line[4]); }')


if echo "$product_name" | grep -q "MacBookAir*"
then
    PREFIX="MBA"
    
elif echo "$product_name" | grep -q "MacBookPro*"
then
    PREFIX="MBP"

elif echo "$product_name" | grep -q "iMac*"
then
    PREFIX="iMAC"

elif echo "$product_name" | grep -q "Parallels*"
then
    PREFIX="VM"


else
    echo "No model identifier found."
    PREFIX=""
    
    if [ "$PREFIX" == "" ]; then
    echo "Error: No model identifier found."
    fi
    exit 1
fi

echo Username $username
echo City $city
echo $product_name
echo PREFIX $PREFIX

user=$(echo $username|tr . -)

echo $user

computer_name="${city}-${PREFIX}-${user}"


if [ "$username" == "" ]; then
    echo "Error: Username field is blank."
    exit 1

else

/usr/sbin/scutil --set ComputerName "$computer_name"
/usr/sbin/scutil --set LocalHostName "$computer_name"
/usr/sbin/scutil --set HostName "$computer_name"

dscacheutil -flushcache

echo "Set computer name to $computer_name"

/usr/local/bin/jamf recon
fi

exit 0
