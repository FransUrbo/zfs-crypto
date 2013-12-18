This is my combination and collection of patches to
ZoL.

Some are my own, some are others that I needed and/or
wanted for various reasons.


The base is latest ZoL/master and ZFS-Crypto/0.6.3.

  Fix z_sync_cnt decrement in zfs_close
  https://github.com/zfsonlinux/zfs/pull/1981

  Tuning setting to ignore read/checksum errors when sending data.
  https://github.com/zfsonlinux/zfs/pull/1983

  ZoL #1886, Illumos #4322 (ZFS deadlock on dp_config_rwlock)
  https://github.com/zfsonlinux/zfs/pull/1887

  Add I/O Read/Write Accounting
  https://github.com/zfsonlinux/zfs/pull/1872

  Fixes #1841 : add missing libzfs_core to some Makefiles
  https://github.com/zfsonlinux/zfs/pull/1878

  iSCSI support for ZoL
  https://github.com/zfsonlinux/zfs/pull/1099

  Some SMBFS rewrites
  https://github.com/zfsonlinux/zfs/pull/1476
