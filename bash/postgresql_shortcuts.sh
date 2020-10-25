DEBUG_LEVEL=${DEBUG_LEVEL-0}
if [ "$DEBUG_LEVEL" -gt 0 ]; then
    echo "[level:$DEBUG_LEVEL] SOURCING $BASH_SOURCE FROM $@..."
fi

export DATABASE_NAME=${DATABASE_NAME-project_data}

alias pgcmd='pg_ctl -l $POSTGRES_LOG_FILENAME -D $POSTGRES_DATA_DIRECTORY -o "-c unix_socket_permissions=0700 -c unix_socket_directories="$POSTGRES_SOCKET_DIRECTORY '
alias start-database='pgcmd start'
alias stop-database='pgcmd stop'
alias connect-database='psql -h $POSTGRES_SOCKET_DIRECTORY -d $DATABASE_NAME -p $POSTGRES_PORT'

function reload-postgres-environment() {
    set -x
    export DATABASE_DIRECTORY=${DATABASE_DIRECTORY-$PWD/database}
    export DATABASE_USER=${DATABASE_USER-$USER}
    export POSTGRES_LOG_FILENAME=${DATABASE_DIRECTORY}/pg.log
    export POSTGRES_DATA_DIRECTORY=${DATABASE_DIRECTORY}/pg-data
    export POSTGRES_SOCKET_DIRECTORY=${DATABASE_DIRECTORY}/pg-sock
    export POSTGRES_PORT=5432
    set +x
}

function ensure-database-directory() {
  if [ ! -e $DATABASE_DIRECTORY ]; then
      echo " - creating database directory in ${DATABASE_DIRECTORY}..."
      mkdir -p $DATABASE_DIRECTORY
  fi
  mkdir -p $POSTGRES_SOCKET_DIRECTORY $POSTGRES_DATA_DIRECTORY
}

function replace-postgresql-conf-port() {
    case $# in
        2)
            export POSTGRES_PORT=$2
            conf_path=$1
            ;;
        1)
            export POSTGRES_PORT=$1
            conf_path=$POSTGRES_DATA_DIRECTORY/postgresql.conf
            ;;
        *)
            echo "need at least a port"
            return
    esac
    if [ ! -e $conf_path ]; then
        echo "ERROR: no postgres.conf at $conf_path"
        return
    fi
    set -x
    sed -i.bak \
        -e "s|^#port *=.*|port = $POSTGRES_PORT|" \
        $conf_path
    # -e "s|#unix_socket_directories *=.*|unix_socket_directories = $POSTGRES_SOCKET_DIRECTORY|" \
    set +x
    ls -lrt $conf_path*
}

function init-database() {
    case $1 in
        *[!0-9]*)
            echo "override port must be a number but given: $1"
            return
            ;;
        *)
            override_port=$1
            ;;
    esac
    reload-postgres-environment
    ensure-database-directory
    initdb $POSTGRES_DATA_DIRECTORY
    if [ "x$override_port" != "x" ]; then
        echo overriding port to $override_port...
        replace-postgresql-conf-port $override_port
    fi
    start-database
    createdb -h $POSTGRES_SOCKET_DIRECTORY -p $POSTGRES_PORT $DATABASE_NAME
}

function create-database-user() {
    createuser -h $POSTGRES_SOCKET_DIRECTORY -p $POSTGRES_PORT $DATABASE_USER
}

