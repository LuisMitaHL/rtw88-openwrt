# BACKPORTS.md

Registry of every patch in `patches/`: where it came from, why it is carried, and its
upstream status. Build procedure is in `README.md`; the rules that keep this file in
sync with `patches/` are in `AGENTS.md`.

- Pin: `lwfinger/rtw88` `f1dd7c3a5` (2026-10-24), set in `Makefile` as
  `PKG_SOURCE_DATE` / `PKG_SOURCE_VERSION`.
- Source of merged fixes: `pkshih/rtw` branch `rtw-next`, audited at head
  `9b0be45d4` ("Merge tag wireless-next-2026-10-15") plus a linux-wireless
  mailing-list sweep (2026-10-31).
- Supported OpenWrt targets: 24.10 (Linux 6.6) and 25.12 (Linux 6.12). 23.05
  (Linux 5.15) was dropped with the `f1dd7c3a5` pin bump.
- Every post-pin fix must be carried here as a patch until the next pin bump.

## Provenance convention

- **Pending (mailing list, not merged)** — first line carries the lore
  Message-ID instead of a SHA, and a `Note:` after the mail headers names the
  source series and any dependency.
- **Downstream-only** — first line is the null SHA `00000000...`; the patch
  header says it is not an upstream backport.

The pin now contains every commit previously carried as a `Merged` backport, so
that status is currently unused. It returns, as `From <upstream SHA>`, when a
commit merged into `rtw-next` after `fbfa27d9b` has to be carried against this pin.

## Status legend

- **Merged** — picked into `rtw-next`; absent from the pin, so carried here
  until the pin is bumped. No such patch at the `f1dd7c3a5` pin.
- **Pending** — submitted to linux-wireless, not merged upstream; the
  Message-ID is the identity until an upstream commit exists.
- **Downstream** — repo-only feature; never submitted upstream.

Only these three statuses exist. The section "Not carried" lists reviewed
upstream work rejected on purpose (Superseded / Withdrawn / wrong-subsystem /
already in the pin) — those never get a patch file.

## Pending upstream (not merged; Message-ID is the identity)

These may change or be rejected upstream. When one gets merged, follow
`AGENTS.md`: replace the Message-ID with the real commit SHA in both the patch
file and here, and flip the status to Merged.

| Patch | Upstream Message-ID | Status | Notes |
|---|---|---|---|
| `0400` usb-download-rsvd-page-synchronously | `20261013033737.6761-1-pepe.schlehofer@gmail.com` | Pending | Reserved page is downloaded synchronously (URB with completion-wait, 5 s cancel). Fixes `error beacon valid` / beacon download races. Acked upstream; OpenWrt is picking it (PR [#25837](https://github.com/openwrt/openwrt/pull/25837)). **Hand-adapted**: `secs_to_jiffies()` guarded at 6.13 with a `msecs_to_jiffies(5000)` fallback. **Base for `0520`**; no longer requires the old USB write-failure fix (now in the pin). |
| `0410` 8822b-relax-etsi-edcca-2g | `20261011204509.46062-1-pepe.schlehofer@gmail.com` | Pending | 2.4 GHz ETSI EDCCA threshold `max(IGI+8, 48)` capped 50. The adapter's own USB3 energy pinned IGI low → AP invisible in scans + `failed to get tx report`. Different function than the 8822B RF-path fix now in the pin, no conflict. OpenWrt PR [#25836](https://github.com/openwrt/openwrt/pull/25836). |
| `0420` usb-drop-rx-before-device-started | `20261016161931.18495-1-25031212351@stu.xidian.edu.cn` | Pending | Drop RX frames while `RTW_FLAG_RUNNING` is clear (frames delivered by probe-time URBs before mac80211 starts, incl. leftovers in `rx_queue` after stop). Low severity, mostly dmesg noise. v1 unreviewed. Relies on the descriptor validation now in the pin (same function). |
| `0430` rx-do-not-trust-claimed-decryption | `20261017083313.56113-1-luka.gejak@linux.dev` | Pending | Only claim decryption for a frame that passed the CRC/ICV checks, and drop `RX_FLAG_DECRYPTED` for an AES frame whose CCMP header is malformed; ICV-failed frames get `RX_FLAG_FAILED_FCS_CRC` (as rtw89). Without this, one frame with a garbage CCMP header poisons mac80211's CCMP replay counter and every later genuine frame is dropped. Fixes the 8822CE A-MSDU watch item; shared `rx.c`, but the repro is PCIe (8822CE) and there is no USB reproduction, so it is carried as hardening. v1, unreviewed (no follow-ups). Same function as the descriptor validation now in the pin; the old hand-adaptation for the pre-bump 5-arg `rtw_rx_query_rx_desc()` no longer applies, so re-verify on a bump. |
| `0500` mac80211-program-channel-on-start | `20261007091225.413-2-jeremy.fareau@gmail.com` | Pending | M1 (2-patch series "channel and control frame filter lost on interface restart") — program the channel in `rtw_ops_start()`. Reported on RTL8814AU (a target chip), monitor mode. |
| `0510` main-restore-control-frame-filter-on-start | `20261007091225.413-3-jeremy.fareau@gmail.com` | Pending | M1 patch 2 — restore `REG_RXFLTMAP1` in `rtw_core_start()`. Companion of `0500`. |
| `0520` fw-download-beacon-from-rsvd-page | `20261026152940.1274382-2-mehmet.fide@gmail.com` | Pending | M2 (v9 series "channel switch in AP mode", patch 1/3) — download the beacon the reserved page was built with instead of fetching a second one, so a countdown that starts at 2 no longer reaches 0. **Requires `0400`** (it must complete synchronously). No port change since v6: the v9 hunk lands byte-identically on the pin. |
| `0530` mac80211-channel-switch-in-ap-mode | `20261026152940.1274382-3-mehmet.fide@gmail.com` | Pending | M2 mac80211 part (v9 patches 2/3 + 3/3, **bundled** — 3/3 only reworks the pacing helper 2/3 adds, and they are one feature here) — sets `WIPHY_FLAG_HAS_CHANNEL_SWITCH` + `channel_switch_beacon`, calls `ieee80211_csa_finish()`, and queues the countdown downloads 10 ms after each TBTT read from `REG_TSFTR`. **Hand-adapted**: (1) `ieee80211_beacon_cntdwn_is_complete()` / `ieee80211_csa_finish()` guarded at 6.14, where their `link_id` argument was added (the old row said 6.9, which is wrong: both gained `link_id` with the MLO rework); (2) `guard(mutex)(&rtwdev->mutex)` in `rtw_ops_hw_scan()` replaced by an explicit lock + `goto out`, because 5.15 has no `linux/cleanup.h` and the 23.05 target may come back; (3) the ASSOC and `BSS_CHANGED_BEACON` hunks rebased onto the pin's `LINUX_VERSION_CODE` guards around `vif->cfg.assoc`. Requires `0520`. **Beware**: Ping-Ke's Acked-by does not cover the WoWLAN-resume path added in 2/3 at v9 — expect further revisions. |

## Downstream (never submitted upstream)

| Patch | Upstream | Status | Notes |
|---|---|---|---|
| `0900` txpower-honour-iw-set-txpower | null SHA | Downstream | Standard `iw phy <phy> set txpower fixed|limited <mBm>`. mac80211's already-resolved cap (`min(regulatory, user, AP)`, a total) is cached in `struct rtw_hal` and clamps the per-rate offset by active TX paths. `.get_txpower` signature guarded at **6.14** (where `link_id` was added); **no `.set_txpower`** is registered — that op does not exist in mainline mac80211. Notified via `config()` (`IEEE80211_CONF_CHANGE_POWER`) and `bss_info_changed()` (`BSS_CHANGED_TXPOWER`), both present from 6.1 through 6.18, so unguarded. |
| `0910` pci-old-fix-dma-format-32bit | null SHA | Downstream | Build fix for `pci_old.c` (only in the lwfinger/pkshih tree, untouched by any `0xxx` patch): its tx-data diagnostic prints `dma_addr_t` with `%#llx`, which `-Werror=format` rejects where `dma_addr_t` is a 32-bit type (32-bit targets such as the mt76x8 family, formerly built on 23.05). Casts both args to `unsigned long long`. No dependencies. |

## Dropped at the `f1dd7c3a5` pin bump (now in the pin)

The 16 `Merged` backports `0010`–`0320` were removed: each maps to a commit already
in the new pin, and applying all of them fuzzily to `f1dd7c3a5` leaves the tree
byte-identical. Their upstream ids, kept here so the work is not re-audited:

   9f2948010  6b964941b  10d58823c  aa7d92e83  d5e6f353c  7cde94dab
   c710c7c2e  04cc8c59a  185971f1b  cf8b516f6  a4a2c1a10  617b1d976
   000e63e67  0b772bb2d  0fe85a5f9  81510c3d6

Two port quirks disappeared with them:

- `0060`'s TX report timeout (500 ms PCIe / 2500 ms otherwise) is now upstream
  through `4f88655` (increase the 8723D-USB timeout) plus the vendored
  `c141bdd`; the pin's `tx.c` is byte-identical to what the patch produced.
  The pin's `rtwdev->hci.type == RTW_HCI_TYPE_PCIE` split must not be re-ported.
- The old descriptor-validation backport's dropped `FCS_LEN` check in `rtw_usb_rx_handler()` was later removed
  upstream on purpose by `016a0f6` ("usb: No need to check for frames smaller
  than FCS anymore"), which notes the validation lives in
  `rtw_rx_query_rx_desc()` since `0dea178`. The pin has both; do not restore it.
- The old USB write-failure fix's OpenWrt-only `ieee80211_purge_tx_queue()` guard fell with 23.05
  support: both remaining kernels (6.6, 6.12) have that API.

## Not carried (reviewed and intentionally rejected)

- `c80788f7c` — superseded by `7cde94dab` (former `0060`); both are in the pin.
- `ed51a86b7` (monitor-mode control frames) — already in the pin.
- The PCI-only series (NAPI leak, ASPM/Dell/ASUS quirks, stalled-TX recovery,
  PCI-only OOB read / AER) and the SDIO-only / RTL8723B chip-introduction
  clusters — wrong bus or chip for this USB package.
- "8830e65ed" — treewide `assign_bit()` cleanup; the only rtw88 hunk is cosmetic.
- "8723d: add iface combination" (2026-10-16) — targets the newer per-chip
  `iface_combinations` design; 8723D already gets STA+AP here.
- `usb: retry control message on -EPROTO` (2026-05-28) — posted as an HTML
  attachment, no reviewable diff; the symptom is addressed by the pin's
  USB-mode-switch quieting (former `0300`).
- Mehmet Fide's TX-power patch (2026-09-17) — withdrawn; superseded here by `0900`.
- RTL8812A Bluetooth 1T1R restriction (`f1dd7c3`) and the RTL8812AE antenna-
  selection commit — 8812A-only; kept out of the 8812AU/8821AU/8822BU line.

**Watch items** (bug reports with no patch posted — repro/justification material only):
RTL8812BU does not re-enumerate after a failed USB write (2026-09-06); `WARN_ON` storm from
`rtw_get_channel()` (2026-09-06). The RTL8822CE corrupted-A-MSDU report (2026-10-16) now
has a patch — see `0430`.

## OpenWrt carry status (2026-10-26)

The only rtw88 fix OpenWrt's `package/kernel/mac80211/patches/rtl/` backports is
`7cde94dab`, which the pin now carries; P1/P2 are being picked via PRs
`#25837`/`#25836`. Everything else in this repo is ahead of OpenWrt.

## File naming and order

- `0xxx-*.patch` are shared by the OpenWrt versions and applied to the raw
  lwfinger tree in filename order; buckets are `00xx` fixes, `01xx` AP after-DTIM,
  `02xx` 8822B/C, `03xx` cosmetic, `04xx` pending single fixes, `05xx` pending
  series, `09xx` downstream features. Numbers are tens, i.e. `0400` → next free
  is `0410`; the `00xx`–`03xx` buckets are empty at this pin.
- `999-openwrt-{24.10,25.12}-compat.patch` are **generated** artifacts:
  they rewrite `LINUX_VERSION_CODE` checks on top of the `0xxx` patches and must
  be regenerated (both) after changing any `0xxx` patch — see
  `README.md` § "Generate the patch". Keep only the matching version's file when
  building.
- Order dependencies currently in the tree:
  `0400 → 0520 → 0530`, `0500` & `0510` companion, `0420` and `0430` follow the
  descriptor validation that now lives in the pin, `0900` and `0910` independent.

## Re-audit pointers

- Pin: `git log --oneline --all` on `lwfinger/rtw88`; the repo imports
  `rtw-next` in batches, so a burst of commits usually lands at once.
- Merged queue: `git log --oneline -- <path> ...` on `pkshih/rtw` `rtw-next` for
  `drivers/net/wireless/realtek/rtw88` newer than the audit head.
- Mailing list: `git clone --shallow-since=<old-pin-date> https://lore.kernel.org/linux-wireless/0`
  (the web UI is bot-protected) plus `https://marc.info/?l=linux-wireless&w=2&r=1&s=rtw-88`.
- Sources read for this file: `https://github.com/pkshih/rtw/tree/rtw-next`,
  individual commits at `https://github.com/pkshih/rtw/commit/<SHA>`, lore
  Message-IDs above, OpenWrt PRs `#25299/#25303/#25836/#25837/#25504/#25505`.

Maintenance rules for agents are in `AGENTS.md`.
