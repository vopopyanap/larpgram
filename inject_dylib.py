#!/usr/bin/env python3
import sys
import struct
import plistlib
import os
import glob

def inject_dylib(binary_path, dylib_path):
    print(f"[inject_dylib] Patching Mach-O binary: {binary_path}")
    with open(binary_path, "rb") as f:
        data = bytearray(f.read())

    magic = struct.unpack("<I", data[:4])[0]
    if magic != 0xfeedfacf:
        raise ValueError(f"Not a 64-bit Mach-O binary (magic={hex(magic)})")

    magic, cputype, cpusubtype, filetype, ncmds, sizeofcmds, flags, reserved = struct.unpack("<IIIIIIII", data[:32])

    offset = 32
    target_bytes = dylib_path.encode("utf-8")
    for _ in range(ncmds):
        cmd, csize = struct.unpack("<II", data[offset:offset+8])
        if cmd in (0xc, 0xd, 0x80000018):
            stroff = struct.unpack("<I", data[offset+8:offset+12])[0]
            name = data[offset+stroff:offset+csize].split(b"\x00")[0]
            if target_bytes in name:
                print(f"[inject_dylib] Dylib already injected: {name.decode('utf-8', 'ignore')}")
                return True
        offset += csize

    path_bytes = target_bytes + b"\x00"
    pad_len = (8 - (len(path_bytes) % 8)) % 8
    path_padded = path_bytes + (b"\x00" * pad_len)
    cmdsize = 24 + len(path_padded)

    # struct dylib_command: cmd (0xc), cmdsize, name.offset (24), timestamp (2), current_version (0), compatibility_version (0)
    cmd_bytes = struct.pack("<IIIIII", 0xc, cmdsize, 24, 2, 0, 0) + path_padded

    end_of_cmds = 32 + sizeofcmds
    data[end_of_cmds:end_of_cmds + cmdsize] = cmd_bytes

    # Update mach_header_64
    struct.pack_into("<II", data, 16, ncmds + 1, sizeofcmds + cmdsize)

    with open(binary_path, "wb") as f:
        f.write(data)

    print(f"[inject_dylib] Successfully injected {dylib_path} (ncmds: {ncmds + 1})")
    return True

def patch_info_plist(plist_path, display_name="Larpgram", bundle_id="ph.telegra.larpgram"):
    print(f"[patch_plist] Updating {plist_path} with Name='{display_name}', ID='{bundle_id}'")
    with open(plist_path, "rb") as f:
        pl = plistlib.load(f)

    pl["CFBundleDisplayName"] = display_name
    pl["CFBundleName"] = display_name
    pl["CFBundleIdentifier"] = bundle_id

    with open(plist_path, "wb") as f:
        plistlib.dump(pl, f)
    print("[patch_plist] Info.plist updated successfully!")

def strip_localized_strings(app_dir):
    print(f"[strip_strings] Cleaning localized InfoPlist.strings from {app_dir}")
    count = 0
    for lproj in glob.glob(os.path.join(app_dir, "*.lproj", "InfoPlist.strings")):
        try:
            os.remove(lproj)
            count += 1
        except Exception:
            pass
    print(f"[strip_strings] Removed {count} localized InfoPlist.strings files")

if __name__ == "__main__":
    if len(sys.argv) < 3:
        print("Usage:")
        print("  python inject_dylib.py dylib <binary_path> <dylib_path>")
        print("  python inject_dylib.py plist <app_dir> [display_name] [bundle_id]")
        sys.exit(1)

    action = sys.argv[1]
    if action == "dylib":
        binary_path = sys.argv[2]
        dylib_path = sys.argv[3] if len(sys.argv) > 3 else "@executable_path/Frameworks/Larpgram.dylib"
        inject_dylib(binary_path, dylib_path)
    elif action == "plist":
        app_dir = sys.argv[2]
        display_name = sys.argv[3] if len(sys.argv) > 3 else "Larpgram"
        bundle_id = sys.argv[4] if len(sys.argv) > 4 else "ph.telegra.larpgram"
        plist_path = os.path.join(app_dir, "Info.plist")
        patch_info_plist(plist_path, display_name, bundle_id)
        strip_localized_strings(app_dir)
