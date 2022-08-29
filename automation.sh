#!/bin/bash

apachepath=/var/log/apache2/
S3URL=s3://upgradvidyut

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
	

}
#######################################             
# MAIN
######################################

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



