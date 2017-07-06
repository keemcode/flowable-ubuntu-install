#!/bin/bash
# -------
# Script for install of Flowable
#
# Copyright 2013-2017 Loftux AB, Peter Löfgren
# Distributed under the Creative Commons Attribution-ShareAlike 3.0 Unported License (CC BY-SA 3.0)
# -------

export FLOW_HOME=/opt/flowable
export CATALINA_HOME=$FLOW_HOME/tomcat
export FLOW_USER=flowable
export FLOW_GROUP=$FLOW_USER
export APTVERBOSITY="-qq -y"
export TMP_INSTALL=/tmp/flowableinstall
export DEFAULTYESNO="y"

# Branch name to pull from server. Use master for stable.
BRANCH=master
export BASE_DOWNLOAD=https://raw.githubusercontent.com/douglascrp/alfresco-ubuntu-install/$BRANCH

export LOCALESUPPORT=en_US.utf8

export TOMCAT_DOWNLOAD=http://archive.apache.org/dist/tomcat/tomcat-8/v8.0.38/bin/apache-tomcat-8.0.38.tar.gz
export JDBCPOSTGRESURL=https://jdbc.postgresql.org/download
export JDBCPOSTGRES=postgresql-9.4.1211.jar
export JDBCMYSQLURL=https://dev.mysql.com/get/Downloads/Connector-J
export JDBCMYSQL=mysql-connector-java-5.1.40.tar.gz

export FLOWABLE_ADMIN_DOWNLOAD=http://central.maven.org/maven2/org/flowable/flowable-ui-admin/6.1.0/flowable-ui-admin-6.1.0.war
export FLOWABLE_IDM_DOWNLOAD=http://central.maven.org/maven2/org/flowable/flowable-ui-idm-app/6.1.0/flowable-ui-idm-app-6.1.0.war
export FLOWABLE_MODELER_DOWNLOAD=http://central.maven.org/maven2/org/flowable/flowable-ui-modeler-app/6.1.0/flowable-ui-modeler-app-6.1.0.war
export FLOWABLE_REST_DOWNLOAD=http://central.maven.org/maven2/org/flowable/flowable-app-rest/6.1.0/flowable-app-rest-6.1.0.war
export FLOWABLE_TASK_DOWNLOAD=http://central.maven.org/maven2/org/flowable/flowable-ui-task-app/6.1.0/flowable-ui-task-app-6.1.0.war

# Color variables
txtund=$(tput sgr 0 1)          # Underline
txtbld=$(tput bold)             # Bold
bldred=${txtbld}$(tput setaf 1) #  red
bldgre=${txtbld}$(tput setaf 2) #  red
bldblu=${txtbld}$(tput setaf 4) #  blue
bldwht=${txtbld}$(tput setaf 7) #  white
txtrst=$(tput sgr0)             # Reset
info=${bldwht}*${txtrst}        # Feedback
pass=${bldblu}*${txtrst}
warn=${bldred}*${txtrst}
ques=${bldblu}?${txtrst}

echoblue () {
  echo "${bldblu}$1${txtrst}"
}
echored () {
  echo "${bldred}$1${txtrst}"
}
echogreen () {
  echo "${bldgre}$1${txtrst}"
}
cd /tmp
if [ -d "flowableinstall" ]; then
	rm -rf flowableinstall
fi
mkdir flowableinstall
cd ./flowableinstall

echo
echoblue "- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -"
echogreen "Flowable Ubuntu installer by Loftux AB."
echogreen "Please read the documentation at"
echogreen "https://github.com/douglascrp/flowable-ubuntu-install."
echoblue "- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -"
echo

echo "Installing Flowable Community edition from Flowable Software"
echo

echo
echoblue "- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -"
echo "Checking for the availability of the URLs inside script..."
echoblue "- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -"
echo

echo
echoblue "- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -"
echo "Preparing for install. Updating the apt package index files..."
echoblue "- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -"
sudo apt-get $APTVERBOSITY update;
echo

if [ "`which systemctl`" = "" ]; then
  export ISON1604=n
  echoblue "- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -"
  echo "You are installing for version 14.04 (using upstart for services)."
  echoblue "- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -"
  read -e -p "Is this correct [y/n] " -i "$DEFAULTYESNO" useupstart
  if [ "$useupstart" = "n" ]; then
    export ISON1604=y
  fi
else 
  export ISON1604=y
  echoblue "- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -"
  echo "You are installing for version 16.04 or later (using systemd for services)."
  echoblue "- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -"
  read -e -p "Is this correct [y/n] " -i "$DEFAULTYESNO" useupstart
  if [ "$useupstart" = "n" ]; then
    export ISON1604=n
  fi
fi

if [ "`which curl`" = "" ]; then
echoblue "- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -"
echo "You need to install curl. Curl is used for downloading components to install."
echoblue "- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -"
sudo apt-get $APTVERBOSITY install curl;
fi

if [ "`which wget`" = "" ]; then
echoblue "- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -"
echo "You need to install wget. Wget is used for downloading components to install."
echoblue "- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -"
sudo apt-get $APTVERBOSITY install wget;
fi

URLERROR=0

for REMOTE in $TOMCAT_DOWNLOAD $JDBCPOSTGRESURL/$JDBCPOSTGRES $JDBCMYSQLURL/$JDBCMYSQL \
        $FLOWABLE_ADMIN_DOWNLOAD $FLOWABLE_IDM_DOWNLOAD $FLOWABLE_MODELER_DOWNLOAD \
        $FLOWABLE_REST_DOWNLOAD $FLOWABLE_TASK_DOWNLOAD

do
        wget --spider $REMOTE --no-check-certificate >& /dev/null
        if [ $? != 0 ]
        then
                echored "In flowableinstall.sh, please fix this URL: $REMOTE"
                URLERROR=1
        fi
done

if [ $URLERROR = 1 ]
then
    echo
    echored "Please fix the above errors and rerun."
    echo
    exit
fi

echo
echoblue "- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -"
echo "You need to add a system user that runs the tomcat Flowable instance."
echoblue "- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -"
read -e -p "Add flowable system user${ques} [y/n] " -i "$DEFAULTYESNO" addflowable
if [ "$addflowable" = "y" ]; then
  sudo adduser --system --disabled-login --disabled-password --group $FLOW_USER
  echo
  echogreen "Finished adding flowable user"
  echo
else
  echo "Skipping adding flowable user"
  echo
fi

echo
echoblue "- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -"
echo "You need to set the locale to use when running tomcat Flowable instance."
echo "This has an effect on date formats for transformations and support for"
echo "international characters."
echoblue "- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -"
read -e -p "Enter the default locale to use: " -i "$LOCALESUPPORT" LOCALESUPPORT
#install locale to support that locale date formats in open office transformations
sudo locale-gen $LOCALESUPPORT
echo
echogreen "Finished updating locale"
echo

echo
echoblue "- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -"
echo "Tomcat is the application server that runs Flowable."
echo "You will also get the option to install jdbc lib for Postgresql or MySql."
echo "Install the jdbc lib for the database you intend to use."
echoblue "- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -"
read -e -p "Install Tomcat${ques} [y/n] " -i "$DEFAULTYESNO" installtomcat

if [ "$installtomcat" = "y" ]; then
  echogreen "Installing Tomcat"
  echo "Downloading tomcat..."
  curl -# -L -O $TOMCAT_DOWNLOAD
  # Make sure install dir exists, including logs dir
  sudo mkdir -p $FLOW_HOME/logs
  echo "Extracting..."
  tar xf "$(find . -type f -name "apache-tomcat*")"
  sudo mv "$(find . -type d -name "apache-tomcat*")" $CATALINA_HOME
  # Remove apps not needed
  sudo rm -rf $CATALINA_HOME/webapps/*
  # Get Flowable config

  if [ "$ISON1604" = "y" ]; then
    sudo curl -# -o /etc/systemd/system/flowable.service $BASE_DOWNLOAD/tomcat/flowable.service
    sudo curl -# -o $FLOW_HOME/flowable-service.sh $BASE_DOWNLOAD/scripts/flowable-service.sh
    sudo chmod 755 $FLOW_HOME/flowable-service.sh
    sudo sed -i "s/@@LOCALESUPPORT@@/$LOCALESUPPORT/g" $FLOW_HOME/flowable-service.sh 
    # Enable the service
    sudo systemctl enable flowable.service
    sudo systemctl daemon-reload
  else
    sudo curl -# -o /etc/init/flowable.conf $BASE_DOWNLOAD/tomcat/flowable.conf
    sudo sed -i "s/@@LOCALESUPPORT@@/$LOCALESUPPORT/g" /etc/init/flowable.conf
  fi

  echo
  echoblue "- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -"
  echo "You need to add the dns name, port and protocol for your server(s)."
  echo "It is important that this is is a resolvable server name."
  echo "This information will be added to default configuration files."
  echoblue "- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -"
  read -e -p "Please enter the public host name for Flowable server (fully qualified domain name)${ques} [`hostname`] " -i "`hostname`" FLOWABLE_HOSTNAME
  read -e -p "Please enter the protocol to use for public Flowable server (http or https)${ques} [http] " -i "http" FLOWABLE_PROTOCOL
  read -e -p "Please enter the port to use for public Flowable server ${ques} [8080] " -i "8080" FLOWABLE_PORT
  if [ "${FLOWABLE_PROTOCOL,,}" = "https" ]; then
    FLOWABLE_PORT=443
  fi

  # Add default flowable-ui-app.properties
  FLOWABLE_UI_APP_PROPERTIES=/tmp/flowableinstall/flowable-ui-app.properties
  sudo curl -# -o $FLOWABLE_UI_APP_PROPERTIES $BASE_DOWNLOAD/tomcat/flowable-ui-app.properties
  sed -i "s/@@FLOWABLE_SERVER@@/$FLOWABLE_HOSTNAME/g" $FLOWABLE_UI_APP_PROPERTIES
  sed -i "s/@@FLOWABLE_SERVER_PORT@@/$FLOWABLE_PORT/g" $FLOWABLE_UI_APP_PROPERTIES
  sed -i "s/@@FLOWABLE_SERVER_PROTOCOL@@/$FLOWABLE_PROTOCOL/g" $FLOWABLE_UI_APP_PROPERTIES
  sudo mv $FLOWABLE_UI_APP_PROPERTIES $CATALINA_HOME/lib/

  echo
  read -e -p "Install Postgres JDBC Connector${ques} [y/n] " -i "$DEFAULTYESNO" installpg
  if [ "$installpg" = "y" ]; then
	curl -# -O $JDBCPOSTGRESURL/$JDBCPOSTGRES
	sudo mv $JDBCPOSTGRES $CATALINA_HOME/lib
  fi
  echo
  read -e -p "Install Mysql JDBC Connector${ques} [y/n] " -i "$DEFAULTYESNO" installmy
  if [ "$installmy" = "y" ]; then
    cd /tmp/flowableinstall
	curl -# -L -O $JDBCMYSQLURL/$JDBCMYSQL
	tar xf $JDBCMYSQL
	cd "$(find . -type d -name "mysql-connector*")"
	sudo mv mysql-connector*.jar $CATALINA_HOME/lib
  fi
  sudo chown -R $FLOW_USER:$FLOW_GROUP $FLOW_HOME
  echo
  echogreen "Finished installing Tomcat"
  echo
else
  echo "Skipping install of Tomcat"
  echo
fi

echo
echoblue "- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -"
echo "Install Java JDK."
echo "This will install Oracle Java 8 version of Java. If you prefer OpenJDK"
echo "you need to download and install that manually."
echoblue "- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -"
read -e -p "Install Oracle Java 8${ques} [y/n] " -i "$DEFAULTYESNO" installjdk
if [ "$installjdk" = "y" ]; then
  echoblue "Installing Oracle Java 8. Fetching packages..."
  sudo apt-get $APTVERBOSITY install python-software-properties software-properties-common
  sudo add-apt-repository ppa:webupd8team/java
  sudo apt-get $APTVERBOSITY update
  echo oracle-java8-installer shared/accepted-oracle-license-v1-1 select true | sudo /usr/bin/debconf-set-selections
  sudo apt-get $APTVERBOSITY install oracle-java8-installer
  sudo update-java-alternatives -s java-8-oracle
  echo
  echogreen "Finished installing Oracle Java 8"
  echo
else
  echo "Skipping install of Oracle Java 8"
  echored "IMPORTANT: You need to install other JDK and adjust paths for the install to be complete"
  echo
fi

echo
echoblue "Adding basic support files. Always installed if not present."
echo
  sudo mkdir -p $FLOW_HOME/scripts

  if [ ! -f "$FLOW_HOME/scripts/postgresql.sh" ]; then
    echo "Downloading postgresql.sh install and setup script..."
    sudo curl -# -o $FLOW_HOME/scripts/postgresql.sh $BASE_DOWNLOAD/scripts/postgresql.sh
  fi

  if [ ! -f "$FLOW_HOME/scripts/mysql.sh" ]; then
    echo "Downloading mysql.sh install and setup script..."
    sudo curl -# -o $FLOW_HOME/scripts/mysql.sh $BASE_DOWNLOAD/scripts/mysql.sh
  fi

  sudo chmod 755 $FLOW_HOME/scripts/*.sh

echo
echoblue "- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -"
echo "Install Flowable war files."
echo "Download war files."
echo "If you have already downloaded your war files you can skip this step and add "
echo "them manually."
echo
echoblue "- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -"
read -e -p "Add Flowable war files${ques} [y/n] " -i "$DEFAULTYESNO" installwar
if [ "$installwar" = "y" ]; then

  echogreen "Downloading flowable war files..."
  sudo curl -# -o $CATALINA_HOME/webapps/flowable-admin.war $FLOWABLE_ADMIN_DOWNLOAD 
  sudo curl -# -o $CATALINA_HOME/webapps/flowable-idm.war $FLOWABLE_IDM_DOWNLOAD 
  sudo curl -# -o $CATALINA_HOME/webapps/flowable-modeler.war $FLOWABLE_MODELER_DOWNLOAD
  sudo curl -# -o $CATALINA_HOME/webapps/flowable-rest.war $FLOWABLE_REST_DOWNLOAD 
  sudo curl -# -o $CATALINA_HOME/webapps/flowable-task.war $FLOWABLE_TASK_DOWNLOAD
  echo
  echogreen "Finished adding Flowable war files"
  echo
else
  echo
  echo "Skipping adding Flowable war files"
  echo
fi

if [ "$installwar" = "y" ] || [ "$installsharewar" = "y" ]; then
cd /tmp/flowableinstall
fi

# Finally, set the permissions
sudo chown -R $FLOW_USER:$FLOW_GROUP $FLOW_HOME

echo
echogreen "- - - - - - - - - - - - - - - - -"
echo "Scripted install complete"
echo
echored "Manual tasks remaining:"
echo
echo "1. Add database. Install scripts available in $FLOW_HOME/scripts"
echo
echo "2. Verify Tomcat memory and locale settings in the file"
if [ "$ISON1604" = "y" ]; then
echo "   $FLOW_HOME/flowable-service.sh."
else
echo "   /etc/init/flowable.conf."
fi
echo "   Match the locale LC_ALL (or remove) setting to the one used in this script."
echo
echo "3. Update database and other settings in flowable-ui-app.properties"
echo "   You will find this file in $CATALINA_HOME/lib/"
echored "   Really, do this. There are some settings there that you need to verify."
echo
echo "4. Start nginx if you have installed it: sudo service nginx start"
echo
echo "5. Start Flowable/tomcat:"
if [ "$ISON1604" = "y" ]; then
echo "   sudo $FLOW_HOME/flowable-service.sh start"
else
echo "   sudo service flowable start"
fi
echo

echo
echo "${warn}${bldblu} - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - ${warn}"
echogreen "Thanks for using Flowable Ubuntu installer by Loftux AB."
echogreen "Please visit https://loftux.com for more Flowable Services and add-ons."
echogreen "You are welcome to contact us at info@loftux.se"
echo "${warn}${bldblu} - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - ${warn}"
echo