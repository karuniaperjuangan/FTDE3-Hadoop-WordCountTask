add-apt-repository -y ppa:openjdk-r/ppa
apt-get -y update
apt install -y openjdk-11-jdk

#Creating a new rsa key pair with empty password
ssh-keygen -t rsa -P "" -f ~/.ssh/id_rsa <<< y

# See id_rsa.pub content
more /root/.ssh/id_rsa.pub

#Copying the key to autorized keys
cat $HOME/.ssh/id_rsa.pub > $HOME/.ssh/authorized_keys
#Changing the permissions on the key
chmod 0600 ~/.ssh/authorized_keys

#Conneting with the local machine
ssh -o StrictHostKeyChecking=no localhost uptime

export JAVA_HOME="/usr/lib/jvm/java-11-openjdk-amd64"
export JRE_HOME="/usr/lib/jvm/java-11-openjdk-amd64/jre"
export PATH=:"$PATH:/usr/lib/jvm/java-11-openjdk-amd64/bin"

#Downloading Hadoop 3.4.1
wget https://dlcdn.apache.org/hadoop/common/hadoop-3.4.1/hadoop-3.4.1.tar.gz

#Untarring the file
sudo tar -xzf hadoop-3.4.1.tar.gz
#Removing the tar file
rm hadoop-3.4.1.tar.gz
export JAVA_HOME="/usr/lib/jvm/java-11-openjdk-amd64"
export PATH=:"$PATH:/usr/lib/jvm/java-11-openjdk-amd64/bin"

#Copying the hadoop files to user/local
cp -r hadoop-3.4.1/ /usr/local/
rm -r hadoop-3.4.1/
sed -i '/export JAVA_HOME=/a export JAVA_HOME=\/usr\/lib\/jvm\/java-11-openjdk-amd64' /usr/local/hadoop-3.4.1/etc/hadoop/hadoop-env.sh
export HADOOP_HOME="/usr/local/hadoop-3.4.1"

cat <<EOF > $HADOOP_HOME/etc/hadoop/core-site.xml
<?xml version="1.0" encoding="UTF-8"?>
<?xml-stylesheet type="text/xsl" href="configuration.xsl"?>
<!--
  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License. See accompanying LICENSE file.
-->

<!-- Put site-specific property overrides in this file. -->

<configuration>
  <property>
          <name>fs.defaultFS</name>
          <value>hdfs://localhost:9000</value>
          <description>Where HDFS NameNode can be found on the network</description>
  </property>
</configuration>
EOF

cat <<EOF > $HADOOP_HOME/etc/hadoop/hdfs-site.xml
<?xml version="1.0" encoding="UTF-8"?>
<?xml-stylesheet type="text/xsl" href="configuration.xsl"?>
<!--
  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License. See accompanying LICENSE file.
-->

<!-- Put site-specific property overrides in this file. -->

<configuration>
<property>
    <name>dfs.replication</name>
    <value>1</value>
  </property>

</configuration>
EOF

cat <<EOF > $HADOOP_HOME/etc/hadoop/mapred-site.xml
<?xml version="1.0"?>
<?xml-stylesheet type="text/xsl" href="configuration.xsl"?>
<!--
  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License. See accompanying LICENSE file.
-->

<!-- Put site-specific property overrides in this file. -->

<configuration>
<property>
    <name>mapreduce.framework.name</name>
    <value>yarn</value>
  </property>
  <property>
    <name>mapreduce.application.classpath</name>
    <value>$HADOOP_HOME/share/hadoop/mapreduce/*:$HADOOP_HOME/share/hadoop/mapreduce/lib/*</value>
  </property>

</configuration>
EOF

cat <<EOF > $HADOOP_HOME/etc/hadoop/yarn-site.xml
<?xml version="1.0"?>
<!--
  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License. See accompanying LICENSE file.
-->
<configuration>
<property>
    <description>The hostname of the RM.</description>
    <name>yarn.resourcemanager.hostname</name>
    <value>localhost</value>
  </property>
  <property>
    <name>yarn.nodemanager.aux-services</name>
    <value>mapreduce_shuffle</value>
  </property>
  <property>
    <name>yarn.nodemanager.env-whitelist</name>
    <value>JAVA_HOME,HADOOP_COMMON_HOME,HADOOP_HDFS_HOME,HADOOP_CONF_DIR,CLASSPATH_PREPEND_DISTCACHE,HADOOP_YARN_HOME,HADOOP_HOME,PATH,LANG,TZ,HADOOP_MAPRED_HOME</value>
  </property>

<!-- Site specific YARN configuration properties -->
<property>
  <name>yarn.nodemanager.disk-health-checker.max-disk-utilization-per-disk-percentage</name>
  <value>98.5</value>
</property>
</configuration>
EOF

export HDFS_NAMENODE_USER="root"
export HDFS_DATANODE_USER="root"
export HDFS_SECONDARYNAMENODE_USER="root"
export YARN_RESOURCEMANAGER_USER="root"
export YARN_NODEMANAGER_USER="root"

$HADOOP_HOME/bin/hdfs namenode -format
#Launching hdfs deamons
$HADOOP_HOME/sbin/start-dfs.sh


#Launching yarn deamons
#nohup causes a process to ignore a SIGHUP signal
nohup $HADOOP_HOME/sbin/start-yarn.sh

#Listing the running deamons
jps

$HADOOP_HOME/bin/hdfs dfs -mkdir -p /word_count_with_python
$HADOOP_HOME/bin/hdfs dfs -put ./pembukaan_uud1945.txt /word_count_with_python


$HADOOP_HOME/bin/hdfs dfsadmin -report
chmod +x ./mapper.py 
chmod +x ./reducer.py

$HADOOP_HOME/bin/hadoop jar $HADOOP_HOME/share/hadoop/tools/lib/hadoop-streaming-3.4.1.jar \
  -input /word_count_with_python/pembukaan_uud1945.txt \
  -output /word_count_with_python/output8 \
  -mapper "python3 ./mapper.py" \
  -reducer "python3 ./reducer.py"

$HADOOP_HOME/bin/hdfs dfs -ls /word_count_with_python/output8
$HADOOP_HOME/bin/hdfs dfs -copyToLocal /word_count_with_python/output8/part-00000 ./hdfs-wordcount.txt