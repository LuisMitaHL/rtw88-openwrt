include $(TOPDIR)/rules.mk

PKG_NAME:=rtw88-backports-usb
PKG_RELEASE:=1

PKG_LICENSE:=GPLv2
PKG_LICENSE_FILES:=

PKG_SOURCE_URL:=https://github.com/lwfinger/rtw88
PKG_SOURCE_PROTO:=git
PKG_SOURCE_DATE:=2025-11-30
PKG_SOURCE_VERSION:=3309c45c283cbd996e1e05eeddf90c4fa589b90b

# PKG_MAINTAINER:=
PKG_BUILD_PARALLEL:=1

STAMP_CONFIGURED_DEPENDS := $(STAGING_DIR)/usr/include/mac80211-backport/backport/autoconf.h

include $(INCLUDE_DIR)/kernel.mk
include $(INCLUDE_DIR)/package.mk

define Package/rtw88-backports-firmware
  TITLE:= RealTek rtw88 firmware files
  SECTION:=firmware
  CATEGORY:=Firmware
  DEPENDS:=
endef

RTW_AUTOLOAD := rtw_8821cu \
		rtw_8822bu \
		rtw_8822cu \
		rtw_8812au \
		rtw_8821au \
		rtw_8723du

define KernelPackage/rtw88-backports-usb
  SUBMENU:=Wireless Drivers
  TITLE:= Realtek RTL8822CU AP Mode
  DEPENDS:=+kmod-cfg80211 +kmod-mac80211 +kmod-usb-core +@DRIVER_11N_SUPPORT +@DRIVER_11AC_SUPPORT +@PCI_SUPPORT +rtw88-backports-firmware
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
	$(PKG_BUILD_DIR)/rtw_8723d.ko \
	$(PKG_BUILD_DIR)/rtw_8723x.ko \
	$(PKG_BUILD_DIR)/rtw_8723du.ko
  AUTOLOAD:=$(call AutoLoad,50,$(RTW_AUTOLOAD))
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

EXTRA_CFLAGS:= \
	-DRTW_SINGLE_WIPHY \
	-DRTW_USE_CFG80211_STA_EVENT \
	-DCONFIG_IOCTL_CFG80211 \
	-DCONFIG_CONCURRENT_MODE \
	-DBUILD_OPENWRT

EXTRA_KCONFIG:= \
	CONFIG_RTW88-BACKPORTS-USB=m \
	USER_MODULE_NAME=rtw88-backports-usb

MAKE_OPTS:= \
	$(KERNEL_MAKE_FLAGS) \
	M="$(PKG_BUILD_DIR)" \
	NOSTDINC_FLAGS="$(NOSTDINC_FLAGS)" \
	USER_EXTRA_CFLAGS="$(EXTRA_CFLAGS)" \
	$(EXTRA_KCONFIG)

define Build/Compile
	+$(MAKE) $(PKG_JOBS) -C "$(LINUX_DIR)" \
		$(MAKE_OPTS) \
		modules
endef

define Package/rtw88-backports-firmware/install
	$(INSTALL_DIR) $(1)/lib/firmware/rtw88
	$(INSTALL_DATA) \
		$(PKG_BUILD_DIR)/firmware/* \
		$(1)/lib/firmware/rtw88/
endef

$(eval $(call KernelPackage,rtw88-backports-usb))
$(eval $(call BuildPackage,rtw88-backports-firmware))
