initdir = $(DEFAULT_INIT_DIR)
init_SCRIPTS = zfs-common zfs-mount zfs-share
zeddir = $(DEFAULT_INIT_DIR)
zed_SCRIPTS = zed

$(init_SCRIPTS):
	-$(SED) -e 's,@bindir\@,$(bindir),g' \
		-e 's,@sbindir\@,$(sbindir),g' \
		-e 's,@udevdir\@,$(udevdir),g' \
		-e 's,@udevruledir\@,$(udevruledir),g' \
		-e 's,@sysconfdir\@,$(sysconfdir),g' \
		-e 's,@initdir\@,$(initdir),g' \
		'$@.in' >'$@'

$(zed_SCRIPTS):
	-$(SED) -e 's,@bindir\@,$(bindir),g' \
		-e 's,@sbindir\@,$(sbindir),g' \
		-e 's,@udevdir\@,$(udevdir),g' \
		-e 's,@udevruledir\@,$(udevruledir),g' \
		-e 's,@sysconfdir\@,$(sysconfdir),g' \
		-e 's,@initdir\@,$(initdir),g' \
		'$@.in' >'$@'

distclean-local::
	-$(RM) $(init_SCRIPTS) $(zed_SCRIPTS)
