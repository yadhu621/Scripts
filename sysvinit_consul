#!/bin/sh
#
# Manage the consul agent.
# chkconfig: - 99 01
#
# description: Agent component of the consul framework.
# processname: consul
# config: /etc/consul.d/server/config.json
# pidfile: /var/run/consul.pid

### BEGIN INIT INFO
# Provides: consul
# Required-Start: $all
# Required-Stop: $all
# Default-Start: 2 3 4 5
# Default-Stop: 0 1 6
# Short-Description: Startup script for the consul agent.
# Description: Agent component of the consul framework.
### END INIT INFO

# Source function library
. /etc/init.d/functions

prog="consul"
user="consul"
exec="/usr/local/bin/$prog"
pidfile="/var/run/${prog}.pid"
lockfile="/var/lock/subsys/$prog"
logfile="/var/log/$prog.log"
config="/etc/consul.d/server/config.json"


start() {
    [ -x $exec ] || exit 5
    [ -f $config ] || exit 6

    touch $logfile $pidfile
    chown $user:$user $logfile $pidfile

    echo -n $"Starting $prog: "

    daemon \
        --pidfile=$pidfile \
        --user=$user \
        " { $exec agent -ui -config-dir=$config &>> $logfile & } ; echo \$! >| $pidfile "

    retval=$?
    echo

    [ $retval -eq 0 ] && touch $lockfile
    return $retval
}

stop() {
    echo -n $"Shutting down $prog: "
    # graceful shutdown with SIGINT
    killproc -p $pidfile $exec -INT
    retval=$?
    echo
    [ $retval -eq 0 ] && rm -f $lockfile
    return $retval
}

restart() {
    stop
    start
}

reload() {
    echo -n $"Reloading $prog: "
    killproc -p $pidfile $exec -HUP
    echo
}

rh_status() {
    status -p "$pidfile" -l $prog $exec
}

rh_status_q() {
    rh_status >/dev/null 2>&1
}

case "$1" in
    start)
        rh_status_q && exit 0
        $1
        ;;
    stop)
        rh_status_q || exit 0
        $1
        ;;
    restart)
        $1
        ;;
    reload)
        rh_status_q || exit 7
        $1
        ;;
    status)
        rh_status
        ;;
    *)
        echo $"Usage: $0 {start|stop|status|restart|reload}"
        exit 2
esac

exit $?
