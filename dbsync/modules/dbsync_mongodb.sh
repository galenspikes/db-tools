#!/bin/bash

source ../config

date=`date +%Y%m%d_%Hh%Mm%Ss`
uuid=`date +%N%s`
tmpdir=tmp_${uuid}
CPU_COUNT=`cat /proc/cpuinfo | grep "physical id" | sort -u | wc -l`

function usage() {
  echo "
  --source-host
  --target-host
  --source-env
  --target-env
  --database-name
  -h|--help
  "
}

while [[ "$1" == --* ]]; do
  case "$1" in
  --source-host)
    shift
    source_host="$1"
    ;;
  --target-host)
    shift
    target_host="$1"
    ;;
  --source-env)
    shift
    source_env="$1"
    ;;
  --target-env)
    shift
    target_env="$1"
    ;;
  --database-name)
    shift
    database_name="$1"
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


# mongodump
mongodump --host=${source_host} --username=${APP_USER} --password="${APP_USER_PASSWORD}" --db=${source_env}_${database_name} --authenticationDatabase=${MONGODB_AUTH_DB} --out=${DOWNLOAD_PATH}/${tmpdir}

echo "`date "+%D %T"`: Finished downloading ${source_env}_${database_name}"
mv ${DOWNLOAD_PATH}/${tmpdir} ${ROOT_PATH}/.data
mv ${ROOT_PATH}/.data/${tmpdir}/${source_env}_${database_name} ${ROOT_PATH}/.data/${tmpdir}/${target_env}_${database_name}

# mongorestore to tmp1
mongorestore --host=${target_host} --username=${APP_USER} --password="${APP_USER_PASSWORD}" --authenticationDatabase=${MONGODB_AUTH_DB} --dir=${ROOT_PATH}/.data/${tmpdir}

echo "------------- FINISHED! ------------------"
