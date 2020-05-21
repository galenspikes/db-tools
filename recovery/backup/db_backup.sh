#!/bin/bash

function usage() {
    echo ""
    echo "Example: ./db_backup.sh --config-file=/home/postgres/config --connection-type=mysql"
    echo "--config-file=/path/to/config/file"
    echo "--connection-type=postgresql (mysql/postgresql/mongodb)"
    echo ""
    exit
}

while [[ "$1" == --* ]]; do
  case "$1" in
  --config-file)
    shift
    BACKUP_CONFIG_FILE="$1"
    ;;
  --connection-type)
    shift
    CONNECTION_TYPE="$1"
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

if [ "${BACKUP_CONFIG_FILE:0:1}" != "/" ]; then
  echo "Provide full absolute path for config-file"
  exit
fi

source ${BACKUP_CONFIG_FILE}
echo connection type: $CONNECTION_TYPE

#######################################
if [ ${CONNECTION_TYPE} = "mysql" ]; then
  for schema_name in $(mysql --host=${HOST} --user=${APP_USER} --password="${APP_USER_PASSWORD}" --silent --skip-column-names --execute="${MYSQL_SCHEMA_LOOKUP_QUERY}"); do
    time ${WORK_DIR}/modules/mysql_backup.sh --schema-name ${schema_name} --config-file ${BACKUP_CONFIG_FILE} --working-directory ${WORK_DIR}
  done
########################################
elif [ ${CONNECTION_TYPE} = "postgresql" ]; then
  for schema_name in $(psql -h ${HOST} -U ${APP_USER} -t -c "${POSTGRES_LOOKUP_QUERY}" postgres); do
     DATE=`date +%Y-%m-%d_%Hh%Mm`
     time ${WORK_DIR}/modules/postgresql_backup.sh --schema-name ${schema_name} --config-file ${BACKUP_CONFIG_FILE} --working-directory ${WORK_DIR}
     time /usr/bin/pg_dumpall --host=${HOST} --username=${APP_USER} --no-password --globals-only --file=${BACKUP_DIR}/${POSTGRESQL_BACKUP_FILE_PREFIX}_globals_${DATE}.sql
     time /usr/local/bin/aws s3 mv ${BACKUP_DIR}/${POSTGRESQL_BACKUP_FILE_PREFIX}_globals_${DATE}.sql ${S3_BUCKET_NAME}/${S3_SUBDIR}/${CONNECTION_TYPE}/${POSTGRESQL_BACKUP_FILE_PREFIX}_globals_${DATE}.sql
  done  
#######################################
elif [ ${CONNECTION_TYPE} = "mongodb" ]; then
  time ${WORK_DIR}/modules/mongodb_backup.sh --config-file ${BACKUP_CONFIG_FILE} --working-directory ${WORK_DIR}
else
  echo "Please enter valid connection type parameter: mysql, postgres, mongodb"
fi
