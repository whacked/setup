DEBUG_LEVEL=${DEBUG_LEVEL-0}
if [ "$DEBUG_LEVEL" -gt 0 ]; then
    echo "[level:$DEBUG_LEVEL] SOURCING $BASH_SOURCE FROM $@..."
fi

DATABASE_DIRECTORY=${DATABASE_DIRECTORY-$PWD/database}
export DATABASE_NAME=${DATABASE_NAME-project_data}
DATABASE_USER=${DATABASE_USER-$USER}

POSTGRES_LOG_FILENAME=${DATABASE_DIRECTORY}/pg.log
POSTGRES_DATA_DIRECTORY=${DATABASE_DIRECTORY}/pg-data
POSTGRES_SOCKET_DIRECTORY=${DATABASE_DIRECTORY}/pg-sock

alias pg_ctl_command="pg_ctl -l $POSTGRES_LOG_FILENAME -D $POSTGRES_DATA_DIRECTORY -o '-c unix_socket_permissions=0700 -c unix_socket_directories='$POSTGRES_SOCKET_DIRECTORY "
alias start-database="pg_ctl_command start"
alias stop-database="pg_ctl_command stop"
alias connect-database="psql -h $POSTGRES_SOCKET_DIRECTORY -d $DATABASE_NAME"

function ensure-database-directory() {
  if [ ! -e $DATABASE_DIRECTORY ]; then
      echo " - creating database directory in ${DATABASE_DIRECTORY}..."
      mkdir -p $DATABASE_DIRECTORY
  fi
  mkdir -p $POSTGRES_SOCKET_DIRECTORY $POSTGRES_DATA_DIRECTORY
}

function init-database() {
    ensure-database-directory
    initdb $POSTGRES_DATA_DIRECTORY
    start-database
    createdb -h $POSTGRES_SOCKET_DIRECTORY $DATABASE_NAME
}

function create-database-user() {
    createuser -h $POSTGRES_SOCKET_DIRECTORY $DATABASE_USER
}

