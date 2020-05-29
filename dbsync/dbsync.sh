#!/bin/bash

working_directory=`pwd`

function usage() {
  echo "
  --source-host
  --target-host
  --source-env
  --target-env
  --database-name
  --conn-type
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
  --conn-type)
    shift
    conn_type="$1"
    ;;
  --schema-only)
   shift
   schema_only=true
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


echo "Syncing ${conn_type} - ${database_name}"

if [ ${conn_type} = "mysql" ]; then
  ${working_directory}/modules/dbsync_mysql.sh --source-host ${source_host} --target-host ${target_host} --source-env ${source_env} --target-env ${target_env} --database-name ${database_name}  
elif [ ${conn_type} = "postgresql" ]; then
  ${working_directory}/modules/dbsync_postgresql.sh --source-host ${source_host} --target-host ${target_host} --source-env ${source_env} --target-env ${target_env} --database-name ${database_name}
elif [ ${conn_type} = "mongodb" ]; then
  ${working_directory}/modules/dbsync_mongodb.sh --source-host ${source_host} --target-host ${target_host} --source-env ${source_env} --target-env ${target_env} --database-name ${database_name}
else
  echo "Don\'t forget to define the connection type."
  echo "--conn-type mysql/mongodb/postgresql"
fi

