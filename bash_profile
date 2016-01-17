alias ll='ls -l --color'
alias dut='du --max-depth=1 -h'
alias vi=vim


export HADOOP_PREFIX=/usr/local/hadoop
export HADOOP_COMMON_HOME=/usr/local/hadoop
export HADOOP_HDFS_HOME=/usr/local/hadoop
export HADOOP_MAPRED_HOME=/usr/local/hadoop
export HADOOP_YARN_HOME=/usr/local/hadoop
export HADOOP_CONF_DIR=/usr/local/hadoop/etc/hadoop
export YARN_CONF_DIR=$HADOOP_PREFIX/etc/hadoop
export SPARK_HOME=/usr/local/spark
export MONGO_HOME=/usr/local/mongodb


export LANG=en_US.UTF-8
export PATH=$PATH:$SPARK_HOME/bin:$HADOOP_PREFIX/bin:$MONGO_HOME/bin