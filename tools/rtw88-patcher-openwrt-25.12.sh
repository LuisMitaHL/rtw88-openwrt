#!/bin/bash
# set -ex

# List of kernel versions to check
KERNEL_VERSIONS=("6, 12, 0" "6, 13, 0" "6, 14, 0" "6, 15, 0" "6, 16, 0" "6, 17, 0")

modify_file() {
  local file=$1
  
  # Check if file exists
  if [[ -f "$file" ]]; then
    echo "Processing file: $file"

    for version in "${KERNEL_VERSIONS[@]}"; do
      # Update first pattern
      sed -i "s/#if LINUX_VERSION_CODE < KERNEL_VERSION(${version})/#if LINUX_VERSION_CODE < KERNEL_VERSION(${version}) \&\& !defined(OPENWRT)/" "$file"
      sed -i "s/#if (LINUX_VERSION_CODE < KERNEL_VERSION(${version}))/#if (LINUX_VERSION_CODE < KERNEL_VERSION(${version})) \&\& !defined(OPENWRT)/" "$file"
      
      # Update second pattern
      sed -i "s/#if LINUX_VERSION_CODE >= KERNEL_VERSION(${version})/#if LINUX_VERSION_CODE >= KERNEL_VERSION(${version}) || defined(OPENWRT)/" "$file"
      sed -i "s/#if (LINUX_VERSION_CODE >= KERNEL_VERSION(${version}))/#if (LINUX_VERSION_CODE >= KERNEL_VERSION(${version})) || defined(OPENWRT)/" "$file"
    done

    echo "Modifications applied to $file"
  else
    echo "File not found: $file"
  fi
}

patch_rtw88_main_h() {
  local file="main.h"
  
  # Check if the file exists
  if [[ -f "$file" ]]; then
    echo "Patching file: $file"

    # Check if the '#define OPENWRT' line is already present
    if ! grep -q "#define OPENWRT" "$file"; then
      sed -i '39i\
#define OPENWRT\n' "$file"

      echo "Patched $file with '#define OPENWRT'"
    else
      echo "File $file already contains '#define OPENWRT', skipping patch."
    fi
  else
    echo "File not found: $file"
  fi
}

# Find all files in the current directory and subdirectories to modify.
# find . -type f -name "*.c" -o -name "*.h" | while read -r file; do
# Do not replace alt_rtl8821ce/ files.
find . -type d -name "alt_rtl8821ce" -prune -o \( -type f -name "*.c" -o -name "*.h" \) -print | while read -r file; do
  modify_file "$file"
done

patch_rtw88_main_h

echo "Finished."
