# BACKPORTS.md

Registry of every patch in `patches/`: where it came from, why it is carried, and its
upstream status. Build procedure is in `README.md`; the rules that keep this file in
sync with `patches/` are in `AGENTS.md`.

- Pin: `lwfinger/rtw88` `a56bcd26e` (2026-05-21), set in `Makefile` as
  `PKG_SOURCE_DATE` / `PKG_SOURCE_VERSION`. The upstream repo is dormant since.
- Source of merged fixes: `pkshih/rtw` branch `rtw-next`, audited at head
  `fbfa27d9b` (2026-10-10) plus a linux-wireless mailing-list sweep (2026-10-17).
- Because the pin is stale, every post-pin fix must be carried here as a patch
  until the pin is bumped.

## Provenance convention

- **Merged upstream** — patch first line is `From <upstream SHA> Mon Sep 17...`
  (a real 40-hex SHA, the commit id in `pkshih/rtw`).
- **Pending (mailing list, not merged)** — first line carries the lore
  Message-ID instead of a SHA, and a `Note:` after the mail headers names the
  source series and any dependency.
- **Downstream-only** — first line is the null SHA `00000000...`; the patch
  header says it is not an upstream backport.

## Status legend

- **Merged** — picked into `rtw-next`; absent from the pin, so carried here
  until the pin is bumped.
- **Pending** — submitted to linux-wireless, not merged upstream; the
  Message-ID is the identity until an upstream commit exists.
- **Downstream** — repo-only feature; never submitted upstream.

Only these three statuses exist. The section "Not carried" lists reviewed
upstream work rejected on purpose (Superseded / Withdrawn / wrong-subsystem /
already in the pin) — those never get a patch file.

## Merged (in rtw-next, absent from the pin)

| Patch | Upstream | Status | Notes |
|---|---|---|---|
| `0010` txq-fix-memory-leak-in-push-skb | [`9f2948010`](https://github.com/pkshih/rtw/commit/9f2948010) | Merged | `ieee80211_free_txskb()` on the `rtw_hci_tx_write()` failure path. |
| `0020` usb-fix-memory-leaks-on-write-failure | [`6b964941b`](https://github.com/pkshih/rtw/commit/6b964941b) | Merged | Purge ack queue + kfree on `rtw_usb_write_port()` errors. **Base for `0400`.** **Hand-adapted for 23.05** (5.15 kernel / mac80211 6.1 lacks the exported `ieee80211_purge_tx_queue()`): the purge call guarded at 6.13 with `skb_queue_purge()` fallback, like the pin's own call sites. |
| `0030` mac80211-fix-out-of-bounds-cam-write | [`10d58823c`](https://github.com/pkshih/rtw/commit/10d58823c) | Merged | `>` → `>=` in the CAM idx check when the key table is full. |
| `0040` rx-add-rx-descriptor-validation | [`aa7d92e83`](https://github.com/pkshih/rtw/commit/aa7d92e83) | Merged | **Hand-ported**: kept the pin's 5-arg `rtw_rx_query_rx_desc()` (upstream reshaped to 4 args with `int`); added the validations + error returns; dropped the pin's now-redundant `FCS_LEN` check in `rtw_usb_rx_handler()`; skipped the shared pci.c/sdio.c hunks (USB-only package). **Base for `0420`.** |
| `0050` fw-check-edcca-th-for-null | [`d5e6f353c`](https://github.com/pkshih/rtw/commit/d5e6f353c) | Merged | Pre-pin fix lwfinger never picked up. `edcca_th` is NULL on every target chip (8821c/8812a/8814a/8723d) → NULL deref. |
| `0060` tx-report-long-timeout-for-non-pcie | [`7cde94dab`](https://github.com/pkshih/rtw/commit/7cde94dab) | Merged | 500 ms (PCIe) vs 2500 ms (everyone else) TX report timeout; fixes slow TX status / TCP collapse on USB. **Net-result port** — upstream's patch sits on c80788f7c, which must stay unported. |
| `0100` usb-route-bmc-frames-high-queue-dtim | [`c710c7c2e`](https://github.com/pkshih/rtw/commit/c710c7c2e) | Merged | **AP after-DTIM series, apply in order 0100 → 0110 → 0120.** Route bmc frames to the high queue only for DTIM delivery. Fixes page-pool exhaustion: AP associations fail, `error beacon valid`. |
| `0110` usb-bound-after-dtim-queue | [`04cc8c59a`](https://github.com/pkshih/rtw/commit/04cc8c59a) | Merged | Adds `hiq_lock`/`hiq_budget`/`hiq_refill` to `struct rtw_usb`, init in `rtw_usb_init_tx()`. Depends on `0100`. |
| `0120` usb-filter-after-dtim-frames | [`185971f1b`](https://github.com/pkshih/rtw/commit/185971f1b) | Merged | Adds `rtw_usb_bmc_needs_dtim()` (EAPOL/ARP/DHCP only). Depends on `0100` + `0110`. |
| `0130` mac80211-widen-atim-window-ap | [`cf8b516f6`](https://github.com/pkshih/rtw/commit/cf8b516f6) | Merged | HCI-agnostic; `ATIMWND_AP 0xa` in `rtw_ops_start_ap()`. Conceptually part of the series above. |
| `0200` 8822c-skip-rf-path-c-in-phy-status | [`a4a2c1a10`](https://github.com/pkshih/rtw/commit/a4a2c1a10) | Merged | `<=` → `<` twice: loop read RF path C on a 2x2 chip, OOB rssi data. |
| `0210` 8822b-skip-rf-path-c-in-phy-status | [`617b1d976`](https://github.com/pkshih/rtw/commit/617b1d976) | Merged | Same fix, `query_phy_status_page1()`. |
| `0220` 8822c-use-fsleep-for-dpk-delays | [`000e63e67`](https://github.com/pkshih/rtw/commit/000e63e67) | Merged | `msleep(10)` can oversleep to 20 ms; `fsleep(10000)` is exact. |
| `0300` usb-quiet-mode-switch-transfer-errors | [`0b772bb2d`](https://github.com/pkshih/rtw/commit/0b772bb2d) | Merged | `RTW_FLAG_SWITCHING_USB_MODE` + guards: kills the `-71` register-write spam on USB2-only ports. |
| `0310` main-firmware-mac-address-fallback | [`0fe85a5f9`](https://github.com/pkshih/rtw/commit/0fe85a5f9) | Merged | Use firmware-provided MAC when efuse is invalid (e.g. 8723DS). Device-tree vs DTBO caveat on some routers. |
| `0320` debugfs-avoid-vzalloc-zero-rsvd-page | [`81510c3d6`](https://github.com/pkshih/rtw/commit/81510c3d6) | Merged | Kills the kernel WARNING when reading `rsvd_page` debugfs before writing it. |

## Pending upstream (not merged; Message-ID is the identity)

These may change or be rejected upstream. When one gets merged, follow
`AGENTS.md`: replace the Message-ID with the real commit SHA in both the patch
file and here, and flip the status to Merged.

| Patch | Upstream Message-ID | Status | Notes |
|---|---|---|---|
| `0400` usb-download-rsvd-page-synchronously | `20261013033737.6761-1-pepe.schlehofer@gmail.com` | Pending | Reserved page is downloaded synchronously (URB with completion-wait, 5 s cancel). Fixes `error beacon valid` / beacon download races — the other half of the AP stall fix (with `0100`–`0130`). **Requires `0020` first.** Acked upstream; OpenWrt is picking it (PR [#25837](https://github.com/openwrt/openwrt/pull/25837)). **Hand-adapted**: `secs_to_jiffies()` (kernel ≥ 6.13; 6.12.y stable has it) guarded at 6.13 with `msecs_to_jiffies(5000)` fallback so 23.05's 5.15 kernel compiles. |
| `0410` 8822b-relax-etsi-edcca-2g | `20261011204509.46062-1-pepe.schlehofer@gmail.com` | Pending | 2.4 GHz ETSI EDCCA threshold `max(IGI+8, 48)` capped 50. The adapter's own USB3 energy pinned IGI low → AP invisible in scans + `failed to get tx report`. Different function than `0210`, no conflict. OpenWrt PR [#25836](https://github.com/openwrt/openwrt/pull/25836). |
| `0420` usb-drop-rx-before-device-started | `20261016161931.18495-1-25031212351@stu.xidian.edu.cn` | Pending | Drop RX frames while `RTW_FLAG_RUNNING` is clear (frames delivered by probe-time URBs before mac80211 starts, incl. leftovers in `rx_queue` after stop). Low severity, mostly dmesg noise. v1 unreviewed. **Requires `0040` first** (same function). |
| `0430` rx-do-not-trust-claimed-decryption | `20261017083313.56113-1-luka.gejak@linux.dev` | Pending | Only claim decryption for a frame that passed the CRC/ICV checks, and drop `RX_FLAG_DECRYPTED` for an AES frame whose CCMP header is malformed; ICV-failed frames get `RX_FLAG_FAILED_FCS_CRC` (as rtw89). Without this, one frame with a garbage CCMP header poisons mac80211's CCMP replay counter and every later genuine frame is dropped. Fixes the 8822CE A-MSDU watch item; shared `rx.c`, but the repro is PCIe (8822CE) and there is no USB reproduction, so it is carried as hardening. v1, unreviewed (no follow-ups). **Requires `0040` first** (same function; hand-adapted to the pin's 5-arg `rtw_rx_query_rx_desc()`). |
| `0500` mac80211-program-channel-on-start | `20261007091225.413-2-jeremy.fareau@gmail.com` | Pending | M1 (2-patch series "channel and control frame filter lost on interface restart") — program the channel in `rtw_ops_start()`. Reported on RTL8814AU (a target chip), monitor mode. |
| `0510` main-restore-control-frame-filter-on-start | `20261007091225.413-3-jeremy.fareau@gmail.com` | Pending | M1 patch 2 — restore `REG_RXFLTMAP1` in `rtw_core_start()`. Companion of `0500`. |
| `0520` fw-download-beacon-from-rsvd-page | `20261013073010.358756-2-mehmet.fide@gmail.com` | Pending | M2 (v6 series "channel switch in AP mode") — re-download the reserved page every beacon interval to advance the CSA countdown. **Requires `0400`** (it must complete synchronously). |
| `0530` mac80211-channel-switch-in-ap-mode | `20261013073010.358756-3-mehmet.fide@gmail.com` | Pending | M2 mac80211 part — sets `WIPHY_FLAG_HAS_CHANNEL_SWITCH` + `channel_switch_beacon`, calls `ieee80211_csa_finish()`. **Hand-adapted to the pin**: explicit `mutex_lock()/mutex_unlock()` (OpenWrt 23.05 / 5.15 has no `cleanup.h`) and `ieee80211_beacon_cntdwn_is_complete()` / `ieee80211_csa_finish()` guarded at 6.9, where their `link_id` argument was added. Requires `0520`. |

## Downstream (never submitted upstream)

| Patch | Upstream | Status | Notes |
|---|---|---|---|
| `0900` txpower-honour-iw-set-txpower | null SHA | Downstream | Standard `iw phy <phy> set txpower fixed|limited <mBm>`. mac80211's already-resolved cap (`min(regulatory, user, AP)`, a total) is cached in `struct rtw_hal` and clamps the per-rate offset by active TX paths. `.get_txpower` signature guarded at **6.14** (where `link_id` was added); **no `.set_txpower`** is registered — that op does not exist in mainline mac80211. Notified via `config()` (`IEEE80211_CONF_CHANGE_POWER`) and `bss_info_changed()` (`BSS_CHANGED_TXPOWER`), both present from 6.1 through 6.18, so unguarded. |
| `0910` pci-old-fix-dma-format-32bit | null SHA | Downstream | Build fix for `pci_old.c` (only in the lwfinger/pkshih tree at the pin, untouched by any `0xxx` patch): its tx-data diagnostic prints `dma_addr_t` with `%#llx`, which `-Werror=format` rejects where `dma_addr_t` is a 32-bit type (OpenWrt 23.05 mt76x8). Casts both args to `unsigned long long`. No dependencies. |

## Not carried (reviewed and intentionally rejected)

- `c80788f7c` — superseded by `7cde94dab` (`0060`); porting both would double the effect.
- `ed51a86b7` (monitor-mode control frames) — **already in the pin** (lwfinger `274f0d866`).
- `f24d0d8c3`, `737e980e1`, `44d1f624b`, `b8d49bb8d`, `2c17afde9`, `0d2a88690`,
  `3f9094247`, `249716daa`, `bf1436771`, `658e3c836`, `bbb15e711`, `c95323ea9`,
  `6e76e9ed2`, `706183dbe` — already in the pin, or rejected (PCI-only OOB read / AER).
- `4c13e00cc` — pure refactor.
- `e779df480`, `b0034a2e4`, `c5a8c4936`, `ab468ac01`, `53eebd2b7` — PCI-only
  (NAPI leak, ASPM/Dell/ASUS quirks, stalled-TX recovery).
- `673662a04`, `5f92fb993`, `4d688f22e`, `b81ead28a`, `5a95bd460`, `8c17eb82a`,
  `28eaf7971`, `43f6347e8`, `73e3b1c94` and the RTL8723B chip series
  (`d726c70ce`, `a9283c737`, `6501c79b3`, `269946cba`, `b2d251aa7`,
  `6879a85cf`, `9f596b630`) — SDIO-only or chip-introduction/refactor commits.
- `8830e65ed` — treewide `assign_bit()` cleanup; the only rtw88 hunk is cosmetic.
- `8723d: add iface combination` (2026-10-16) — targets the newer per-chip
  `iface_combinations` design the pin doesn't have; 8723D already gets STA+AP.
- `usb: retry control message on -EPROTO` (2026-05-28) — posted as an HTML
  attachment, no reviewable diff; the symptom is addressed by `0300`.
- Mehmet Fide's TX-power patch (2026-09-17) — withdrawn; superseded here by `0900`.

**Watch items** (bug reports with no patch posted — repro/justification material only):
RTL8812BU does not re-enumerate after a failed USB write (2026-09-06); `WARN_ON` storm from
`rtw_get_channel()` (2026-09-06). The RTL8822CE corrupted-A-MSDU report (2026-10-16) now
has a patch — see `0430`.

## OpenWrt carry status (2026-10-16)

The only rtw88 fix OpenWrt's `package/kernel/mac80211/patches/rtl/` backports is
`7cde94dab` (`0060` here) on all semantic branches; P1/P2 are being picked via PRs
`#25837`/`#25836`. Everything else in this repo is ahead of OpenWrt.

## File naming and order

- `0xxx-*.patch` are shared by all OpenWrt versions and applied to the raw
  lwfinger tree in filename order; buckets are `00xx` fixes, `01xx` AP after-DTIM,
  `02xx` 8822B/C, `03xx` cosmetic, `04xx` pending single fixes, `05xx` pending
  series, `09xx` downstream features. Numbers are tens, i.e. `0060` → next free
  is `0070`.
- `999-openwrt-{23.05,24.10,25.12}-compat.patch` are **generated** artifacts:
  they rewrite `LINUX_VERSION_CODE` checks on top of the `0xxx` patches and must
  be regenerated (all three, last) after changing any `0xxx` patch — see
  `README.md` § "Generate the patch". Keep only the matching version's file when
  building.
- Order dependencies currently in the tree:
  `0020 → 0400`, `0040 → 0420`, `0040 → 0430`, `0100 → 0110 → 0120`,
  `0400 → 0520 → 0530`, `0500` & `0510` companion, `0900` independent.

## Re-audit pointers

- Merged queue: `git log --oneline -- <path> ...` on `pkshih/rtw` `rtw-next` for
  `drivers/net/wireless/realtek/rtw88` newer than the audit head.
- Mailing list: `git clone --shallow-since=<old-pin-date> https://lore.kernel.org/linux-wireless/0`
  (the web UI is bot-protected) plus `https://marc.info/?l=linux-wireless&w=2&r=1&s=rtw-88`.
- Sources read for this file: `https://github.com/pkshih/rtw/tree/rtw-next`,
  individual commits at `https://github.com/pkshih/rtw/commit/<SHA>`, lore
  Message-IDs above, OpenWrt PRs `#25299/#25303/#25836/#25837/#25504/#25505`.

Maintenance rules for agents are in `AGENTS.md`.
