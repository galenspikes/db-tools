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
OUTPUT_DIR=${MONGODB_BACKUP_FILE_PREFIX}_${DATE}
CONNECTION_TYPE=mongodb

time mongodump --host=${HOST} --username=${APP_USER} --password="${APP_USER_PASSWORD}" --authenticationDatabase=${MONGODB_AUTH_DB} -o ${BACKUP_DIR}/${OUTPUT_DIR}

cd ${BACKUP_DIR}/${OUTPUT_DIR}
for dir in $(ls -d */ | sed 's#/##'); do
  tar --remove-files -cvf ${BACKUP_DIR}/${MONGODB_BACKUP_FILE_PREFIX}_${dir}_${DATE}.tar ${BACKUP_DIR}/${OUTPUT_DIR}/${dir}/*
  /usr/local/bin/aws s3 mv ${BACKUP_DIR}/${MONGODB_BACKUP_FILE_PREFIX}_${dir}_${DATE}.tar ${S3_BUCKET_NAME}/${S3_SUBDIR}/${CONNECTION_TYPE}/${MONGODB_BACKUP_FILE_PREFIX}_${dir}_${DATE}.tar
done

cd ${BACKUP_DIR}
rm -rf ${BACKUP_DIR}/${OUTPUT_DIR}

