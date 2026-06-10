# amdgpu monitor system freeze

## recover gpu from freeze state

```bash
sudo cat /sys/kernel/debug/dri/1/amdgpu_gpu_recover
```

## attempt 1: dcdebugmask

> not working after toggle power saver

open config

```bash
sudo nano /etc/mkinitcpio.d/linux.preset
```

add flags or create `default_options`

```
default_options="amdgpu.runpm=0 amdgpu.dcdebugmask=0x10"
```

update

```bash
sudo mkinitcpio -P
```

reboot

## attempt 2: ppfeaturemask (arch btw)

open config

```bash
sudo nano /etc/kernel/cmdline
```

add this to the end of line

```
amdgpu.ppfeaturemask=0xfff73fff
```

rebuild .efi file

```bash
sudo mkinitcpio -P
```

reboot

checkout new param:

```bash
cat /proc/cmdline
```
