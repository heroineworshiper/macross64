#!/usr/bin/python


import os
import sys
import fileinput

filename = sys.argv[1]

file = open(filename, 'rb')
data = bytearray(file.read())
total = 0
s = "    .byte "
for b in data:
    s += "$%02x" % b
    if total < len(data) - 1:
        if total > 0 and ((total + 1) % 8) == 0:
            print s
            s = "    .byte "
        else:
            s += ", "
    else:
        print s
        s = ""
    total += 1
