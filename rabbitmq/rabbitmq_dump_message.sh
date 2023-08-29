#!/bin/bash -xe

RMQ_CLI=$1
RMQ_HOST=$2
RMQ_PORT=$3
RMQ_VTHOST=$4
RMQ_USER=$5
RMQ_CREDENTIAL_FILE=$6
RMQ_PERL_SRC_QUEUE=$7
RMQ_PYTHON_DEST_QUEUE=$8
SPOOLER_PATH=$9
RMQ_WORKDIR=${10}

RMQ_PW=$(cat "$RMQ_CREDENTIAL_FILE") # get the rmq pw from credential file # we can also think to encode the pw and decode it within the script to have one more layer of security
RMQ_PAYLOAD_FILENAME=filename_$((100000 + RANDOM % 999999)) # generate random string - example filename_103010 picked up by python spooler based on filename prefix

RMQ_CALL="$RMQ_CLI --host $RMQ_HOST --port $RMQ_PORT --vhost=$RMQ_VTHOST --username=$RMQ_USER --password=$RMQ_PW --ssl --ssl-disable-hostname-verification -k"
CHECK_QUEUE_EXISTENCE=$($RMQ_CALL list queues | grep -w "$RMQ_PERL_SRC_QUEUE")

if [[ -z $CHECK_QUEUE_EXISTENCE ]]; then
  echo "$(date) rabbitmqadmin: Queue not defined on remote side/not possible to reach the broker to list the queues" >> /var/log/messages
  exit 0
fi

CHECK_NUMBER_OF_MESSAGES_QUEUE=$($RMQ_CALL list queues | grep -w "$RMQ_PERL_SRC_QUEUE" | awk '{print $4}') # get number of message sitting in the queue

if [[ $CHECK_NUMBER_OF_MESSAGES_QUEUE -gt 0 ]]; then
  for ((i = 0 ; i < CHECK_NUMBER_OF_MESSAGES_QUEUE ; i++ )); # for every cron execution spool as much messages already sitting in the queue instead of waiting for the next run
    do
	    # dump the payload from the message in ctenotify queue
	    $RMQ_CALL get queue="$RMQ_PERL_SRC_QUEUE" payload_file="$RMQ_WORKDIR/$RMQ_PAYLOAD_FILENAME" requeue=false encoding=auto # take the payload and save it to a temp directory before the queue substitution
	    sed -i 's/\<'"$RMQ_PERL_SRC_QUEUE"'\>/'"$RMQ_PYTHON_DEST_QUEUE"'/g' "$RMQ_WORKDIR"/$RMQ_PAYLOAD_FILENAME # change to destination python queue (will be consumed by the python app with the correct format)
	    mv "$RMQ_WORKDIR"/$RMQ_PAYLOAD_FILENAME "$SPOOLER_PATH"/$RMQ_PAYLOAD_FILENAME # mv to spooler workdir to be picked up by python spooler and sent to dest_python queue
      sleep 1 # sleep 1 second before dumping next message and moving to the dest directory
    done
else
	exit 0 # no messages in the queue
fi