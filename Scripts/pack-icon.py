"""Package PNG representations as a modern macOS ICNS without image conversion."""
import pathlib
import struct
import sys

source = pathlib.Path(sys.argv[1])
variants = {
    b"icp4": "icon_16x16.png",
    b"icp5": "icon_32x32.png",
    b"icp6": "icon_32x32@2x.png",
    b"ic07": "icon_128x128.png",
    b"ic08": "icon_256x256.png",
    b"ic09": "icon_512x512.png",
    b"ic10": "icon_512x512@2x.png",
    b"ic11": "icon_16x16@2x.png",
    b"ic12": "icon_32x32@2x.png",
    b"ic13": "icon_128x128@2x.png",
    b"ic14": "icon_256x256@2x.png",
}
chunks = []
for tag, name in variants.items():
    png = (source / name).read_bytes()
    chunks.append(tag + struct.pack(">I", len(png) + 8) + png)
body = b"".join(chunks)
pathlib.Path(sys.argv[2]).write_bytes(b"icns" + struct.pack(">I", len(body) + 8) + body)
