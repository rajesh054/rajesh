#!/bin/bash
#zookeeper installation
#sudo su
cd /opt/

#installing zookeeper and extraction
sudo wget http://apache.org/dist/zookeeper/zookeeper-3.4.10/zookeeper-3.4.10.tar.gz
sudo tar xzxf zookeeper-3.4.10.tar.gz -C /opt/
sudo ln -s /opt/zookeeper-3.4.10 /opt/zookeeper
sudo cp /opt/zookeeper/conf/zoo_sample.cfg /opt/zookeeper/conf/zoo.cfg

#changing config in zoo.cfg
ip=$(
    ip route get 8.8.8.8 | awk 'NR==1 {print $NF}'
)
sudo echo "$ip"

sudo echo "server.1=$ip:2888:3888" >> /opt/zookeeper/conf/zoo.cfg

sed -i 's#/tmp/zookeeper#/var/lib/zookeeper#g' /opt/zookeeper/conf/zoo.cfg

#creating myid file
sudo mkdir -p /var/lib/zookeeper/
sudo touch /var/lib/zookeeper/myid
sudo echo "1" >> /var/lib/zookeeper/myid

#starting zookeeper
cd /opt/zookeeper/
#./bin/zkServer.sh start conf/zoo.cfg

sudo touch /etc/init.d/zookeeper
sudo chmod 744 /etc/init.d/zookeeper

sudo echo "#!/bin/bash
### BEGIN INIT INFO
# Provides:          kafka
# Required-Start:    \$local_fs \$remote_fs \$network \$syslog
# Required-Stop:     \$local_fs \$remote_fs \$network \$syslog
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: Startup script for Kafka server
# Description:       Kafka is a high-throughput distributed messaging system.
### END INIT INFO
#
# /etc/init.d/kafka
#
# Startup script for kafka
#
# chkconfig: 2345 20 80
# description: Starts and stops kafka

DAEMON_PATH=/opt/zookeeper/
PATH=\$PATH:\$DAEMON_PATH/bin

# See how we were called.
case \"\$1\" in
  start)
        # Start daemon.
        echo \"Starting Zookeeper\";
        nohup \$DAEMON_PATH/bin/zkServer.sh start /\$DAEMON_PATH/conf/zoo.cfg 2> /dev/null
        ;;
  stop)
        # Stop daemons.
        echo \"Shutting down Zookeeper\";
        pid=\`ps ax | grep -i 'org.apache.zookeeper.server' | grep -v grep | awk '{print \$1}'\`
        if [ -n \"\$pid\" ]
          then
          kill -9 \$pid
        else
          echo \"Zookeeper was not Running\"
        fi
        ;;
  restart)
        \$0 stop
        sleep 2
        \$0 start
        ;;
  status)
        pid=\`ps ax | grep -i 'org.apache.zookeeper.server' | grep -v grep | awk '{print \$1}'\`
        if [ -n \"\$pid\" ]
          then
          echo \"Zookeeper is Running as PID: \$pid\"
        else
          echo \"Zookeeper is not Running\"
        fi
        ;;
  *)
        echo \"Usage: \$0 {start|stop|resstart|status}\"
        exit 1
esac

exit 0 " >> /etc/init.d/zookeeper


#Updating Jdk 1.7 to 1.8 for solr

sudo yum install -y java-1.8.0-openjdk.x86_64

sudo /usr/sbin/alternatives --set java /usr/lib/jvm/jre-1.8.0-openjdk.x86_64/bin/java

sudo /usr/sbin/alternatives --set javac /usr/lib/jvm/jre-1.8.0-openjdk.x86_64/bin/javac

sudo yum remove java-1.7

# Installation of solr
cd /opt/
sudo wget https://archive.apache.org/dist/lucene/solr/6.4.0/solr-6.4.0.tgz
sudo tar xzf solr-6.4.0.tgz solr-6.4.0/bin/install_solr_service.sh --strip-components=2
sudo bash ./install_solr_service.sh solr-6.4.0.tgz
#sudo echo "server.1=$ip:2888:3888" >> /opt/zookeeper/conf/zoo.cfg


sed -i  "s/#ZK_HOST=\"\"/ZK_HOST=\"$ip:2181\"/" /etc/default/solr.in.sh
sed -i "s/#SOLR_HOST=/SOLR_HOST=/" /etc/default/solr.in.sh
sed -i -e "s/\(SOLR_HOST=\"\).*/\1$ip\"/" "/etc/default/solr.in.sh"



sudo service zookeeper restart
sudo service solr restart


