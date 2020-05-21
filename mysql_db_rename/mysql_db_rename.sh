#!/bin/bash

oldSchemaName=$1
newSchemaName=$2
host=$3
user=$4
password="$5"

#######################################################################################################################################################################
# FUNCTIONS
#######################################################################################################################################################################
function usage() {
    echo ""
    echo "usage: ./mysql_db_rename.sh --oldSchemaName oldSchemaName --newSchemaName newSchemaName --host localhost --user jdoe --password pass"
    echo "  --oldSchemaName
  			--newSchemaName
  			--host
  			--user
  			--password
  			"
    echo "--help, -h: Help text"
    echo ""
    exit
}

function mysqlCheck() {
	if ! type mysql > /dev/null || ! type mysqldump > /dev/null; then
		echo "MySQL Client Programs (specifically 'mysql' and 'mysqldump') are required to run mysql_db_rename. Please download and install them."
		echo "Link: https://dev.mysql.com/doc/refman/5.7/en/programs-client.html"
		exit
	else 
		echo "Client programs mysql and mysqldump found!"
	fi
}

function renameEvents() {
	oldSchemaName=$1
	newSchemaName=$2
	host=$3
	user=$4
	password="$5"
	for event in $(mysql -h $host -u $user --password="$5" -s -N -e "select event_name from information_schema.events where event_schema='${oldSchemaName}'"); do
	  echo "Moving ${event} to new db"
	  mysql -h $host -u $user --password="$password" --verbose -e "ALTER EVENT ${oldSchemaName}.${event} RENAME TO ${newSchemaName}.${event}"
	done
}

function getTriggers() {
	oldSchemaName=$1
	newSchemaName=$2
	host=$3
	user=$4
	password="$5"
	for trigger in $(mysql -h $host -u $user --password="$password" -s -N -e "select trigger_name from information_schema.triggers where trigger_schema='${oldSchemaName}'"); do	  
          echo "Dumping ${trigger} to ${newSchemaName}_triggers.sql"
	  mysqldump --login-path=${loginPath} --verbose --no-data --no-create-info --skip-opt --triggers --ignore-error --add-drop-table=FALSE ${oldSchemaName} >> ${newSchemaName}_triggers.sql
	  mysql -h $host -u $user --password="$password" --verbose -e "DROP TRIGGER ${oldSchemaName}.${trigger}"
	done
}

function loadTriggers() {
	oldSchemaName=$1
    newSchemaName=$2
    host=$3
	user=$4
	password="$5"
	if [ -f ${newSchemaName}_triggers.sql ]; then
  	  mysql -h $host -u $user --password="$password" --verbose ${newSchemaName} < ${newSchemaName}_triggers.sql
	else
	  echo "No triggers file"
	fi
}

function renameProcedures() {
	oldSchemaName=$1
	newSchemaName=$2
	host=$3
	user=$4
	password="$5"
	for proc in $(mysql -h $host -u $user --password="$password" -s -N -e "select name from mysql.proc where db='${oldSchemaName}'"); do
	  echo "Moving ${proc} to new db"
	  mysql -h $host -u $user --password="$password" --verbose -e "UPDATE mysql.proc SET db='${newSchemaName}' WHERE name='${proc}' and db='${oldSchemaName}'"
	done
}

function getViews() {
	oldSchemaName=$1
    newSchemaName=$2
    host=$3
	user=$4
	password="$5"
        for view in $(mysql -h $host -u $user --password="$password" -s -N -e "select table_name from information_schema.views where table_schema='${oldSchemaName}'"); do
          echo "Dumping ${view} to ${newSchemaName}_views.sql"
	  mysqldump -h $host -u $user --password="$password" --add-drop-table=FALSE --verbose ${oldSchemaName} ${view} >> ${newSchemaName}_views.sql
	  mysql -h $host -u $user --password="$5" -e "drop table ${oldSchemaName}.${view}"
        done
}

function loadViews() {
	oldSchemaName=$1
    newSchemaName=$2
    host=$3
	user=$4
	password="$5"
	if [ -f ${newSchemaName}_views.sql ]; then
	  mysql -h $host -u $user --password="$password" --verbose ${newSchemaName} < ${newSchemaName}_views.sql
	else
	  echo "No views file"
	fi
}

function renameTables() {
	oldSchemaName=$1
	newSchemaName=$2
	host=$3
	user=$4
	password="$5"
	for table in $(mysql -h $host -u $user --password="$password" -s -N -e "select table_name from information_schema.tables where table_schema='${oldSchemaName}' and table_type='BASE TABLE'"); do
	  echo "Moving Table: ${table}"
	  mysql -h $host -u $user --password="$5" --verbose -e "RENAME TABLE ${oldSchemaName}.${table} TO ${newSchemaName}.${table}"
 	done
}

function renameDb() {
	oldSchemaName=$1
	newSchemaName=$2
	host=$3
	user=$4
	password="$5"

	mysql -v -h $host -u $user --password="$password" --verbose -e "CREATE DATABASE ${newSchemaName}"

	echo "Dump Views"
	getViews $oldSchemaName $newSchemaName $host $user "$password"
	echo "Dump Triggers"
	getTriggers $oldSchemaName $newSchemaName $host $user "$password"
	echo "Move Tables"
	renameTables $oldSchemaName $newSchemaName $host $user "$password"
	echo "Move Procs"
	renameProcedures $oldSchemaName $newSchemaName $host $user "$password"
	echo "Move Events"
	renameEvents $oldSchemaName $newSchemaName $host $user "$password"
	echo "Load Views"
    loadViews $oldSchemaName $newSchemaName $host $user "$password"
	echo "Load Triggers"
	loadTriggers $oldSchemaName $newSchemaName $host $user "$password"
	mysql -h $host -u $user --password="$5" --verbose -e "DROP DATABASE ${oldSchemaName}"	
	echo "Done!"
}

function cleanupFiles() {
	newSchemaName=$1
	if [ ! -d ./dumped_db_objects ]; then
	  mkdir dumped_db_objects
	fi
	if [ -f "${newSchemaName}_views.sql" ]; then
	  mv ${newSchemaName}_views.sql ./dumped_db_objects/${newSchemaName}_views_`date +%s`.sql
	elif [ -f "${newSchemaName}_triggers.sql" ]; then 
	  mv ${newSchemaName}_triggers.sql ./dumped_db_objects/${newSchemaName}_triggers_`date +%s`.sql
	fi
}

#######################################################################################################################################################################
# MAIN
#######################################################################################################################################################################
#while [[ "$1" == --* ]]; do
#  case "$1" in
#  --old)
#    shift
#    oldSchemaName="$1"
#    ;;
#  --new)
#    shift
#    newSchemaName="$1"
#    ;;
#  --host)
#    shift
#    host="$1"
#    ;;
#  --user)
#    shift
#    user="$1"
#    ;;
#  --password)
#    shift
#    password="$1"
#    ;;
#  -h|--help)
#    usage
#    exit 0
#    ;;
#  --)
#    shift
#    break
#    ;;
#  esac
#  shift
#done
#shift $(( OPTIND - 1 ))

# Check if MySQL Client Programs are installed
mysqlCheck

# Run
renameDb ${oldSchemaName} ${newSchemaName} ${host} ${user} "${password}"
cleanupFiles ${newSchemaName}
