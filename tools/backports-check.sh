#!/bin/sh
# tools/backports-check.sh — verify BACKPORTS.md stays in sync with patches/
#
# Checks (see AGENTS.md for the contract):
#   1. every patches/0xxx-*.patch first line is a valid provenance line
#      (From <40-hex SHA> Mon Sep 17 00:00:00 2001)
#   2. every 0xxx patch is referenced by BACKPORTS.md's carry tables
#   3. every reference in the BACKPORTS.md carry tables (Merged/Pending/
#      Downstream) resolves to an existing 0xxx patch first line
#   4. unmerged hashes carry a Note: line (source/dependency)
#
# Run before every commit that touches patches/ or BACKPORTS.md.
set -u

cd "$(cd "$(dirname "$0")/.." && pwd)" || exit 1
doc=BACKPORTS.md
fail=0

[ -f "$doc" ] || { echo "FAIL: $doc missing"; exit 1; }

# Collect all first-line provenance refs from existing patches (for step 3).
allrefs=$(for p in patches/0*.patch; do sed -n '1s/^From \(.*\) Mon Sep 17 00:00:00 2001$/\1/p' "$p"; done)

# Step 1-2, 4 per existing patch file.
for p in patches/0*.patch; do
	[ -f "$p" ] || continue
	line=$(sed -n '1p' "$p")
	ref=$(printf '%s\n' "$line" | sed -n 's/^From \(.*\) Mon Sep 17 00:00:00 2001$/\1/p')
	if [ -z "$ref" ]; then
		echo "FAIL: $p first line must be 'From <ref> Mon Sep 17 00:00:00 2001'"
		fail=1
		continue
	fi
	if [ "$ref" = "0000000000000000000000000000000000000000" ]; then
		stem=$(basename "$p" .patch)
		key=${stem%%-*}
		pat=$key
	else
		case $ref in
			*@[A-Za-z]*) key=$(printf '%s' "$ref"); pat=$(printf '%s' "$key");;
			*) key=$(printf '%s' "$ref" | cut -c1-9); pat="$key";;
		esac
	fi
	if [ "$ref" != "0000000000000000000000000000000000000000" ]; then
		case $ref in
			*@[A-Za-z]*)
				if ! grep -q '^Note:' "$p"; then
					echo "FAIL: $p carries a Message-ID ($key) but has no Note: line"
					fail=1
				fi
				;;
		esac
	fi
	if ! grep -qF -- "$pat" "$doc"; then
		echo "FAIL: $p (ref $key) has no row in $doc"
		fail=1
	fi
done

# Extract the carry tables (Merged / Pending / Downstream) only. The
# "Not carried" section may legitimately list upstream SHAs with no patch.
carry=$(awk '
	/^## Merged/        { on=1; next }
	/^## Pending/       { on=1; next }
	/^## Downstream/    { on=1; next }
	/^## /              { on=0 }
	on { print }
' "$doc")

# Step 3: every reference in the carry tables must resolve to a patch.
# Keys: 9-hex SHA prefixes (10-char short ids), Message-IDs, and the 4-digit
# numbering of each row (including dependency refs like "Requires `0020`").
keys=$(printf '%s\n' "$carry" | grep -oE '`[0-9a-f]{9}`|`[^`]*@[^`]*`|`[0-9]{4}`' | tr -d '`' | sort -u)
[ -n "$keys" ] || keys=""
missing=$(for k in $keys; do
	case $k in
		[0-9][0-9][0-9][0-9])
			ls patches/${k}-*.patch >/dev/null 2>&1 || echo "$k"
			;;
		*)
			# Keys made of only digits are numbers; treat hex-like 9-char keys fine.
			printf '%s\n' "$allrefs" | grep -qF -- "$k" || echo "$k"
			;;
	esac
done)
if [ -n "$missing" ]; then
	for k in $missing; do echo "FAIL: $doc references the $k hash but no patches/0xxx-*.patch has it"; fail=1; done
fi

if [ "$fail" -eq 0 ]; then
	n=$(printf '%s' "$keys" | wc -l)
	echo "OK: 0xxx patches and $doc agree ($n refs checked)"
else
	echo "FAIL: 0xxx patches and $doc are out of sync — neither set may be committed alone"
	exit 1
fi
