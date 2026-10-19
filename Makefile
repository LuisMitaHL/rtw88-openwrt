include $(TOPDIR)/rules.mk

PKG_NAME:=rtw88-backports-usb
PKG_RELEASE:=1

PKG_LICENSE:=GPL-2.0-only OR BSD-3-Clause
PKG_LICENSE_FILES:=

PKG_SOURCE_URL:=https://github.com/lwfinger/rtw88
PKG_SOURCE_PROTO:=git
PKG_SOURCE_DATE:=2026-05-21
PKG_SOURCE_VERSION:=a56bcd26e770257612a0803249cbd4095fc6feca

PKG_MAINTAINER:=Luis Mita <luis@luismita.com>
PKG_BUILD_PARALLEL:=1

STAMP_CONFIGURED_DEPENDS := $(STAGING_DIR)/usr/include/mac80211-backport/backport/autoconf.h

include $(INCLUDE_DIR)/kernel.mk
include $(INCLUDE_DIR)/package.mk

define Package/rtw88-backports-firmware
  # Firmware blobs are architecture-independent, so the package is installable
  # on any target (apk metadata "arch:noarch").
  PKGARCH:=all
  TITLE:= Realtek rtw88 firmware files
  SECTION:=firmware
  CATEGORY:=Firmware
  DEPENDS:=
endef

RTW_AUTOLOAD := rtw_8821cu \
		rtw_8822bu \
		rtw_8822cu \
		rtw_8812au \
		rtw_8814au \
		rtw_8821au \
		rtw_8723du

# Firmware blobs for the chips this package ships (see RTW_AUTOLOAD).
# Deliberately not a wildcard: the pinned tree also carries RTL8703B firmware
# for a chip no module here supports.
RTW_FW:= rtw8723d_fw.bin \
	rtw8812a_fw.bin \
	rtw8814a_fw.bin \
	rtw8821a_fw.bin \
	rtw8821c_fw.bin \
	rtw8822b_fw.bin \
	rtw8822c_fw.bin \
	rtw8822c_wow_fw.bin

define KernelPackage/rtw88-backports-usb
  SUBMENU:=Wireless Drivers
  TITLE:= Realtek rtw88 USB WiFi (AP mode)
  DEPENDS:=+kmod-mac80211 +kmod-usb-core +@DRIVER_11N_SUPPORT +@DRIVER_11AC_SUPPORT +rtw88-backports-firmware
  CONFLICTS:=kmod-rtw88-usb
  FILES:=\
	$(PKG_BUILD_DIR)/rtw_usb.ko \
	$(PKG_BUILD_DIR)/rtw_core.ko \
	$(PKG_BUILD_DIR)/rtw_88xxa.ko \
	$(PKG_BUILD_DIR)/rtw_8822cu.ko \
	$(PKG_BUILD_DIR)/rtw_8822c.ko \
	$(PKG_BUILD_DIR)/rtw_8822b.ko \
	$(PKG_BUILD_DIR)/rtw_8822bu.ko \
	$(PKG_BUILD_DIR)/rtw_8821c.ko \
	$(PKG_BUILD_DIR)/rtw_8821cu.ko \
	$(PKG_BUILD_DIR)/rtw_8821a.ko \
	$(PKG_BUILD_DIR)/rtw_8821au.ko \
	$(PKG_BUILD_DIR)/rtw_8812a.ko \
	$(PKG_BUILD_DIR)/rtw_8812au.ko \
	$(PKG_BUILD_DIR)/rtw_8814a.ko \
	$(PKG_BUILD_DIR)/rtw_8814au.ko \
	$(PKG_BUILD_DIR)/rtw_8723d.ko \
	$(PKG_BUILD_DIR)/rtw_8723x.ko \
	$(PKG_BUILD_DIR)/rtw_8723du.ko
  AUTOLOAD:=$(call AutoProbe,$(RTW_AUTOLOAD))
endef

NOSTDINC_FLAGS = \
	-I$(PKG_BUILD_DIR) \
	-I$(PKG_BUILD_DIR)/include \
	-I$(STAGING_DIR)/usr/include/mac80211-backport \
	-I$(STAGING_DIR)/usr/include/mac80211-backport/uapi \
	-I$(STAGING_DIR)/usr/include/mac80211 \
	-I$(STAGING_DIR)/usr/include/mac80211/uapi \
	-include backport/autoconf.h \
	-include backport/backport.h \
	-Wno-error=cast-function-type

# The pinned upstream Makefile builds rtw_pci.o (with pci_old.o), rtw_sdio.o
# and every *e/*s chip variant whenever the target kernel has CONFIG_PCI /
# CONFIG_MMC. None of those are shipped by this USB-only package, so force
# both gates off and let kbuild only build what is listed in FILES.
EXTRA_KCONFIG:= \
	CONFIG_PCI=n \
	CONFIG_MMC=

MAKE_OPTS:= \
	$(KERNEL_MAKE_FLAGS) \
	M="$(PKG_BUILD_DIR)" \
	NOSTDINC_FLAGS="$(NOSTDINC_FLAGS)" \
	$(EXTRA_KCONFIG)

define Build/Compile
	+$(MAKE) $(PKG_JOBS) -C "$(LINUX_DIR)" \
		$(MAKE_OPTS) \
		modules
endef

define Package/rtw88-backports-firmware/install
	$(INSTALL_DIR) $(1)/lib/firmware/rtw88
	$(INSTALL_DATA) \
		$(addprefix $(PKG_BUILD_DIR)/firmware/,$(RTW_FW)) \
		$(1)/lib/firmware/rtw88/
endef

$(eval $(call KernelPackage,rtw88-backports-usb))
$(eval $(call BuildPackage,rtw88-backports-firmware))
