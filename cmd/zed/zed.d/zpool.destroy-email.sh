#!/bin/bash
#
# If ZED_EMAIL is defined, then send a mail notifying admin that a pool
# have been destroyed.
#
# This script is called in response to a 'zpool.destroy' subclass, which
# is issued when a pool is destroyed.
#
test -f zed.rc && . ./zed.rc

NAME="zed.zpool.destroy.email"
LOCKFILE="${ZED_LOCKDIR:=/var/lock}/${NAME}.lock"
STATEFILE="${ZED_RUNDIR:=/var/run}/${NAME}.state"

exec 8> "${LOCKFILE}"
flock -x 8

# Only run if ZED_EMAIL has been configured.
test -n "${ZED_EMAIL}" || exit 0

(cat <<EOF
The ZFS pool '${ZEVENT_POOL}' have been destroyed.

   eid: ${ZEVENT_EID}
  host: `hostname`
EOF
) | mail -s "ZFS pool ${ZEVENT_POOL} destroyed on `hostname`" ${ZED_EMAIL}
