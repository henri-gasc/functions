#!~/Documents/Gentoo/venv/bin/python
# -*- coding: utf-8 -*-

import importlib
import os
import re
import sys

try:
    import numpy

    empty_venv = True
except ModuleNotFoundError:
    empty_venv = False
assert (
    not empty_venv
), "The module numpy was found, are you sure the environment is clean ?"

dir_searched = sys.argv[1]


def list_files_in(directory: str) -> list[str]:
    files = []
    if os.path.isfile(directory):
        files.append(directory)
    elif os.path.isdir(directory):
        for pot_file in os.listdir(directory):
            path = f"{directory}/{pot_file}"
            for f in list_files_in(path):
                files.append(f)
    else:
        print(f"ignoring {path}, not a file nor a directory")
    return files


def filter(list_file: list[str], ext: str = ".py") -> list[str]:
    files = []
    for f in list_file:
        filename, extension = os.path.splitext(f)
        if extension == ext:
            files.append(f)
    return files


def format(list_file: str) -> str:
    try:
        importlib.import_module(imp)
    except ModuleNotFoundError:
        use = "[${PYTHON_USEDEP}]"
        print(f"dev-python/{imp}{use}")


import_statements = []
list_files = list_files_in(dir_searched)

for file in filter(list_files):
    f = open(file, "r")
    for line in f:
        if "import " in line:
            statement = line.strip()
            # The statement can be as follow (we want the xxx):
            # - from xxx import ... (as ...)
            # - import xxx (as ...)
            # - from xxx.abc import ... (as ...)
            # - import xxx.abc (as ...)
            # In the first two cases, xxx is the second word
            # In the second two, xxx is the first part of the second word
            if '"' in statement:
                continue
            module_name = statement.split(" ")[1]
            if "." in module_name:
                module_name = module_name.split(".")[0]
            import_statements.append(module_name.lower())
    f.close()

if importlib in import_statements:
    print("The list of modules printed here may not be complete")
print(f"The dependencies for {os.path.realpath(dir_searched)} are:")
for imp in sorted(set(import_statements)):
    format(imp)

for file in filter(list_files, ".txt"):
    if "requirement" in file:
        print(f"\nThere is those requirements as well ({file}):")
        with open(file, "r") as f:
            print(f.read())
