AA_PROXY_RS_VERSION = main
AA_PROXY_RS_SITE = https://github.com/aa-proxy/aa-proxy-rs.git
AA_PROXY_RS_SITE_METHOD = git

# Fleetwood monorepo: use sibling aa-proxy-rs when present (includes STA WiFi support).
LOCAL_AA_PROXY_RS := $(realpath $(BR2_EXTERNAL_AA_PROXY_OS_PATH)/../../../aa-proxy-rs)
ifneq ($(wildcard $(LOCAL_AA_PROXY_RS)/Cargo.toml),)
AA_PROXY_RS_SITE = $(LOCAL_AA_PROXY_RS)
AA_PROXY_RS_SITE_METHOD = local
AA_PROXY_RS_VERSION = local
endif

# obtain git hashes for aa-proxy-rs and buildroot
BUILDROOT_DIR = $(realpath $(TOPDIR)/..)
BUILDROOT_COMMIT = $(shell git config --global --add safe.directory $(BUILDROOT_DIR) && git -C $(BUILDROOT_DIR) rev-parse HEAD)
AA_PROXY_RS_GIT_DIR = $(realpath $(DL_DIR)/aa-proxy-rs/git)
AA_PROXY_RS_COMMIT = $(shell git config --global --add safe.directory $(AA_PROXY_RS_GIT_DIR) && git -C $(AA_PROXY_RS_GIT_DIR) rev-parse HEAD)

define AA_PROXY_RS_INSTALL_TARGET_CMDS
	$(INSTALL) -D -m 0755 $(@D)/target/$(RUSTC_TARGET_NAME)/release/aa-proxy-rs $(TARGET_DIR)/usr/bin
	$(INSTALL) -D -m 0644 $(@D)/target/release/config.toml $(TARGET_DIR)/etc/aa-proxy-rs/config.toml
	$(INSTALL) -D -m 0755 $(@D)/contrib/S28aa-proxy-wifi $(TARGET_DIR)/etc/init.d/S28aa-proxy-wifi
	$(INSTALL) -D -m 0755 $(@D)/contrib/S30wifi_mode $(TARGET_DIR)/etc/init.d/S30wifi_mode
	$(INSTALL) -D -m 0755 $(@D)/contrib/S39hostapd_conf $(TARGET_DIR)/etc/init.d/S39hostapd_conf
	$(INSTALL) -D -m 0755 $(@D)/contrib/S41wifi_services $(TARGET_DIR)/etc/init.d/S41wifi_services
	$(INSTALL) -D -m 0755 $(@D)/contrib/S93aa-proxy-rs $(TARGET_DIR)/etc/init.d/S93aa-proxy-rs
endef

# pass git hashes as env variables
AA_PROXY_RS_CARGO_ENV = \
	AA_PROXY_COMMIT="$(AA_PROXY_RS_COMMIT)" \
	BUILDROOT_COMMIT="$(BUILDROOT_COMMIT)" \
	AA_PROXY_BOARD="$(notdir $(patsubst %/,%,$(CONFIG_DIR)))"

# use own toolchain only for RISC-V builds (milkv-duos)
ifeq ($(findstring milkv-duos,$(CONFIG_DIR)),milkv-duos)
# Add our own toolchain to path
AA_PROXY_RS_CARGO_ENV += PATH=/app/buildroot/output/milkv-duos/build/riscv/bin:$(BR_PATH)
endif

# disable wasm-scripting on armv6 (wasmtime doesn't support it)
ifeq ($(RUSTC_TARGET_NAME),arm-unknown-linux-gnueabihf)
AA_PROXY_RS_CARGO_BUILD_OPTS += --no-default-features
endif

# default config file generator
define AA_PROXY_RS_GENERATE_CONFIG
	cd $(@D) && env PATH=$${PATH}:$(HOST_DIR)/bin cargo run --release --bin generate_config
endef
AA_PROXY_RS_POST_BUILD_HOOKS += AA_PROXY_RS_GENERATE_CONFIG

$(eval $(cargo-package))
