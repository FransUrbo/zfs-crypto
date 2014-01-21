#!/bin/bash
#
# If ZED_EMAIL is defined, then send a mail notifying admin that a pool
# have had a data error.
#
test -f zed.rc && . ./zed.rc

NAME="zed.data.email"
LOCKFILE="${ZED_LOCKDIR:=/var/lock}/${NAME}.lock"
STATEFILE="${ZED_RUNDIR:=/var/run}/${NAME}.state"

exec 8> "${LOCKFILE}"
flock -x 8

# Only run if ZED_EMAIL has been configured.
test -n "${ZED_EMAIL}" || exit 0

(cat <<EOF
The ZFS pool '${ZEVENT_POOL}' have had a data error.

   eid: ${ZEVENT_EID}
  host: `hostname`
`${ZPOOL} status ${ZEVENT_POOL}`
EOF
) | mail -s "ZFS pool ${ZEVENT_POOL} have a data error `hostname`" ${ZED_EMAIL}
