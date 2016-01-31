# Creates spark
#
# docker build -t wildleaf/spark .

#FROM sequenceiq/pam:centos-6.5
FROM tianon/centos:6.5
MAINTAINER Wildleaf

USER root

# install dev tools
RUN yum clean all; \
    rpm --rebuilddb; \
    yum install -y curl which tar sudo openssh-server openssh-clients rsync; \
    yum install -y glibc-common unzip
# update libselinux. see https://github.com/sequenceiq/hadoop-docker/issues/14
RUN yum update -y libselinux

# passwordless ssh
RUN ssh-keygen -q -N "" -t dsa -f /etc/ssh/ssh_host_dsa_key; \
	ssh-keygen -q -N "" -t rsa -f /etc/ssh/ssh_host_rsa_key; \
	ssh-keygen -q -N "" -t rsa -f /root/.ssh/id_rsa; \
	cp /root/.ssh/id_rsa.pub /root/.ssh/authorized_keys

# java
RUN curl -LO 'http://download.oracle.com/otn-pub/java/jdk/8u71-b14/jdk-8u71-linux-x64.rpm' -H 'Cookie: oraclelicense=accept-securebackup-cookie'; \
	rpm -i jdk-8u71-linux-x64.rpm; \
	rm jdk-8u71-linux-x64.rpm 

ENV JAVA_HOME /usr/java/default
ENV PATH $PATH:$JAVA_HOME/bin
RUN rm /usr/bin/java && ln -s $JAVA_HOME/bin/java /usr/bin/java

# download native support
RUN mkdir -p /tmp/native; \
	curl -L https://github.com/sequenceiq/docker-hadoop-build/releases/download/v2.7.1/hadoop-native-64-2.7.1.tgz | tar -xz -C /tmp/native

# hadoop
RUN curl -s http://www.apache.org/dist/hadoop/common/hadoop-2.7.1/hadoop-2.7.1.tar.gz | tar -xz -C /usr/local/; \
	cd /usr/local && ln -s ./hadoop-2.7.1 hadoop

ENV HADOOP_PREFIX=/usr/local/hadoop 
ENV HADOOP_COMMON_HOME=$HADOOP_PREFIX HADOOP_HDFS_HOME=$HADOOP_PREFIX HADOOP_MAPRED_HOME=$HADOOP_PREFIX HADOOP_YARN_HOME=$HADOOP_PREFIX HADOOP_CONF_DIR=$HADOOP_PREFIX/etc/hadoop 
ENV YARN_CONF_DIR=$HADOOP_CONF_DIR SPARK_HOME=/usr/local/spark MONGO_HOME=/usr/local/mongodb

RUN sed -i '/^export JAVA_HOME/ s:.*:export JAVA_HOME=/usr/java/default\nexport HADOOP_PREFIX=/usr/local/hadoop\nexport HADOOP_HOME=/usr/local/hadoop\n:' $HADOOP_PREFIX/etc/hadoop/hadoop-env.sh; \
	sed -i '/^export HADOOP_CONF_DIR/ s:.*:export HADOOP_CONF_DIR=/usr/local/hadoop/etc/hadoop/:' $HADOOP_PREFIX/etc/hadoop/hadoop-env.sh
#RUN . $HADOOP_PREFIX/etc/hadoop/hadoop-env.sh

RUN mkdir $HADOOP_PREFIX/input; \
	cp $HADOOP_CONF_DIR/*.xml $HADOOP_PREFIX/input

# pseudo distributed
COPY core-site.xml.template hdfs-site.xml mapred-site.xml yarn-site.xml $HADOOP_CONF_DIR/
RUN sed s/HOSTNAME/localhost/ $HADOOP_CONF_DIR/core-site.xml.template > $HADOOP_CONF_DIR/core-site.xml; \
	$HADOOP_PREFIX/bin/hdfs namenode -format

# fixing the libhadoop.so like a boss
RUN rm -rf /usr/local/hadoop/lib/native; \
	mv /tmp/native /usr/local/hadoop/lib

ADD ssh_config /root/.ssh/config
RUN chmod 600 /root/.ssh/config; \
	chown root:root /root/.ssh/config

# # installing supervisord
# RUN yum install -y python-setuptools
# RUN easy_install pip
# RUN curl https://bitbucket.org/pypa/setuptools/raw/bootstrap/ez_setup.py -o - | python
# RUN pip install supervisor
#
# ADD supervisord.conf /etc/supervisord.conf

COPY bootstrap_hadoop.sh bootstrap.sh /etc/
RUN chown root:root /etc/bootstrap*.sh; \
	chmod 700 /etc/bootstrap*.sh

#ENV BOOTSTRAP_HADOOP /etc/bootstrap_hadoop.sh
ENV BOOTSTRAP /etc/bootstrap.sh

# workingaround docker.io build error
RUN ls -la $HADOOP_CONF_DIR/*-env.sh; \
	chmod +x $HADOOP_CONF_DIR/*-env.sh; \
	ls -la $HADOOP_CONF_DIR/*-env.sh 

# fix the 254 error code
RUN sed  -i "/^[^#]*UsePAM/ s/.*/#&/"  /etc/ssh/sshd_config; \
	echo "UsePAM no" >> /etc/ssh/sshd_config; \
	echo "Port 2122" >> /etc/ssh/sshd_config

RUN service sshd start && $HADOOP_CONF_DIR/hadoop-env.sh && $HADOOP_PREFIX/sbin/start-dfs.sh && $HADOOP_PREFIX/bin/hdfs dfs -mkdir -p /user/root && $HADOOP_PREFIX/bin/hdfs dfs -put $HADOOP_CONF_DIR/ input

#support for Hadoop 2.6.0
#RUN curl -s http://d3kbcqa49mib13.cloudfront.net/spark-1.6.0-bin-hadoop2.6.tgz | tar -xz -C /usr/local/; \
RUN curl -s http://tasker.buzzsponge.com/spark/spark-1.6.0-bin-custom-spark.tgz | tar -xz -C /usr/local/; \
	cd /usr/local && ln -s spark-1.6.0-bin-custom-spark spark

#RUN mkdir $SPARK_HOME/yarn-remote-client
#ADD yarn-remote-client $SPARK_HOME/yarn-remote-client

#RUN $BOOTSTRAP && $HADOOP_PREFIX/bin/hadoop dfsadmin -safemode leave 
#&& $HADOOP_PREFIX/bin/hdfs dfs -put $SPARK_HOME/lib /spark

#Add MongoDB
RUN curl -s https://fastdl.mongodb.org/linux/mongodb-linux-x86_64-rhel62-3.2.1.tgz | tar -xz -C /usr/local/; \
	cd /usr/local && ln -s mongodb-linux-x86_64-rhel62-3.2.1 mongodb; \
	mkdir -p /data/db

ADD bash_profile /root/.bash_profile

ENV PATH $PATH:$SPARK_HOME/bin:$HADOOP_PREFIX/bin:$MONGO_HOME/bin

ENTRYPOINT ["/etc/bootstrap.sh"]

# Spark and Mongo ports
EXPOSE 8080 8081 7077 27017
# Hdfs ports
EXPOSE 50010 50020 50070 50075 50090 8020 9000
# Mapred ports
#EXPOSE 19888
#Yarn ports
#EXPOSE 8030 8031 8032 8033 8040 8042 8088
#Other ports
EXPOSE 49707 2122