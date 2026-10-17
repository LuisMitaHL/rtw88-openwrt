#!/bin/bash
#
# Render tools/rtw88-patcher-openwrt-<version>.sh for each OpenWrt release
# from tools/rtw88-patcher-openwrt.template.sh. The per-version facts live
# in the table below; update the template for logic changes and re-run this.
#
#   version  kernel (LINUX_VERSION_CODE base)  mac80211 backport  skip files
#   23.05    5.15                              6.1                -
#   24.10    6.6                               6.11               usb.c usb.h
#   25.12    6.12                              6.17               -
#
# mac80211 backport levels are the PKG_VERSION of the mac80211 package of
# each OpenWrt release (6.1.110 / 6.12.61 / 6.18.7 in the SDKs). The guard
# window ends at the newest mac80211 API each release deliberately provides
# to out-of-tree modules (6.1 / 6.11 / 6.17), NOT at the backport level
# itself: guarding thresholds the release's kernel sources do not satisfy
# (e.g. 24.10's 6.6 kernel vs the 6.12 backport) would select code paths
# against kernel-side APIs the kernel lacks, and vice versa.
#
# 24.10 skips usb.c/usb.h: kernel 6.6 does not provide WQ_BH, so the
# workqueue-BH RX paths there must stay.

set -euo pipefail
cd "$(dirname "$0")"

# version|OPENWRT_KERNEL|BACKPORT_API|SKIP_FILES
render() {
	local ver=$1 kernel=$2 api=$3 skip=$4
	out=rtw88-patcher-openwrt-$1.sh
	sed -e "s|@OPENWRT_VERSION@|$ver|g" \
		-e "s|@OPENWRT_KERNEL@|$kernel|g" \
		-e "s|@BACKPORT_API@|$api|g" \
		-e "s|@SKIP_FILES@|$skip|g" \
		rtw88-patcher-openwrt.template.sh > "$out"
	chmod +x "$out"
}

render 23.05 5.15 6.1 ''
render 24.10 6.6 6.11 'usb.c usb.h'
render 25.12 6.12 6.17 ''
