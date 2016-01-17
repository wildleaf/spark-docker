#!/bin/bash
export LANG="en_US.utf8"
alias ll='ls -l --color'
alias dut='du --max-depth=1 -h'

/etc/bootstrap_hadoop.sh

#start Mongo
[[ ! -d /data/db ]] && mkdir -p /data/db
$MONGO_HOME/bin/mongod &

# setting spark defaults
#echo spark.yarn.jar hdfs:///spark/spark-assembly-1.6.0-hadoop2.6.0.jar > $SPARK_HOME/conf/spark-defaults.conf
cp $SPARK_HOME/conf/metrics.properties.template $SPARK_HOME/conf/metrics.properties

cd $SPARK_HOME/sbin/
./start-master.sh
./start-slave.sh spark://$HOSTNAME:7077


CMD=${1:-"exit 0"}
if [[ "$CMD" == "-d" ]];
then
	service sshd stop
	/usr/sbin/sshd -D -d
else
	/bin/bash -c "$*"
fi