#!/bin/bash

set -u
set -e

${BR2_EXTERNAL_AA_PROXY_OS_PATH}/board/common/generate-issue.sh

source ${BR2_EXTERNAL_AA_PROXY_OS_PATH}/board/common/add_usb_serial.sh

# dnsmasq is started by S41wifi_services in AP mode only; drop the Buildroot
# auto-installed S80dnsmasq so STA mode does not spam DHCP errors at boot.
rm -f "${TARGET_DIR}/etc/init.d/S80dnsmasq"

