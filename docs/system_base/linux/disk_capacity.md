# 磁盘添加及扩容

条件

- 对原有磁盘扩容
- 原有磁盘裸盘做了lvm

### 对磁盘扩容

对磁盘进行热扩容(Vmware虚拟机可能不支持开机扩容)，我们将磁盘sdb从5G扩容到了10G，但是可以看到vg的大小并没有扩大

```sh
[root@localhost ~]# fdisk -l /dev/sdb 

Disk /dev/sdb: 10.7 GB, 10737418240 bytes, 20971520 sectors
Units = sectors of 1 * 512 = 512 bytes
Sector size (logical/physical): 512 bytes / 512 bytes
I/O size (minimum/optimal): 512 bytes / 512 bytes

[root@localhost ~]# pvdisplay 
  --- Physical volume ---
  PV Name               /dev/sdb
  VG Name               vg00
  PV Size               5.00 GiB / not usable 4.00 MiB
  Allocatable           yes (but full)
  PE Size               4.00 MiB
  Total PE              1279
  Free PE               0
  Allocated PE          1279
  PV UUID               1yxy7F-Sfd4-O9JV-sSBJ-zaKn-Mryh-d5VYh0
   
  --- Physical volume ---
  PV Name               /dev/sda2
  VG Name               centos
  PV Size               <39.00 GiB / not usable 3.00 MiB
  Allocatable           yes 
  PE Size               4.00 MiB
  Total PE              9983
  Free PE               1
  Allocated PE          9982
  PV UUID               rJ2bWs-Vfx1-nMz1-NKbT-Rb6n-WTTn-roQokn

```



### 对PV进行扩容

可以看到pv的大小已经扩大

```sh
[root@localhost ~]# pvresize /dev/sdb 
  Physical volume "/dev/sdb" changed
  1 physical volume(s) resized or updated / 0 physical volume(s) not resized
[root@localhost ~]# pvdisplay 
  --- Physical volume ---
  PV Name               /dev/sdb
  VG Name               vg00
  PV Size               <10.00 GiB / not usable 3.00 MiB
  Allocatable           yes 
  PE Size               4.00 MiB
  Total PE              2559
  Free PE               1280
  Allocated PE          1279
  PV UUID               1yxy7F-Sfd4-O9JV-sSBJ-zaKn-Mryh-d5VYh0
   
  --- Physical volume ---
  PV Name               /dev/sda2
  VG Name               centos
  PV Size               <39.00 GiB / not usable 3.00 MiB
  Allocatable           yes 
  PE Size               4.00 MiB
  Total PE              9983
  Free PE               1
  Allocated PE          9982
  PV UUID               rJ2bWs-Vfx1-nMz1-NKbT-Rb6n-WTTn-roQokn
```



### 对VG进行扩容

```sh
[root@localhost ~]# vgextend vg00 /dev/sdb 
  Physical volume '/dev/sdb' is already in volume group 'vg00'
  Unable to add physical volume '/dev/sdb' to volume group 'vg00'
  /dev/sdb: physical volume not initialized.
[root@localhost ~]# vgdisplay 
  --- Volume group ---
  VG Name               vg00
  System ID             
  Format                lvm2
  Metadata Areas        1
  Metadata Sequence No  3
  VG Access             read/write
  VG Status             resizable
  MAX LV                0
  Cur LV                1
  Open LV               1
  Max PV                0
  Cur PV                1
  Act PV                1
  VG Size               <10.00 GiB
  PE Size               4.00 MiB
  Total PE              2559
  Alloc PE / Size       1279 / <5.00 GiB
  Free  PE / Size       1280 / 5.00 GiB
  VG UUID               BFJr5O-YLC4-K5N4-aNZE-imQq-OgdG-Enhf0h
```



### 对LV进行扩容

```sh
[root@localhost ~]# lvextend -l +100%FREE /dev/vg00/data
  Size of logical volume vg00/data changed from <5.00 GiB (1279 extents) to <10.00 GiB (2559 extents).
  Logical volume vg00/data successfully resized.
[root@localhost ~]# lvdisplay 
  --- Logical volume ---
  LV Path                /dev/vg00/data
  LV Name                data
  VG Name                vg00
  LV UUID                K46ODy-glFh-1XMV-xiUM-jXeB-aHp1-S8GzOi
  LV Write Access        read/write
  LV Creation host, time localhost.localdomain, 2020-08-20 15:04:42 +0800
  LV Status              available
  # open                 1
  LV Size                <10.00 GiB
  Current LE             2559
  Segments               1
  Allocation             inherit
  Read ahead sectors     auto
  - currently set to     8192
  Block device           253:2
```



### 重置文件大小

```sh
[root@localhost ~]# df -h
Filesystem               Size  Used Avail Use% Mounted on
devtmpfs                 898M     0  898M   0% /dev
tmpfs                    910M     0  910M   0% /dev/shm
tmpfs                    910M  9.6M  901M   2% /run
tmpfs                    910M     0  910M   0% /sys/fs/cgroup
/dev/mapper/centos-root   37G  1.2G   36G   4% /
/dev/sda1               1014M  150M  865M  15% /boot
tmpfs                    182M     0  182M   0% /run/user/0
/dev/mapper/vg00-data    4.8G   20M  4.6G   1% /data
[root@localhost ~]# resize2fs /dev/vg00/data
resize2fs 1.42.9 (28-Dec-2013)
Filesystem at /dev/vg00/data is mounted on /data; on-line resizing required
old_desc_blocks = 1, new_desc_blocks = 2
The filesystem on /dev/vg00/data is now 2620416 blocks long.

[root@localhost ~]# df -h
Filesystem               Size  Used Avail Use% Mounted on
devtmpfs                 898M     0  898M   0% /dev
tmpfs                    910M     0  910M   0% /dev/shm
tmpfs                    910M  9.6M  901M   2% /run
tmpfs                    910M     0  910M   0% /sys/fs/cgroup
/dev/mapper/centos-root   37G  1.2G   36G   4% /
/dev/sda1               1014M  150M  865M  15% /boot
tmpfs                    182M     0  182M   0% /run/user/0
/dev/mapper/vg00-data    9.8G   23M  9.3G   1% /data
```

