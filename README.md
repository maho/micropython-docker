# YAMPiD - Yet Another Micropython (Pycopy) in Docker - for ESP32

initially fork of https://github.com/derekenos/micropython-docker , but due do different
goals, now is rather kind of separate project. 

Docker environment to build, flash and configure webrepl in ESP32 board with Pycopy (fork
of micropython): https://github.com/pfalcon/pycopy


## Build firmware 

`make build` - build for pycopy
`make build FLAVOUR=micropython` - build for original micropython


## SSH Jumpstation

By default, this software access ESP32 via SSH jumpstation. 
Sometimes is not possible to connect ESP32 to your PC, because there is problem with
USB drivers (eg. on some MacOses). In such case, it's convenient to use SSH jumpstation.
Eg old laptop or RaspberryPI/BananaPi plugged to your network. 

There are following targets:

* `flash_esp32` - flash esp32 connected to ssh jumpstation (eg. raspberry pi)"
* `install_webrepl` - install webrepl on esp32 (via jumpstation) "
* `all` - flash and install webrepl via ssh jumpstation"
* `clean` - clean/reset information about instalation status 
* `reinstall_all` - flash and install webrepl once again

## Install locally connected ESP32 board. 

Use the same targets as above, but with `local_` prefix. So:

* `make local_flash_esp32`
* `make local_all`
* `make install_webrepl`
* ....


### Variables
You should modify at least `SSH_USER`, `SSH_HOST`, `WEBREPL_PASS`, `WIFI_SSID` and
`WIFI_PASS`. You can use them in make commandline, or write to `private.mk` file, which is
in .gitignore, so secrets won't land in git repository. 

Available parameters:

* `SSH_USER` - username on your SSH jumpstation,
* `SSH_HOST` - address of your SSH jumpstation,
* `SSH_KEY` - key to your SSH jumpstation, default is ~/.ssh/id_rsa (and usually default is ok)
* `WEBREPL_PASS` - password to webrepl in your ESP32. Don't forget to modify it, otherwise
            your installation will be insecure
* `WIFI_SSID` and `WIFI_PASS` - your esp32 will try to connect to wifi using these
            credentials. 
* `CMD_PREFIX` - prefix of `ampy` and `esptool.py` commands. If you have everything in
            $PATH, just leave it blank. If you have it in virtualenv, give
            `PI_PREFIX=/path/to/venv/bin/`
* `DEVICE` - device on ssh jumpstation side. Default is `/dev/ttyUSB`
* `AMPY_DELAY` - delay before calling ampy command. Default is 5. Make it bigger if you
            ecounter strange replies from your esp32 device
