#!/bin/bash
#
# If ZED_EMAIL is defined, then send a mail notifying admin that there's
# a vdev with have possible problems.
#
# This script is called in response to a 'probe_failure' subclass, which
# is issued when a vdev have read and/or write errors.
#
test -f zed.rc && . ./zed.rc

NAME="zed.probe_failure.email"
LOCKFILE="${ZED_LOCKDIR:=/var/lock}/${NAME}.lock"
STATEFILE="${ZED_RUNDIR:=/var/run}/${NAME}.state"

exec 8> "${LOCKFILE}"
flock -x 8

# Only run if ZED_EMAIL has been configured.
test -n "${ZED_EMAIL}" || exit 0

(cat <<EOF
A ZFS propbe failure have been detected. ${ZEVENT_VDEV_READ_ERRORS} read errors have
been detected on ${ZEVENT_VDEV_PATH}
with ${ZEVENT_VDEV_WRITE_ERRORS} write errors.

   eid: ${ZEVENT_EID}
  host: `hostname`
  pool: ${ZEVENT_POOL}
  vdev: ${ZEVENT_VDEV_PATH}
  time: ${ZEVENT_TIME_STRING}
`${ZPOOL} status ${ZEVENT_POOL}`
EOF
) | mail -s "ZFS Probe Failure for ${ZEVENT_POOL} on `hostname`" ${ZED_EMAIL}
