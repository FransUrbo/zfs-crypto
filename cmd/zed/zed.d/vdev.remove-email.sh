#!/bin/bash
#
# If ZED_EMAIL is defined, then send a mail notifying admin that a vdev
# have been removed from the pool.
#
# This script is called in response to a 'vdev.remove' subclass, which
# is issued when a vdev is removed.
#
test -f zed.rc && . ./zed.rc

NAME="zed.vdev.remove.email"
LOCKFILE="${ZED_LOCKDIR:=/var/lock}/${NAME}.lock"
STATEFILE="${ZED_RUNDIR:=/var/run}/${NAME}.state"

exec 8> "${LOCKFILE}"
flock -x 8

# Only run if ZED_EMAIL has been configured.
test -n "${ZED_EMAIL}" || exit 0

(cat <<EOF
A ${ZEVENT_VDEV_TYPE} (`basename ${ZEVENT_VDEV_PATH}`)
have been removed from '${ZEVENT_POOL}'.

   eid: ${ZEVENT_EID}
  host: `hostname`
`${ZPOOL} status ${ZEVENT_POOL}`
EOF
) | mail -s "ZFS removed vdev in ${ZEVENT_POOL} on `hostname`" ${ZED_EMAIL}
