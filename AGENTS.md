# AGENTS.md — sync contract for `patches/` and `BACKPORTS.md`

`BACKPORTS.md` is the single source of truth for **why every patch in
`patches/` exists**, where it came from, and its upstream status. Read it
before touching anything in `patches/`; its file-naming and dependency rules
are normative for new work.

## File kinds (do not confuse them)

- `patches/0xxx-*.patch` — hand-maintained backports/features. Applied to the
  raw pinned rtw88 tree in filename order, shared by every OpenWrt version.
- `patches/999-openwrt-{23.05,24.10,25.12}-compat.patch` — **generated**
  artifacts that rewrite `LINUX_VERSION_CODE` checks on top of the `0xxx`
  patches. Never hand-edit them; regenerate all three per `README.md`
  § "Generate the patch" whenever a `0xxx` patch changes, and commit them with
  the change that caused them.
- `tools/backports-check.sh` — the sync gate. **Run it before every commit that
  touches `patches/` or `BACKPORTS.md`. Do not commit while it fails.** If you
  change the sync rules or naming conventions, update this file, `BACKPORTS.md`
  and the script in the same commit.

## The contract

1. **One row per patch file, both directions.** Adding, removing or renaming a
   `0xxx-*.patch` must be the same commit as the matching `BACKPORTS.md` row
   change. No patches without rows, no rows without patches.
2. **Provenance first line.** Each `0xxx` patch must start with
   `From <ref> Mon Sep 17 00:00:00 2001` where `<ref>` is:
   - the upstream commit SHA (40 hex) if merged in `pkshih/rtw` `rtw-next`;
   - the lore Message-ID if only submitted to linux-wireless (add a `Note:`
     line after the mail headers naming the source series and dependency);
   - the null SHA `0000...0000` for downstream-only features, with the header
     saying so.
   Never edit that line without editing its `BACKPORTS.md` row at the same time.
3. **Fixed status vocabulary** in `BACKPORTS.md`: `Merged` (in rtw-next,
   absent from the pin), `Pending` (submitted, unmerged), `Downstream`
   (repo-only, never submitted). Adding a status means updating the legend in
   the same commit. "Not carried" rows never create patch files.
4. **Upstream merge follow-up.** When a Pending patch gets merged upstream:
   re-fetch it from `pkshih/rtw`, swap the Message-ID for the real SHA in the
   patch file *and* the table row, flip the status to `Merged`, re-verify it
   still applies to the pin, and record any port quirks in the row's Notes.
5. **Pin bump follow-up.** Bumping `PKG_SOURCE_VERSION`/`PKG_SOURCE_DATE` in
   `Makefile` means: re-audit against `rtw-next`, drop patch files and rows now
   contained in the pin, and update `BACKPORTS.md`'s header. Never bump
   silently.
6. **Dependencies and order.** Record every `A requires B` in
   `BACKPORTS.md` § "File naming and order" and encode it in the numbering
   (`0xxx` buckets: `00xx` fixes, `01xx` AP after-DTIM, `02xx` 8822B/C,
   `03xx` cosmetic, `04xx` pending singles, `05xx` pending series, `09xx`
   downstream; tens, leave gaps). Never renumber existing files; never reorder
   a dependent series by filename alone.
7. **One fix per file; self-contained provenance.** No bundling several
   upstream commits into one file. Unmerged patches must carry the `Note:`
   line; merged ones only need their SHA.
8. **Generated files stay out of the contract.** `999-*` compat patches and
   `tools/rtw88-patcher-*` scripts have no `BACKPORTS.md` rows; their
   correctness rule is "regenerate + commit together with the `0xxx` change",
   and "keep the version-matching `999` patch last when packaging".

## Quick checklist for a new or changed patch

```
# 1. fetch provenance (SHA or Message-ID) and write the patch with it
# 2. add/adjust the row in BACKPORTS.md (right bucket, right status, notes)
# 3. regenerate the three 999-openwrt-*-compat.patch files if code lines moved
# 4. run the gate:
tools/backports-check.sh
# 5. commit patches/ + BACKPORTS.md/AGENTS.md (+ regenerated 999 files) together
```
