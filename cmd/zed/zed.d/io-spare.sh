#!/bin/bash
#
# Replace a device with a hot spare in response to IO or checksum errors.
# The following actions will be performed when the number of errors exceed
# the limit set by ZED_SPARE_ON_CHECKSUM_ERRORS.
#
# 1) FAULT or DEGRADE the offending device to prevent additional errors.
#
# 2) Set the fault beacon for the device if possible.
#
# 3) Replace the device with a hot spare if any are available.
#
# This script only provides the functionality for automatically kicking in
# a hot spare.  It does not provide any of the autoreplace functionality.
# This means that once the required repair is complete the hot spare must
# be manually retired using the 'zpool detach' command.
#
# Full support for autoreplace is planned, but it requires that the full
# ZFS Diagnosis Engine be ported.  In the meanwhile this script provides
# the majority of the expected hot spare functionality.
#
test -f zed.rc && . ./zed.rc
test -f zed.support && . ./zed.support

# Defaults to disabled, enable in the zed.rc file.
ZED_SPARE_ON_IO_ERRORS=${ZED_SPARE_ON_IO_ERRORS:-no}
ZED_SPARE_ON_CHECKSUM_ERRORS=${ZED_SPARE_ON_CHECKSUM_ERRORS:-0}

if ! check_boolean ${ZED_SPARE_ON_IO_ERRORS} &&
   [ ${ZED_SPARE_ON_CHECKSUM_ERRORS} -eq 0 ]; then
	exit 0
fi

# A lock file is used to serialize execution.
ZED_LOCKDIR=${ZED_LOCKDIR:-/var/lock}
LOCKFILE="${ZED_LOCKDIR}/zed.spare.lock"

exec 8> "${LOCKFILE}"
flock -x 8

# Given a <pool> and <device> return the status, (ONLINE, FAULTED, etc...).
vdev_status() {
	local POOL=$1
	local VDEV=`basename $2`

	${ZPOOL} status ${POOL} | awk -v pat="${VDEV}|${VDEV/-part?}" '$0 ~ pat { print $1" "$2 }'
	return 0
}

# Fault devices after N I/O errors.
if [ "${ZEVENT_CLASS}" = "ereport.fs.zfs.io" ]; then
	# We have I/O errors and we passed the ZED_SPARE_ON_IO_ERRORS
	# check earlier, so just fault!
	ACTION="fault"
# Degrade devices after N checksum errors.
elif [ "${ZEVENT_CLASS}" = "ereport.fs.zfs.checksum" ]; then
	ERRORS=${ZEVENT_VDEV_CKSUM_ERRORS}

	if [ ${ZED_SPARE_ON_CHECKSUM_ERRORS} -gt 0 -a \
	     ${ERRORS} -ge ${ZED_SPARE_ON_CHECKSUM_ERRORS} ]
	then
		ACTION="degrade"
	fi
else
	ACTION=
fi

if [ -n "${ACTION}" ]; then
	# Device is already FAULTED or DEGRADED
	set -- `vdev_status ${ZEVENT_POOL} ${ZEVENT_VDEV_PATH}`
	ZEVENT_VDEV_PATH_FOUND=$1
	STATUS=$2
	if [ "${STATUS}" = "FAULTED" -o "${STATUS}" = "DEGRADED" ]; then
		exit 0
	fi

	# FAULT or DEGRADE the device
	${ZINJECT} -d ${ZEVENT_VDEV_GUID} -A ${ACTION} ${ZEVENT_POOL}

	# FIXME: Set the 'fault' or 'ident' beacon for the device.  This can
	# be done through the sg_ses utility, the only hard part is to map
	# the sd device to its corresponding enclosure and slot.  We may
	# be able to leverage the existing vdev_id scripts for this.
	#
	# $ sg_ses --dev-slot-num=0 --set=ident /dev/sg3
	# $ sg_ses --dev-slot-num=0 --clear=ident /dev/sg3

	# Round robin through the spares selecting those which are available.
	for SPARE in ${ZEVENT_VDEV_SPARE_PATHS}; do
		set -- `vdev_status ${ZEVENT_POOL} ${SPARE}`
		SPARE_VDEV_FOUND=$1
		STATUS=$2
		if [ "${STATUS}" = "AVAIL" ]; then
			status=$(${ZPOOL} replace ${ZEVENT_POOL} \
			    ${ZEVENT_VDEV_GUID} ${SPARE_VDEV_FOUND} \
			    2>&1)
			result=$?

			if [ -n "${ZED_EMAIL}" ]; then
				if [ "$result" == 0 ]; then
					msg="
A ZFS pool have had a vdev replace. The spare '${SPARE_VDEV_FOUND}'
was used to replace the failing '${ZEVENT_VDEV_PATH_FOUND}'
in pool '${ZEVENT_POOL}'.
"
				else
					msg="
A ZFS pool have had a vdev failing. A hot spare was availible and
an attempt to replace the failing '${ZEVENT_VDEV_PATH_FOUND}'
with '${SPARE_VDEV_FOUND}' was unsuccessful.

The command line was:

${ZPOOL} replace ${ZEVENT_POOL} ${ZEVENT_VDEV_GUID} ${SPARE_VDEV_FOUND}

and it returned the error '$result' with the output message:

$status
"
				fi

				(cat <<EOF

$msg

   eid: ${ZEVENT_EID}
  host: `hostname`
`${ZPOOL} status ${ZEVENT_POOL}`
EOF
) | mail -s "ZFS Replace Finish for ${ZEVENT_POOL} on `hostname`" ${ZED_EMAIL}

				if [ "$result" == 0 ]; then
				    # We've successfully replaced the failed vdev
				    break
				fi
			fi
		fi
	done
fi

exit 0
