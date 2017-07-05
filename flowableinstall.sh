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
BRANCH=flowable_install
export BASE_DOWNLOAD=https://raw.githubusercontent.com/douglascrp/alfresco-ubuntu-install/$BRANCH

export LOCALESUPPORT=en_US.utf8

export TOMCAT_DOWNLOAD=http://archive.apache.org/dist/tomcat/tomcat-8/v8.0.38/bin/apache-tomcat-8.0.38.tar.gz
export JDBCPOSTGRESURL=https://jdbc.postgresql.org/download
export JDBCPOSTGRES=postgresql-9.4.1211.jar
export JDBCMYSQLURL=https://dev.mysql.com/get/Downloads/Connector-J
export JDBCMYSQL=mysql-connector-java-5.1.40.tar.gz

export FLOWABLE_DOWNLOAD=https://github.com/flowable/flowable-engine/releases/download/flowable-6.1.0/flowable-6.1.0.zip

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
        $FLOWABLE_DOWNLOAD

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
echo "You will also get the option to install jdbc lib for Postgresql or MySql/MariaDB."
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
  read -e -p "Please enter the public host name for Share server (fully qualified domain name)${ques} [`hostname`] " -i "`hostname`" SHARE_HOSTNAME
  read -e -p "Please enter the protocol to use for public Share server (http or https)${ques} [http] " -i "http" SHARE_PROTOCOL
  SHARE_PORT=80
  if [ "${SHARE_PROTOCOL,,}" = "https" ]; then
    SHARE_PORT=443
  fi
  read -e -p "Please enter the host name for Flowable Repository server (fully qualified domain name)${ques} [$SHARE_HOSTNAME] " -i "$SHARE_HOSTNAME" REPO_HOSTNAME

  # Add default flowable-ui-app.properties
  FLOWABLE_UI_APP_PROPERTIES=/tmp/flowableinstall/flowable-ui-app.properties
  sudo curl -# -o $FLOWABLE_UI_APP_PROPERTIES $BASE_DOWNLOAD/tomcat/lib/flowable-ui-app.properties
  sed -i "s/@@FLOWABLE_SERVER@@/$SHARE_HOSTNAME/g" $FLOWABLE_UI_APP_PROPERTIES
  sed -i "s/@@FLOWABLE_SERVER_PORT@@/$SHARE_PORT/g" $FLOWABLE_UI_APP_PROPERTIES
  sed -i "s/@@FLOWABLE_SERVER_PROTOCOL@@/$SHARE_PROTOCOL/g" $FLOWABLE_UI_APP_PROPERTIES
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
echo "Download war files and optional addons."
echo "If you have already downloaded your war files you can skip this step and add "
echo "them manually."
echo
echo "If you use separate Flowable and Share server, only install the needed for each"
echo "server. Flowable Repository will need Share Services if you use Share."
echo
echo "This install place downloaded files in the $FLOW_HOME/addons and then use the"
echo "apply.sh script to add them to tomcat/webapps. Se this script for more info."
echoblue "- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -"
read -e -p "Add Flowable Repository war file${ques} [y/n] " -i "$DEFAULTYESNO" installwar
if [ "$installwar" = "y" ]; then

  echogreen "Downloading flowable war file..."
  sudo curl -# -o $FLOW_HOME/addons/war/flowable.war $FLOWREPOWAR
  echo

  # Add default flowable and share modules classloader config files
  sudo curl -# -o $CATALINA_HOME/conf/Catalina/localhost/flowable.xml $BASE_DOWNLOAD/tomcat/flowable.xml

  echogreen "Finished adding Flowable Repository war file"
  echo
else
  echo
  echo "Skipping adding Flowable Repository war file and addons"
  echo
fi

read -e -p "Add Share Client war file${ques} [y/n] " -i "$DEFAULTYESNO" installsharewar
if [ "$installsharewar" = "y" ]; then

  echogreen "Downloading Share war file..."
  sudo curl -# -o $FLOW_HOME/addons/war/share.war $FLOWSHAREWAR

  # Add default flowable and share modules classloader config files
  sudo curl -# -o $CATALINA_HOME/conf/Catalina/localhost/share.xml $BASE_DOWNLOAD/tomcat/share.xml

  echo
  echogreen "Finished adding Share war file"
  echo
else
  echo
  echo "Skipping adding Flowable Share war file"
  echo
fi

if [ "$installwar" = "y" ] || [ "$installsharewar" = "y" ]; then
cd /tmp/flowableinstall

if [ "$installwar" = "y" ]; then
    echored "You must install Share Services if you intend to use Share Client."
    read -e -p "Add Share Services plugin${ques} [y/n] " -i "$DEFAULTYESNO" installshareservices
    if [ "$installshareservices" = "y" ]; then
      echo "Downloading Share Services addon..."
      curl -# -O $FLOWSHARESERVICES
      sudo mv flowable-share-services*.amp $FLOW_HOME/addons/flowable/
    fi
fi

read -e -p "Add Google docs integration${ques} [y/n] " -i "$DEFAULTYESNO" installgoogledocs
if [ "$installgoogledocs" = "y" ]; then
  echo "Downloading Google docs addon..."
  if [ "$installwar" = "y" ]; then
    curl -# -O $GOOGLEDOCSREPO
    sudo mv flowable-googledocs-repo*.amp $FLOW_HOME/addons/flowable/
  fi
  if [ "$installsharewar" = "y" ]; then
    curl -# -O $GOOGLEDOCSSHARE
    sudo mv flowable-googledocs-share* $FLOW_HOME/addons/share/
  fi
fi
fi


echo
echoblue "- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -"
echo "Install Flowable Office Services (Sharepoint protocol emulation)."
echo "This allows you to open and save Microsoft Office documents online."
echored "This module is not Open Source (Flowable proprietary)."
echoblue "- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -"
read -e -p "Install Flowable Office Services integration${ques} [y/n] " -i "$DEFAULTYESNO" installssharepoint
if [ "$installssharepoint" = "y" ]; then
    echogreen "Installing Flowable Offices Services bundle..."
    echogreen "Downloading Flowable Office Services amp file"
    # Sub shell to keep the file name
    (cd $FLOW_HOME/addons/flowable;sudo curl -# -O $AOS_AMP)
    echogreen "Downloading _vti_bin.war into tomcat/webapps"
    sudo curl -# -o $FLOW_HOME/tomcat/webapps/_vti_bin.war $AOS_VTI
    echogreen "Downloading ROOT.war into tomcat/webapps"
    sudo curl -# -o $FLOW_HOME/tomcat/webapps/ROOT.war $AOS_SERVER_ROOT
fi

# Install of war and addons complete, apply them to war file
if [ "$installwar" = "y" ] || [ "$installsharewar" = "y" ] || [ "$installssharepoint" = "y" ]; then
    # Check if Java is installed before trying to apply
    if type -p java; then
        _java=java
    elif [[ -n "$JAVA_HOME" ]] && [[ -x "$JAVA_HOME/bin/java" ]];  then
        _java="$JAVA_HOME/bin/java"
        echored "No JDK installed. When you have installed JDK, run "
        echored "$FLOW_HOME/addons/apply.sh all"
        echored "to install addons with Flowable or Share."
    fi
    if [[ "$_java" ]]; then
        sudo $FLOW_HOME/addons/apply.sh all
    fi
fi

echo
echoblue "- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -"
echo "Install Solr4 indexing engine."
echo "You can run Solr4 on a separate server, unless you plan to do that you should"
echo "install the Solr4 indexing engine on the same server as your repository server."
echoblue "- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -"
read -e -p "Install Solr4 indexing engine${ques} [y/n] " -i "$DEFAULTYESNO" installsolr
if [ "$installsolr" = "y" ]; then

  # Make sure we have unzip available
  sudo apt-get $APTVERBOSITY install unzip

  # Check if we have an old install
  if [ -d "$FLOW_HOME/solr4" ]; then
     sudo mv $FLOW_HOME/solr4 $FLOW_HOME/solr4_BACKUP_`eval date +%Y%m%d%H%M`
  fi
  sudo mkdir -p $FLOW_HOME/solr4
  cd $FLOW_HOME/solr4

  echogreen "Downloading solr4.war file..."
  sudo curl -# -o $CATALINA_HOME/webapps/solr4.war $SOLR4_WAR_DOWNLOAD

  echogreen "Downloading config file..."
  sudo curl -# -o $FLOW_HOME/solr4/solrconfig.zip $SOLR4_CONFIG_DOWNLOAD
  echogreen "Expanding config file..."
  sudo unzip -q solrconfig.zip
  sudo rm solrconfig.zip

  echogreen "Configuring..."

  # Make sure dir exist
  sudo mkdir -p $FLOW_DATA_HOME/solr4
  mkdir -p $TMP_INSTALL

  # Remove old config if exists
  if [ -f "$CATALINA_HOME/conf/Catalina/localhost/solr.xml" ]; then
     sudo rm $CATALINA_HOME/conf/Catalina/localhost/solr.xml
  fi

  # Set the solr data path
  SOLRDATAPATH="$FLOW_DATA_HOME/solr4"
  # Escape for sed
  SOLRDATAPATH="${SOLRDATAPATH//\//\\/}"

  sudo mv $FLOW_HOME/solr4/workspace-SpacesStore/conf/solrcore.properties $FLOW_HOME/solr4/workspace-SpacesStore/conf/solrcore.properties.orig
  sudo mv $FLOW_HOME/solr4/archive-SpacesStore/conf/solrcore.properties $FLOW_HOME/solr4/archive-SpacesStore/conf/solrcore.properties.orig
  sed "s/@@FLOWRESCO_SOLR4_DATA_DIR@@/$SOLRDATAPATH/g" $FLOW_HOME/solr4/workspace-SpacesStore/conf/solrcore.properties.orig >  $TMP_INSTALL/solrcore.properties
  sudo mv  $TMP_INSTALL/solrcore.properties $FLOW_HOME/solr4/workspace-SpacesStore/conf/solrcore.properties
  sed "s/@@FLOWRESCO_SOLR4_DATA_DIR@@/$SOLRDATAPATH/g" $FLOW_HOME/solr4/archive-SpacesStore/conf/solrcore.properties.orig >  $TMP_INSTALL/solrcore.properties
  sudo mv  $TMP_INSTALL/solrcore.properties $FLOW_HOME/solr4/archive-SpacesStore/conf/solrcore.properties

  echo "<?xml version=\"1.0\" encoding=\"utf-8\"?>" > $TMP_INSTALL/solr4.xml
  echo "<Context debug=\"0\" crossContext=\"true\">" >> $TMP_INSTALL/solr4.xml
  echo "  <Environment name=\"solr/home\" type=\"java.lang.String\" value=\"$FLOW_HOME/solr4\" override=\"true\"/>" >> $TMP_INSTALL/solr4.xml
  echo "  <Environment name=\"solr/model/dir\" type=\"java.lang.String\" value=\"$FLOW_HOME/solr4/flowableModels\" override=\"true\"/>" >> $TMP_INSTALL/solr4.xml
  echo "  <Environment name=\"solr/content/dir\" type=\"java.lang.String\" value=\"$FLOW_DATA_HOME/solr4/content\" override=\"true\"/>" >> $TMP_INSTALL/solr4.xml
  echo "</Context>" >> $TMP_INSTALL/solr4.xml
  sudo mv $TMP_INSTALL/solr4.xml $CATALINA_HOME/conf/Catalina/localhost/solr4.xml

  echogreen "Setting permissions..."
  sudo chown -R $FLOW_USER:$FLOW_GROUP $CATALINA_HOME/webapps
  sudo chown -R $FLOW_USER:$FLOW_GROUP $FLOW_DATA_HOME/solr4
  sudo chown -R $FLOW_USER:$FLOW_GROUP $FLOW_HOME/solr4

  echo
  echogreen "Finished installing Solr4 engine."
  echored "Verify your setting in flowable-global.properties."
  echo "Set property value index.subsystem.name=solr4"
  echo
else
  echo
  echo "Skipping installing Solr4."
  echo "You can always install Solr4 at a later time."
  echo
fi

echo
echoblue "- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -"
echo "Flowable BART - Backup and Recovery Tool"
echo "Flowable BART is a backup and recovery tool for Flowable ECM. Is a shell script"
echo "tool based on Duplicity for Flowable backups and restore from a local file system,"
echo "FTP, SCP or Amazon S3 of all its components: indexes, data base, content store "
echo "and all deployment and configuration files."
echoblue "- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -"
read -e -p "Install B.A.R.T${ques} [y/n] " -i "$DEFAULTYESNO" installbart

if [ "$installbart" = "y" ]; then
 echogreen "Installing B.A.R.T"


 sudo mkdir -p $FLOW_HOME/scripts/bart
 sudo mkdir -p $FLOW_HOME/logs/bart
 sudo curl -# -o $TMP_INSTALL/$BART_PROPERTIES $BASE_BART_DOWNLOAD$BART_PROPERTIES
 sudo curl -# -o $TMP_INSTALL/$BART_EXECUTE $BASE_BART_DOWNLOAD$BART_EXECUTE

 # Update bart settings
 FLOWHOMEESCAPED="${FLOW_HOME//\//\\/}"
 BARTLOGPATH="$FLOW_HOME/logs/bart"
 FLOWBRTPATH="$FLOW_HOME/scripts/bart"
 INDEXESDIR="\$\{FLOW_DIRROOT\}/solr4"
 # Escape for sed
 BARTLOGPATH="${BARTLOGPATH//\//\\/}"
 FLOWBRTPATH="${FLOWBRTPATH//\//\\/}"
 INDEXESDIR="${INDEXESDIR//\//\\/}"

 sed -i "s/FLOW_INSTALLATION_DIR\=.*/FLOW_INSTALLATION_DIR\=$FLOWHOMEESCAPED/g" $TMP_INSTALL/$BART_PROPERTIES
 sed -i "s/FLOWBRT_LOG_DIR\=.*/FLOWBRT_LOG_DIR\=$BARTLOGPATH/g" $TMP_INSTALL/$BART_PROPERTIES
 sed -i "s/INDEXES_DIR\=.*/INDEXES_DIR\=$INDEXESDIR/g" $TMP_INSTALL/$BART_PROPERTIES
 sudo cp $TMP_INSTALL/$BART_PROPERTIES $FLOW_HOME/scripts/bart/$BART_PROPERTIES
 sed -i "s/FLOWBRT_PATH\=.*/FLOWBRT_PATH\=$FLOWBRTPATH/g" $TMP_INSTALL/$BART_EXECUTE
 sudo cp $TMP_INSTALL/$BART_EXECUTE $FLOW_HOME/scripts/bart/$BART_EXECUTE

 sudo chmod 700 $FLOW_HOME/scripts/bart/$BART_PROPERTIES
 sudo chmod 774 $FLOW_HOME/scripts/bart/$BART_EXECUTE

 # Install dependency
 sudo apt-get $APTVERBOSITY install duplicity;

 # Add to cron tab
 tmpfile=/tmp/crontab.tmp

 # read crontab and remove custom entries (usually not there since after a reboot
 # QNAP restores to default crontab: http://wiki.qnap.com/wiki/Add_items_to_crontab#Method_2:_autorun.sh
 sudo -u $FLOW_USER crontab -l | grep -vi "flowable-bart.sh" > $tmpfile

 # add custom entries to crontab
 echo "0 5 * * * $FLOW_HOME/scripts/bart/$BART_EXECUTE backup" >> $tmpfile

 #load crontab from file
 sudo -u $FLOW_USER crontab $tmpfile

 # remove temporary file
 rm $tmpfile

 # restart crontab
 sudo service cron restart

 echogreen "B.A.R.T Cron is installed to run in 5AM every day as the $FLOW_USER user"

fi

# Finally, set the permissions
sudo chown -R $FLOW_USER:$FLOW_GROUP $FLOW_HOME
if [ -d "$FLOW_HOME/www" ]; then
   sudo chown -R www-data:root $FLOW_HOME/www
fi

echo
echogreen "- - - - - - - - - - - - - - - - -"
echo "Scripted install complete"
echo
echored "Manual tasks remaining:"
echo
echo "1. Add database. Install scripts available in $FLOW_HOME/scripts"
echored "   It is however recommended that you use a separate database server."
echo
echo "2. Verify Tomcat memory and locale settings in the file"
if [ "$ISON1604" = "y" ]; then
echo "   $FLOW_HOME/flowable-service.sh."
else
echo "   /etc/init/flowable.conf."
fi
echo "   Flowable runs best with lots of memory. Add some more to \"lots\" and you will be fine!"
echo "   Match the locale LC_ALL (or remove) setting to the one used in this script."
echo "   Locale setting is needed for LibreOffice date handling support."
echo
echo "3. Update database and other settings in flowable-global.properties"
echo "   You will find this file in $CATALINA_HOME/shared/classes"
echored "   Really, do this. There are some settings there that you need to verify."
echo
echo "4. Update properties for BART (if installed) in $FLOW_HOME/scripts/bart/flowable-bart.properties"
echo "   DBNAME,DBUSER,DBPASS,DBHOST,REC_MYDBNAME,REC_MYUSER,REC_MYPASS,REC_MYHOST,DBTYPE "
echo
echo "5. Update cpu settings in $FLOW_HOME/scripts/limitconvert.sh if you have more than 2 cores."
echo
echo "6. Start nginx if you have installed it: sudo service nginx start"
echo
echo "7. Start Flowable/tomcat:"
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
