#!/usr/bin/python3

from unicodedata import name

for i in range(0x10FFFF):
    try:
        var = name(chr(i)).lower()
        print(f"\\u{i:X}\t{chr(i)}\t{var}\tu{i:x}")
    except:
        var = None
