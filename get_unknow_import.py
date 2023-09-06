#!/home/gasc/Documents/Gentoo/venv/bin/python
# -*- coding: utf-8 -*-

import importlib
import os
import re
import sys


def make_sure_venv_empty() -> None:
    try:
        # Classic module to be installed, yet not part of the python standart library
        import numpy

        empty_venv = True
    except ModuleNotFoundError:
        empty_venv = False
    assert (
        not empty_venv
    ), "The module numpy was found, are you sure the environment is clean ?"


def list_files_in(directory: str) -> list[str]:
    """List recursively the file in the directory and return the list of files with the path"""
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
    """Filter the list given by making removing those not of the extension chosen"""
    files = []
    for f in list_file:
        filename, extension = os.path.splitext(f)
        if extension == ext:
            files.append(f)
    return files


def format(module: str) -> str:
    """Format the module depending on whether the module was found or not"""
    try:
        importlib.import_module(module)
        out = ""
    except ModuleNotFoundError:
        out = f"dev-python/{module}" + "[${PYTHON_USEDEP}]"
    return out


def get_unknow_import(dir_to_search: str) -> tuple[list[str], dict[str, list[str]]]:
    """Print the list"""
    import_statements = []
    list_files = list_files_in(dir_to_search)

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
                    # Allow to also skip the 'from .abc ...' statements
                    module_name = module_name.split(".")[0]
                import_statements.append(module_name.lower())
        f.close()

    if "importlib" in import_statements:
        print("The list of modules printed here may not be complete")

    import_statements_correct = []
    for module in sorted(set(import_statements)):
        out = format(module)
        if out != "":
            import_statements_correct.append(out)

    requirement_star_dot_txt = {}
    for file in filter(list_files, ".txt"):
        if "requirement" in file:
            f = open(file, "r")
            for line in f:
                try:
                    requirement_star_dot_txt[file].append(format(line))
                except KeyError:
                    requirement_star_dot_txt[file] = [format(line)]
            f.close()

    return import_statements_correct, requirement_star_dot_txt


def print_unknow_import(dir_to_search: str) -> None:
    import_statements, requirements_txt = get_unknow_import(dir_to_search)
    print(f"The dependencies for {os.path.realpath(dir_to_search)} are:")
    print("\n".join(import_statements))

    print(f"\nAdditionally, there are those requirements as well:")
    for f in requirements_txt:
        print(f"  from {f}:")
        for m in requirements_txt[f]:
            print(f"    dev-python/{m}", "[${PYTHON_USEDEP}]")


if __name__ == "__main__":
    get_unknow_import(sys.argv[1])
