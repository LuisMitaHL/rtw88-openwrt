#!/bin/bash
#
# Render tools/rtw88-patcher-openwrt-<version>.sh for each OpenWrt release
# from tools/rtw88-patcher-openwrt.template.sh. The per-version facts live
# in the table below; update the template for logic changes and re-run this.
#
#   version  kernel (LINUX_VERSION_CODE base)  mac80211 backport  skip files
#   24.10    6.6                               6.11               usb.c usb.h
#   25.12    6.12                              6.17               -
#
# and the calls those kernels have no API for that upstream makes without a
# check (file|function|occurrence|kernel-version|old-call|new-call, see the
# template):
#
#   usb.c  rtw_usb_tx_agg_skb  ieee80211_purge_tx_queue()  added in 6.13;
#          the 5.15/6.6/6.12 kernels have only skb_queue_purge().
#   tx.c   rtw_tx_report_purge_timer  timer_container_of()  added in 6.16
#          for the "struct timer_list *t" body; the 6.12 kernel still
#          derives rtwdev with from_timer() in the "void *cntx" body.
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

# The call rules, one per line, paths relative to the tree top level.
PURGE_RULE='usb.c|rtw_usb_tx_agg_skb|1|6.12.0|ieee80211_purge_tx_queue(rtwdev->hw, &txcb->tx_ack_queue);|skb_queue_purge(&txcb->tx_ack_queue);'

# version|OPENWRT_KERNEL|BACKPORT_API|SKIP_FILES|calls to guard
# The replacement goes through awk, not sed: a rule legitimately contains
# '&' and '|', which sed would expand or treat as its delimiter.
render() {
	local ver=$1 kernel=$2 api=$3 skip=$4 rules=$5
	local out=rtw88-patcher-openwrt-$1.sh
	local -a exprs=(
		"OPENWRT_VERSION@$ver" "OPENWRT_KERNEL@$kernel"
		"BACKPORT_API@$api" "SKIP_FILES@$skip"
		"UNGUARDED_CALLS@$rules")
	local i
	for i in $(seq "${#exprs[@]}"); do
		export "RTW88_RENDER_$i=${exprs[i - 1]}"
	done
	awk -v n="${#exprs[@]}" '
		BEGIN {
			for (i = 1; i <= n; i++) {
				s = ENVIRON["RTW88_RENDER_" i]
				slot[substr(s, 1, index(s, "@") - 1)] = substr(s, index(s, "@") + 1)
			}
		}
		{
			for (k in slot) {
				tag = "@" k "@"
				while ((p = index($0, tag)) > 0)
					$0 = substr($0, 1, p - 1) slot[k] substr($0, p + length(tag))
			}
			print
		}' rtw88-patcher-openwrt.template.sh > "$out"
	chmod +x "$out"
}

render 24.10 6.6 6.11 'usb.c usb.h' ''
render 25.12 6.12 6.17 '' "$PURGE_RULE"
