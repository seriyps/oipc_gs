#!/usr/bin/env python3
import argparse
import os
import sys
import subprocess
import re

SECTOR = 512

def run(cmd, check=True):
    print("+", " ".join(cmd))
    subprocess.run(cmd, check=check)

def numfmt_iec(value):
    multipliers = {"K": 1024, "M": 1024**2, "G": 1024**3, "T": 1024**4}
    m = re.match(r"(\d+)([KMGTP])", value.upper())
    if not m:
        raise ValueError(f"Cannot parse size: {value}")
    return int(m.group(1)) * multipliers[m.group(2)]

def get_partition_info(img, pn):
    out = subprocess.check_output(["sgdisk", "-i", str(pn), img], text=True)
    first = int(re.search(r"First sector:\s*(\d+)", out).group(1))
    last = int(re.search(r"Last sector:\s*(\d+)", out).group(1))
    type_guid = re.search(r"Partition GUID code:\s*([0-9A-Fa-f\-]+)", out).group(1)
    attr = re.search(r"Attribute flags:\s*([0-9A-Fa-f]+)", out)
    attr_hex = attr.group(1) if attr else "0000000000000000"
    return first, last, type_guid, attr_hex

def dst_last_sector(img):
    out = subprocess.check_output(["sgdisk", "-p", img], text=True)
    sectors = [int(m.group(1)) for m in re.finditer(r"^\s+\d+\s+\d+\s+(\d+)", out, re.MULTILINE)]
    return max(sectors) if sectors else 2047

def append_partition(src_img, dst_img, src_pn):
    src_first, src_last, type_guid, attr_hex = get_partition_info(src_img, src_pn)
    size = src_last - src_first + 1
    last_end = dst_last_sector(dst_img)
    dst_start = last_end + 1
    dst_end = dst_start + size - 1
    run(["sgdisk", "-n", f"0:{dst_start}:{dst_end}", dst_img])
    out = subprocess.check_output(["sgdisk", "-p", dst_img], text=True)
    dst_pn = max([int(m.group(1)) for m in re.finditer(r"^\s+(\d+)", out, re.MULTILINE)])
    run(["sgdisk", "-t", f"{dst_pn}:{type_guid}", dst_img])
    run(["sgdisk", "-A", f"{dst_pn}:set:{attr_hex}", dst_img])
    run([
        "dd", f"if={src_img}", f"of={dst_img}",
        f"bs={SECTOR}", f"skip={src_first}", f"seek={dst_start}", f"count={size}",
        "conv=notrunc"
    ])
    return dst_pn, dst_start, dst_end

def resize_ext4_partition(dst_img, pn, size_spec):
    # Attach loop device
    loopdev = subprocess.check_output(["sudo", "losetup", "--find", "--show", "--partscan", dst_img], text=True).strip()
    partdev = f"{loopdev}p{pn}"
    # Check and resize filesystem
    run(["sudo", "e2fsck", "-f", "-y", partdev])
    run(["sudo", "resize2fs", partdev, size_spec])
    out = subprocess.check_output(["sudo", "dumpe2fs", "-h", partdev], text=True)
    blocks = int(re.search(r"Block count:\s*(\d+)", out).group(1))
    bsize = int(re.search(r"Block size:\s*(\d+)", out).group(1))
    fs_bytes = blocks * bsize
    new_secs = (fs_bytes + SECTOR - 1) // SECTOR
    # Get partition info
    start_sector, _, type_guid, attr_hex = get_partition_info(dst_img, pn)
    new_end = start_sector + new_secs - 1
    # Delete and recreate partition, restore type and flags
    run(["sgdisk", "-d", str(pn), dst_img])
    run(["sgdisk", "-n", f"{pn}:{start_sector}:{new_end}", dst_img])
    run(["sgdisk", "-t", f"{pn}:{type_guid}", dst_img])
    run(["sgdisk", "-A", f"{pn}:set:{attr_hex}", dst_img])
    run(["sudo", "partprobe", loopdev])
    run(["sudo", "losetup", "-d", loopdev])

def shrink_image(dst_img):
    out = subprocess.check_output(["sgdisk", "-p", dst_img], text=True)
    ends = [int(m.group(1)) for m in re.finditer(r"^\s+\d+\s+\d+\s+(\d+)", out, re.MULTILINE)]
    if not ends:
        raise RuntimeError("No partitions found in image")
    last_end = max(ends)
    backup_gpt_sectors = 34
    final_sector = last_end + backup_gpt_sectors
    final_bytes = final_sector * SECTOR
    with open(dst_img, "r+b") as f:
        f.truncate(final_bytes)
    # Move backup GPT header and check for errors
    result = subprocess.run(["sgdisk", "--move-second-header", dst_img])
    if result.returncode != 0:
        raise RuntimeError("Failed to move backup GPT header")

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("src_img")
    parser.add_argument("dst_img")
    parser.add_argument("-r", "--resize-rootfs", default=None)
    args = parser.parse_args()

    if os.path.exists(args.dst_img):
        print("Error: destination image exists")
        sys.exit(1)

    src_size = os.path.getsize(args.src_img)
    with open(args.dst_img, "wb") as f:
        f.truncate(src_size)

    run(["sgdisk", "-Z", args.dst_img])
    run(["sgdisk", "-o", args.dst_img])

    p2_num, p2_start, p2_end = append_partition(args.src_img, args.dst_img, 2)
    p3_num, p3_start, p3_end = append_partition(args.src_img, args.dst_img, 3)

    if args.resize_rootfs:
        resize_ext4_partition(args.dst_img, p3_num, args.resize_rootfs)

    p1_num, p1_start, p1_end = append_partition(args.src_img, args.dst_img, 1)

    shrink_image(args.dst_img)
    print("Done! New image:", args.dst_img)

if __name__ == "__main__":
    main()
