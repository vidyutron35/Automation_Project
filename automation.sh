#!/bin/bash

apachepath=/var/log/apache2/
S3URL=s3://upgradvidyut
HTMLPATH=/var/www/html/
html_file=inventory.html
Log_detail_file=Log_file

installation()
{
        # package updates
        # apache installation, enabling and status check
        sudo apt install apache2 &>> automation.log

           if [ $(echo "$?") -eq 0 ]
           then
                      echo "Installation Succesfull"
              fi

              sudo systemctl start apache2 &>> automation.log


              if [ $(echo "$?") -eq 0 ]
              then
                         echo "httpd service started"
                 fi


                 sudo systemctl enable apache2  &>> automation.log

                 if [ $(echo "$?") -eq 0 ]
                 then
                            echo "Enable httpd"
                    fi

                    sudo systemctl status apache2 | grep Active
            }

copy_log()
{

        cd $apachepath

        find . -name "*.log" | xargs  tar -cvzf  vidyut-httpd-log_$(date '+%d%m%Y-%H%M%S').tar.gz
        mv *.gz /tmp
        cd /tmp

        GZ=`find . -name "*.gz"`
      aws s3 cp ${GZ} $S3URL

####################creating inventory HTML file ##########################

echo $GZ,$( date -r $GZ +%F ),$( echo $GZ | tr "." " " | awk '{ print $NF } ' ),$( du -h $GZ | awk '{ print $1 }' ) >>$Log_detail_file
rm $GZ
cp $Log_detail_file $HTMLPATH
cd $HTMLPATH

echo "<html>" > $html_file

echo "<head>" >> $html_file

echo "<style>" >> $html_file

echo "table, th, td { border: 1px solid black; border-collapse: collapse; padding-left: 1% ; }" >> $html_file

echo "</style>" >> $html_file

echo "</head>" >> $html_file

echo '<table style="width:75%">' >> $html_file

echo '<tr style="background-color: #D9EA70;">' >>$html_file

echo '<td align="center">Log Type</td>' >> $html_file

echo '<td align="center">Date Created</td>' >> $html_file
echo '<td align="center">Type</td>' >> $html_file

echo '<td align="center">Size</td>' >> $html_file

echo "</tr>" >> $html_file

IFS=","

while read filename filedate filetype filesize

do

            echo "<tr>" >>$html_file

                echo "<td align='left' >$filename</td>" >> $html_file

                    echo "<td align='center'>$filedate</td>" >> $html_file

                        echo "<td align='center' >$filetype</td>" >> $html_file

                            echo "<td align='center' >$filesize</td>" >> $html_file

                                echo "</tr>" >> $html_file

                        done < $Log_detail_file



                        echo "</table>" >> $html_file

                        echo "</html>" >> $html_file

}

cronjob()
{
cron=`crontab -l`
if [ "$cron" = "" ]
then
        sudo touch /etc/cron.d/automation
        sudo echo "30 03 * * * root /root/Automation_Project/automation.sh" > /etc/cron.d/automation
        sudo chmod 600 /etc/cron.d/automation

else
        echo "Crontab already present"
fi
}

#######################################             
# MAIN
######################################

sudo apt update -y &>> automation.log
sudo apt update -y &>> automation.log

PRS=$(apache2 -v)
if [ "${PRS}" = "" ]
then
        installation
else
        DPID=$(ps -ef | grep root | grep apache2 |grep -v grep)
        if [ "${DPID}" = "" ]
        then
                Check=$(systemctl is-enabled apache2)
                 if [ "${Check}" != "enabled" ]
                then
                        sudo systemctl enable apache2  &>> automation.log
                fi
                         sudo systemctl start apache2 &>> automation.log

                 if [ $(echo "$?") -eq 0 ]
                   then
                  echo "httpd service started"
                  copy_log
                 fi

         else
                 Check=$(systemctl is-enabled apache2)
                 if [ "${Check}" != "enabled" ]
                 then
                         sudo systemctl enable apache2  &>> automation.log
                 fi
                copy_log
fi
fi

cronjob

