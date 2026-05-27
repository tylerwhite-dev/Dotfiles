# amdgpu monitor system freeze

## attempt 1

> not working after toggle power saver

open config

```
sudo nano /etc/mkinitcpio.d/linux.preset
```

add flags or create `default_options`

```
default_options="amdgpu.runpm=0 amdgpu.dcdebugmask=0x10"
```

update

```
sudo mkinitcpio -P
```

reboot

## recover gpu from freeze state

```bash
sudo cat /sys/kernel/debug/dri/1/amdgpu_gpu_recover
```
