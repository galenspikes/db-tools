#!/bin/bash

# check if config exists or else exit
if test -f "../config"; then
  echo "config exists, continue"
else
  echo "config does not exist, please create or configure properly"
  exit
fi

source ../config

date=`date +%Y%m%d_%Hh%Mm%Ss`
uuid=`date +%N%s`
tmpdir=tmp_${uuid}

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
shift $(( OPTIND - 1 ))

tmp1_target_db=tmp1_${target_env}_${database_name}
tmp2_target_db=tmp2_${target_env}_${database_name}
home_dir=`echo ~`

# check if .pgpass exists or else exit
if test -f "${home_dir}/.pgpass"; then
  echo ".pgpass exists, continue."
  if grep -q ${APP_USER} "${home_dir}/.pgpass"; then
    echo "${APP_USER} entry found in .pgpass, continue"
  else
    echo "${APP_USER} entry not found in .pgpass. Please configure properly"
    echo "Documentation: https://www.postgresql.org/docs/12/libpq-pgpass.html"
    exit
  fi
else
  echo ".pgpass does not exist. Please create and configure."
  echo "Documentation: https://www.postgresql.org/docs/12/libpq-pgpass.html"
  exit
fi

# pg_dump db
pg_dump --host=${source_host} --username=${APP_USER} --dbname=${source_env}_${database_name} --format=c > ${DOWNLOAD_PATH}/${tmpdir}

echo "`date "+%D %T"`: Finished downloading ${source_env}_${database_name}"
mv ${DOWNLOAD_PATH}/${tmpdir} ${ROOT_PATH}/.data

psql -h ${target_host} -U ${APP_USER} -c "select pg_terminate_backend(pid) from pg_stat_activity where datname='${tmp1_target_db}'" postgres
psql -h ${target_host} -U ${APP_USER} -c "drop database if exists ${tmp1_target_db}" postgres
psql -h ${target_host} -U ${APP_USER} -c "create database ${tmp1_target_db}" postgres
pg_restore --host=${target_host} --username=${APP_USER} --dbname=${tmp1_target_db} ${ROOT_PATH}/.data/${tmpdir}

# rename (swap) - might need to kill connections
swap_out_query_0="select pg_terminate_backend(pid) from pg_stat_activity where datname='${target_env}_${database_name}'"
swap_out_query_1="alter database ${target_env}_${database_name} rename to ${tmp2_target_db}"
swap_in_query_0="select pg_terminate_backend(pid) from pg_stat_activity where datname='${tmp1_target_db}'"
swap_in_query_1="alter database ${tmp1_target_db} rename to ${target_env}_${database_name}"
drop_old_db_query="select pg_terminate_backend(pid) from pg_stat_activity where datname='${tmp2_target_db}'"
psql -h ${target_host} -U ${APP_USER} -c "${swap_out_query_0}" postgres
psql -h ${target_host} -U ${APP_USER} -c "${swap_out_query_1}" postgres
psql -h ${target_host} -U ${APP_USER} -c "${swap_in_query_0}" postgres
psql -h ${target_host} -U ${APP_USER} -c "${swap_in_query_1}" postgres
psql -h ${target_host} -U ${APP_USER} -c "${drop_old_db_query}" postgres
dropdb -h ${target_host} -U ${APP_USER} ${tmp2_target_db}

echo "---- FINISHED! ------"
echo "Target Database: ${target_env}_${database_name} on ${target_host}"
echo date
psql -h ${target_host} -U ${APP_USER} -c "SELECT schemaname,relname,n_live_tup FROM pg_stat_user_tables ORDER BY n_live_tup DESC" ${target_env}_${database_name}
