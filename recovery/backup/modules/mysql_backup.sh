#!/bin/bash

while [[ "$1" == --* ]]; do
  case "$1" in
  --schema-name)
    shift
    SCHEMA_NAME="$1"
    ;;
  --working-directory)
    shift
    WORK_DIR="$1"
    ;;
  --config-file)
    shift
    BACKUP_CONFIG_FILE="$1"
    ;;
  -h|--help)
    usage
    exit 0
    ;;
  --)
    shift
    break
    ;;
  esac
  shift
done
shift $(( OPTIND - 1 ))

source ${BACKUP_CONFIG_FILE}

#######################################################################################################################################################################
# MAIN
#######################################################################################################################################################################
DATE=`date +%Y-%m-%d_%Hh%Mm`
CPU_COUNT=`cat /proc/cpuinfo | grep "physical id" | wc -l`
OUTPUT_DIR=${MYSQL_BACKUP_FILE_PREFIX}_${SCHEMA_NAME}_${DATE}
CONNECTION_TYPE=mysql

/usr/bin/time /usr/bin/mydumper --database ${SCHEMA_NAME} --outputdir ${BACKUP_DIR}/${OUTPUT_DIR} --no-locks --use-savepoints --host ${HOST} --user ${APP_USER} --password ${APP_USER_PASSWORD} --threads ${CPU_COUNT} -v 3

/usr/bin/lz4 --rm -vm ${BACKUP_DIR}/${OUTPUT_DIR}/*
/usr/bin/tar -cvf ${BACKUP_DIR}/${OUTPUT_DIR}.tar ${BACKUP_DIR}/${OUTPUT_DIR}/
/usr/local/bin/aws s3 mv ${BACKUP_DIR}/${OUTPUT_DIR}.tar ${S3_BUCKET_NAME}/${S3_SUBDIR}/${CONNECTION_TYPE}/${OUTPUT_DIR}.tar
/usr/bin/rm -rfv ${BACKUP_DIR}/${OUTPUT_DIR}/
