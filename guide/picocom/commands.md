# basics
```bash
picocom [options] /dev/tty[x]
```

# permissions
add user to group
```bash
sudo usermod -aG uucp $USER
```

# common options
`-b 115200` — baud rate

`--parity even|odd|none` — parity

`--flow rtscts|xonxoff|none` — flow control

`--omap crcrlf|crlf|igncr|lfcr|lfcrlf` — output mapping

`--imap ignlf` — ignore extraneous LF

`--noreset` — do not reset port on exit

# example command
picocom --imap lfcrlf /dev/ttyUSB0 -b 921600