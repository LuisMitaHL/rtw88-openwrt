# rtw88-openwrt 🚀
Package and tools for the latest [Linux rtw88](https://github.com/lwfinger/rtw88) driver, backported for OpenWrt 23.05, 24.10, and 25.12.

With this repo, you can build ready-to-use modules with the latest fixes for your router. You can test patches from rtw88 devs too :)

![8821AU](docs/8821au.jpg)

## Support
- RTL8812AU
- RTL8814AU
- RTL8821AU
- RTL8821CU
- RTL8822BU
- RTL8822CU
- RTL8723DU

## Thanks
Thanks to henkv1 for the original repo: https://github.com/henkv1/rtw88-usb-openwrt/

## How to Use

### Build rtw88 for the official OpenWrt-provided 25.12 binaries
This is the most common case.

- Boot your favorite Linux distro and install the prerequisites: https://openwrt.org/docs/guide-developer/toolchain/install-buildsystem
- Download the SDK for your device. For example: if you have a Filogic router with 25.12.4, you can download the openwrt-sdk-25.12.4 tarball from https://downloads.openwrt.org/releases/25.12.4/targets/mediatek/filogic/
- Uncompress and go to the new folder.
- Update the package feeds: `./scripts/feeds update -a ; ./scripts/feeds install -a` (see: https://openwrt.org/docs/guide-developer/toolchain/using_the_sdk for information on using the SDK)
- Clone this repository into the folder package/kernel/rtw88-backports: `git clone https://github.com/LuisMitaHL/rtw88-openwrt package/kernel/rtw88-backports`.
- Run make defconfig.
- There are three patches: for 23.05, 24.10 and 25.12. **Delete the patches for OpenWrt versions that you won't need**.
- Compile the package: `make package/rtw88-usb/compile`. You can add ` -j$(nproc)` at the end for multi-core compiling.

If the build process works, you will find two files:
- The firmware package is named rtw88-backports-firmware-*.apk and you can find it in the bin/packages/{architecture}/base/ directory. 
- The kernel module package is named kmod-rtw88-backports-usb_*.apk and you can find it in the bin/targets/{architecture}/{model}/packages/ directory.

You can copy both packages to your device and install them one by one using `apk add {package} --allow-untrusted`. Install the firmware package first.

### Build the patch

rtw88 is not directly compatible with OpenWrt. This is because OpenWrt uses a hybrid codebase (for example, 23.05 uses Linux 5.15 with mac80211 backports from 6.1), and kernel version checks by rtw88 must be modified with a patch.

You can generate your own patch if the rtw88 repo has been updated, or you want to test or revert some code and the provided patch does not work anymore.

This only works for OpenWrt 23.05, 24.10, and 25.12 target devices.

- Clone the original rtw88 repo.
- Optionally update the code or apply any patches you want. Delete all 0001-openwrt-*.patch files.
- From this repo, choose a script from `tools` for your OpenWrt version and execute it inside the rtw88 tree.
- Generate a patch file with `git diff > rtw88-openwrt.patch` inside the rtw88 tree.
- Put the `rtw88-openwrt.patch` in the "patches" folder of a local copy of this repo.


