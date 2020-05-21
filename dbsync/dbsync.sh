#!/bin/bash

source .dbsync_config

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
    sourceHost="$1"
    ;;
  --target-host)
    shift
    targetHost="$1"
    ;;
  --source-env)
    shift
    sourceEnv="$1"
    ;;
  --target-env)
    shift
    targetEnv="$1"
    ;;
  --database-name)
    shift
    databaseName="$1"
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

echo ""
echo ""
echo "---------------------------------------------------------------------------------"
echo "------------------------- DBSYNC ------------------------------------------------"
echo "---------------------------------------------------------------------------------"
echo "`date "+%D %T"`: Runtime: `date`"
echo "`date "+%D %T"`: Download Path: ${DOWNLOAD_PATH}"
echo "`date "+%D %T"`: Source Host: ${sourceHost}"
echo "`date "+%D %T"`: Target Host: ${targetHost}"
echo "`date "+%D %D"`: Database Name: ${databaseName}"
echo "`date "+%D %T"`: Source Environment Prefix: ${sourceEnv}"
echo "`date "+%D %T"`: Target Environment Prefix: ${targetEnv}"
echo "`date "+%D %T"`: Datetime: ${date}"

cd ${ROOT_PATH}
mkdir ${DOWNLOAD_PATH}/${tmpdir}
echo "`date "+%D %T"`: Downloading ${sourceEnv}_${databaseName} from ${sourceHost}"

time mydumper --host ${sourceHost} -u ${APP_USER} -p "${APP_USER_PASSWORD}" -v 3 --use-savepoints --no-locks --long-query-guard=${LONG_QUERY_GUARD_VAL} -B ${sourceEnv}_${databaseName} -o ${DOWNLOAD_PATH}/${tmpdir} -v 3 -t $CPU_COUNT # >> $ROOT_PATH/dbsync.log

echo "`date "+%D %T"`: Finished downloading ${sourceEnv}_${databaseName}"
mv ${DOWNLOAD_PATH}/${tmpdir} ${ROOT_PATH}/.data

echo "`date "+%D %T"`: Loading ${sourceHost} data"

myloader -o -h ${targetHost} -u ${APP_USER} -p "${APP_USER_PASSWORD}" -B tmp1_${targetEnv}_${databaseName} -d ${ROOT_PATH}/.data/${tmpdir}/ >> $ROOT_PATH/dbsync.log

echo "`date "+%D %T"`: Swap in new data"
mysql -v -h ${targetHost} -u ${APP_USER} --password="${APP_USER_PASSWORD}" -e "create database if not exists ${targetEnv}_${databaseName}"
sh ${MYSQL_DB_RENAME_PATH}/mysql_db_rename.sh ${targetEnv}_${databaseName} tmp2_${targetEnv}_${databaseName} ${targetHost} ${APP_USER} "${APP_USER_PASSWORD}"
sh ${MYSQL_DB_RENAME_PATH}/mysql_db_rename.sh tmp1_${targetEnv}_${databaseName} ${targetEnv}_${databaseName} ${targetHost} ${APP_USER} "${APP_USER_PASSWORD}"
mysql -v -h ${targetHost} -u ${APP_USER} --password="${APP_USER_PASSWORD}" -e "drop database if exists tmp1_${targetEnv}_${databaseName}; drop database if exists tmp2_${targetEnv}_${databaseName};"
echo "`date "+%D %T"`: Deleting temp files..."
rm -vrf ${ROOT_PATH}/.data/${tmpdir}

mysql -v -h ${sourceHost} -u ${APP_USER} --password="${APP_USER_PASSWORD}" -e "insert into application_logs(app_name, status, parameters, created_by) values ('dbsync', 'FINSIHED', 'sourceHost:${sourceHost}, targetHost:${targetHost}, sourceEnv:${sourceEnv}, targetEnv:${targetEnv}, databaseName:${databaseName}', '${APP_USER}')" internal
mysql -v -h ${targetHost} -u ${APP_USER} --password="${APP_USER_PASSWORD}" -e "insert into application_logs(app_name, status, parameters, created_by) values ('dbsync', 'FINSIHED', 'sourceHost:${sourceHost}, targetHost:${targetHost}, sourceEnv:${sourceEnv}, targetEnv:${targetEnv}, databaseName:${databaseName}', '${APP_USER}')" internal

echo "`date "+%D %T"`: Done!"
