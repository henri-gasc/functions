#!/usr/bin/env python
# -*- coding: utf-8 -*-

import portage
import requests
import os
import xml.etree.ElementTree as ET
import shutil

def list_all_packages(overlay: str) -> list[str]:
    """ Return the list of all packages in a overlay """
    list_packages = []
    path_cat = os.path.join(overlay, "profiles", "categories")
    if not os.access(path_cat, os.F_OK):
        # If the profiles/categories file does not exist,
        # we have to find manually all valid folders
        # but for now return nothing
        return []

    with open(path_cat) as f:
        categories = f.read().split("\n")
    for category in categories:
        path = os.path.join(overlay, category)
        if not os.access(path, os.F_OK):
            continue
        for package in os.listdir(path):
            list_packages.append(f"{category}/{package}")
    return list_packages

def get_all_matching(atom: str, overlays: list[str]) -> list[tuple[str, str]]:
    """ Return the list of all matching atoms across all overlays """
    matching = []
    for o in overlays:
        packages = list_all_packages(o)
        if atom in packages:
            matching.append((f"{atom}::{os.path.basename(o)}", o))
    return matching

def print_list(l: list[str]) -> None:
    n = len(l)
    for i in range(n):
        print(f"[{i:n}] {l[i]}")

def get_upstream(metadata_file: str) -> str:
    tree = ET.parse(metadata_file).getroot()
    i = 0
    while tree[i].tag != "upstream":
        i += 1
    for url in tree[i].findall("remote-id"):
        t = url.attrib["type"]
        if t == "github":
            return f"https://github.com/{url.text}"
        elif t in ["pypi"]:
            continue
        else:
            print(t)

def extract_from_manifest(manifest: str, ebuild: str) -> str:
    def get_index(dists: list[str], version: str) -> int:
        for i in range(len(dists)):
            if dists[i][-7:] == ".tar.xz":
                d_v = dists[i][:-7]
            else:
                print(dists[i])
            if d_v == version:
                return i
        return -1
    dists = []
    version = ebuild[:-7]
    with open(manifest) as f:
        for line in f:
            cat, name, *trash = line.split(" ")
            if cat != "DIST":
                continue
            name = line.split(" ")[1]
            if name[-4:] == ".asc":
                continue
            elif ".patch" in name:
                continue
            dists.append(name.strip())
    i = get_index(dists, version)
    if i != -1:
        return dists[i]
    ref = version.find(".")
    rev = version[ref:].find("-r")
    if rev != -1:
        i = get_index(dists, version[:ref+rev])
        if i != -1:
            return dists[i]
    print(f"Could not find a version corresponding to {version} in {dists}")
    return ""

def recurse_find_release_notes(start: str) -> list[str]:
    files = []
    for element in os.listdir(start):
        path = os.path.join(start, element)
        if os.path.isfile(path):
            for poss in ["news", "changelog", "release_notes", "release-notes"]:
                if element.lower()[:len(poss)] == poss:
                    files.append(path)
                    break
        elif os.path.isdir(path):
            files += recurse_find_release_notes(path)
    return files

# atom = input("Changelog for [category/atom]: ")
config_env = portage.config().environ()
# overlays = config_env["PORTDIR_OVERLAY"].split(" ")

# match = get_all_matching(atom, overlays)
# i = 0
# if len(match) == 0:
#     print(f"No atom corresponding to {atom} were found")
#     exit(1)
# elif len(match) != 1:
#     print_list([m[0] for m in match])
#     i = int(input("Chosen overlay is: "))
# path_to_ebuild_dir = os.path.join(match[i][1], atom)

# ebuilds = []
# for file in os.listdir(path_to_ebuild_dir):
#     if file[-7:] == ".ebuild":
#         ebuilds.append(os.path.join(path_to_ebuild_dir, file))
# i = 0
# if len(ebuilds) == 0:
#     print(f"No ebuilds found in {path_to_ebuild_dir}")
#     exit(2)
# elif len(ebuilds) != 1:
#     print_list([os.path.basename(e) for e in ebuilds])
#     i = int(input("The chosen ebuild is number: "))
# ebuild_file = ebuilds[i]
# remote = get_upstream(os.path.join(os.path.dirname(ebuild_file), "metadata.xml"))
# manifest_file = os.path.join(os.path.dirname(ebuild_file), "Manifest")
# if not os.access(manifest_file, os.F_OK):
#     print(f"Could not find a Manifest for {atom}")
#     exit(3)
# distfile = extract_from_manifest(manifest_file, os.path.basename(ebuild_file))
distfile = "ffmpeg-6.1.1.tar.xz"
distfile_file = os.path.join(config_env["DISTDIR"], distfile)

tmp_path = os.path.join(os.path.abspath(os.sep), "tmp", distfile, str(id(distfile)))
print(f"Extracting {distfile} to {tmp_path}")
os.makedirs(tmp_path)
shutil.unpack_archive(distfile_file, tmp_path)
changelogs = recurse_find_release_notes(tmp_path)
notes = []
for file in changelogs:
    with open(file) as f:
        notes.append(f.read())
os.rmdir(tmp_path)

if len(notes) == 0:
    print("Need to fetch online the changelog")
