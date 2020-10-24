DC_FILE=docker-compose.yml
DOCKER_COMPOSE=docker-compose -f $(DC_FILE)
BRANCH=master
export FLAVOUR?=pycopy

ifeq ($(FLAVOUR), pycopy)
	REPO=https://github.com/pfalcon/pycopy.git
	# last working webrepl
	BRANCH=v3.2.2
else
	REPO=https://github.com/micropython/micropython
endif


help:
	@echo " make build - build firmware. available params: FLAVOUR and BRANCH"
	@echo "				FLAVOUR - can be either micropython or pycopy"
	@echo "				BRANCH - default master, you can override it while building"
	@echo " ## SSH JUMPSTATION ##"
	@echo " make flash_esp32 - flash esp32 connected to ssh jumpstation (eg. raspberry pi)"
	@echo " make install_webrepl - install webrepl on esp32 (via jumpstation) "
	@echo " make do_all - flash and install webrepl jumpstation"
	@echo ""
	@echo "Type make<TAB><TAB> to see all available targets"

up: 
	$(DOCKER_COMPOSE) up -d --no-build

down:
	$(DOCKER_COMPOSE) down

build:
	$(DOCKER_COMPOSE) build --build-arg repo=$(REPO) --build-arg branch=$(BRANCH) app
	# invalidate "downloaded from docker" target
	rm -f $(LFIRMWARE_PATH)

shell: up
	$(DOCKER_COMPOSE) exec app /bin/bash


# initialize device via ssh jumpstation
DOCKER_CONTAINER=`$(DOCKER_COMPOSE) ps -q app`
# firmware path in docker container
DFIRMWARE_PATH=/micropython/ports/esp32/build-GENERIC/firmware.bin
# firmware in local environment
LFIRMWARE_PATH=dist/$(FLAVOUR)-firmware.bin
# firmware in ssh environment
RFIRMWARE_PATH=/tmp/$(FLAVOUR)-firmware.bin


#
# temporary path to boot.py and webrepl_cfg.py with substituted password/etc
BOOT_PY=.deps/boot.py
# boot.py in remote/ssh env
RBOOT_PY=/tmp/boot.py

WEBREPL_CFG_PY=.deps/webrepl_cfg.py
# webrepl in remote/ssh
RWEBREPL_CFG_PY=/tmp/webrepl_cfg.py

SSH_USER=pi
SSH_HOST=bpii.home
SSH_KEY=~/.ssh/id_rsa
SSH_USERHOST=$(SSH_USER)@$(SSH_HOST)
SSH_CMD=ssh -i $(SSH_KEY) $(SSH_USERHOST) -t
SCP=scp -i $(SSH_KEY)

WEBREPL_PASS=foo
WIFI_SSID=wifissid
WIFI_PASS=wifikey

## CMD_XXX - commands on jumpstation or local machine, some linux. 
## DO_XXX - commands on remote machine 

# if empty - then will take command from path
# other possibilities
# CMD_PREFIX=/home/pi/venv/bin/
# or
# CMD_PREFIX=/usr/local/bin

CMD_PREFIX=
CMD_AMPY=$(CMD_PREFIX)ampy
CMD_ESPTOOL=$(CMD_PREFIX)esptool.py
DEVICE=/dev/ttyUSB0
AMPY_DELAY=5

DO_AMPY=$(SSH_CMD) $(CMD_AMPY) -p $(DEVICE) -d $(AMPY_DELAY)
DO_ESPTOOL=$(SSH_CMD) $(CMD_ESPTOOL) --port $(DEVICE)

# put sensitive and local variables in to private.mk, which won't be commited
-include private.mk

# do all: flash and install webrepl
do_all: flash_esp32 install_webrepl

reinstall_all: clean do_all

# get firmware from docker to here
esp32_firmware: $(LFIRMWARE_PATH)

minicom:
	$(SSH_CMD) minicom -D $(DEVICE)

flash_esp32: .deps/.flashed

clean:
	rm -rf .deps

$(LFIRMWARE_PATH):
	make up
	mkdir -p $(shell dirname $(LFIRMWARE_PATH))
	docker cp $(DOCKER_CONTAINER):$(DFIRMWARE_PATH) $(LFIRMWARE_PATH)


.deps/.flashed: .deps/.files_scpied
	# scp files to banana pi
	$(DO_ESPTOOL) erase_flash
	$(DO_ESPTOOL) write_flash -z 0x1000 $(RFIRMWARE_PATH)
	touch $@

install_webrepl: .deps/.webrepl_cfg_installed .deps/.boot_installed 

.deps/.files_scpied: $(LFIRMWARE_PATH) $(BOOT_PY) $(WEBREPL_CFG_PY)
	$(SCP) $(LFIRMWARE_PATH) $(WEBREPL_CFG_PY) $(BOOT_PY) $(SSH_USERHOST):/tmp/
	touch $@


.deps/.boot_installed: .deps/.files_scpied .deps/.flashed
	$(DO_AMPY) put $(RBOOT_PY)
	touch $@

.deps/.webrepl_cfg_installed: .deps/.files_scpied .deps/.flashed
	$(DO_AMPY) put $(RWEBREPL_CFG_PY)
	touch $@

$(BOOT_PY): scripts/boot.py.base
	mkdir -p .deps
	cp $< $(BOOT_PY)
	sed -i s/{WIFI_SSID}/$(WIFI_SSID)/g $(BOOT_PY)
	sed -i s/{WIFI_PASS}/$(WIFI_PASS)/g $(BOOT_PY)

$(WEBREPL_CFG_PY): scripts/webrepl_cfg.py.base
	cp $< $(WEBREPL_CFG_PY)
	sed -i s/{WEBREPL_PASS}/$(WEBREPL_PASS)/g $(WEBREPL_CFG_PY)


### do everything on local machine, without using ssh ....

local_%:
	make $(patsubst local_%,%,$@) SSH_CMD= SCP=true RFIRMWARE_PATH=$(LFIRMWARE_PATH) RWEBREPL_CFG_PY=$(WEBREPL_CFG_PY) RBOOT_PY=$(BOOT_PY)
