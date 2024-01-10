#!/usr/bin/env python
# -*- coding: utf-8 -*-

import os
import platform
import sys
import time
from typing import Any, Optional, TextIO

import tomllib


class Ebuild:
    def __init__(self, path_to_pyprojectdottoml: str) -> None:
        self.path = path_to_pyprojectdottoml
        self.eapi = 8
        self.name = ""
        self.version = ""
        self.tool = ""
        self.inherit = "distutils-r1"
        self.description = ""
        self.homepage = ""
        self.src_uri = ""
        self.license = ""
        self.keywords = ""
        self.iuse: set[str] = set()
        self.test_package = ""
        self.doc_package = ""
        self.rdepend: dict[str, list[str]] = {"": [""]}
        self.bdepend: dict[str, list[str]] = {"": [""]}
        self.optfeature: list[Optional[str]] = []
        with open(self.path, "rb") as f:
            self.toml = tomllib.load(f)

    def get_keyword(self) -> None:
        arch = platform.machine()
        if arch == "x86_64":
            arch = "amd64"
        self.keywords = f"~{arch}"

    def guess_iuse(self) -> None:
        p = os.path.split(os.path.abspath(self.path))[0]
        for f in os.listdir(p):
            if os.path.isdir(f):
                if f.lower() in ["test", "tests"]:
                    self.iuse.add("test")
                elif f.lower() in ["doc", "docs"]:
                    self.iuse.add("doc")

    def extract_toml(self) -> None:
        raise NotImplementedError("You should not use this class")

    def build(self) -> None:
        self.extract_toml()
        self.get_keyword()
        self.guess_iuse()

    def write(self) -> None:
        f = open(f"./{self.name}-{self.version}.ebuild", "w")
        f.write(f"# Copyright 1999-{time.localtime().tm_year} Gentoo Authors\n")
        f.write(
            f"# Distributed under the terms of the GNU General Public License v2\n\n"
        )
        f.write(f"EAPI={self.eapi}\n\n")
        if "doc" in self.iuse:
            f.write(f'DOCS_BUILDER="{self.doc_package}"\n')
            f.write(f'DOCS_DIR="docs"\n')
        f.write(f"DISTUTILS_USE_PEP517={self.tool}\n")
        f.write("PYTHON_COMPAT=( python3_{10..12} )\n\n")
        f.write(f"inherit {self.inherit}\n\n")
        f.write(f'DESCRIPTION="{self.description}"\n')
        f.write(f'HOMEPAGE="{self.homepage}"\n')
        f.write(f'SRC_URI="{self.src_uri}"\n\n')
        f.write(f'LICENSE="{self.license}"\n')
        f.write(f'SLOT="0"\n')
        f.write(f'KEYWORDS="{self.keywords}"\n')
        f.write(f'IUSE="{""" """.join(self.iuse)}"\n\n')
        f.write(f'RDEPEND="\n')
        self.write_depend(f, self.rdepend)
        f.write(f'"\n\n')
        f.write(f'BDEPEND="\n')
        self.write_depend(f, self.bdepend)
        f.write(f'"\n\n')
        f.write('DEPEND="${RDEPEND}"\n\n')
        if "test" in self.iuse:
            f.write(f"distutils_enable_tests {self.test_package}\n")
        if self.optfeature != []:
            f.write("pkg_postinst() {\n")
            for opt in self.optfeature:
                f.write(f'\toptfeature "fill this" dev-python/{opt}\n')
            f.write("}\n")
        f.close()

    def write_depend(self, file: TextIO, depend: dict[str, list[str]]) -> None:
        for cat in depend:
            before = ""
            if cat != "":
                before = "\t"
                file.write(f"\t{cat}? (\n")
            for dep in depend[cat]:
                file.write(f"{before}\t{dep}\n")
            if cat != "":
                file.write("\t)\n")

    def format_version(
        self, version: str, name: str, add_usedep: bool = True
    ) -> list[str]:
        v = []
        if "," in version:
            for i in version.split(","):
                v += self.format_version(i, name, add_usedep=False)
        elif version[0] in ["<", ">", "="]:
            stop = 1
            if version[1] == "=":
                stop += 1
            if version[0] == "=":
                version.replace("=", "~")
            v.append(f"{version[:stop]}{name}-{version[stop:]}")
        elif version[0] == "^":
            v_s = version[1:].split(".")
            j = 0
            while int(v_s[j]) == 0:
                j += 1
            ver_up = ["0" for _ in range(len(v_s) - 1)]
            ver_up.insert(j, f"{int(v_s[j])+1}")
            v.append(f">={name}-{'.'.join(v_s)}")
            v.append(f"<{name}-{'.'.join(ver_up)}")
        elif version[0] == "*":
            v.append(name)
        else:
            try:
                int(version[0])
                v.append(f"={name}-{version}")
            except:
                print(f"Sorry, this ({version}) was not taken into account")
        # print(v)
        if add_usedep:
            return [i + "[${PYTHON_USEDEP}]" for i in v]
        else:
            return v

    def parse_dep(self, dep: dict[str, Any], name: str) -> str:
        out = ""
        vers = self.format_version(dep['version'], name)
        if "optional" in dep.keys() and dep["optional"]:
            out = f"opt? ( {' '.join(vers)} )"
            if "opt" not in self.iuse:
                self.iuse.add("opt")
        if "python" in dep.keys():
            out = f"python {dep['python']} ? ( {' '.join(vers)} )"
        if "extras" in dep.keys():
            out = f"{' '.join(vers)} ({dep['extras']})"
        return out

    def guess_test_doc(self, name: str) -> None:
        if "pytest" in name:
            self.test_package = "pytest"
        elif "sphinx" in name:
            self.doc_package = "sphinx"
        elif "mkdocs" in name:
            self.doc_package = "mkdocs"

    def get_dependencies(self, dependencies: dict[str, Any]) -> list[str]:
        deps = []
        for d in dependencies:
            self.guess_test_doc(d)
            v = dependencies[d]
            if type(v) == str:
                for formatted in self.format_version(v, f"dev-python/{d}"):
                    deps.append(formatted)
            elif type(v) == dict:
                deps.append(self.parse_dep(v, f"dev-python/{d}"))
            elif type(v) == list:
                for i in v:
                    deps.append(self.parse_dep(i, f"dev-python/{d}"))
            else:
                print(f"Sorry, can't extract version from {v}")
        return deps

    def get_name_dev_dep(
        self, toml: dict[str, Any], allow_simple_dep: bool
    ) -> list[str]:
        list_dev = []
        if "dev-dependencies" in toml.keys():
            list_dev += self.get_dependencies(toml["dev-dependencies"])
        if "dependencies" in toml.keys() and allow_simple_dep:
            list_dev += self.get_dependencies(toml["dependencies"])
        if "dev" in toml.keys():
            list_dev += self.get_name_dev_dep(toml["dev"], True)
        if "group" in toml.keys():
            list_dev += self.get_name_dev_dep(toml["group"], False)
        return list_dev


class Poetry(Ebuild):
    def __init__(self, path_to_pyprojectdottoml: str):
        super().__init__(path_to_pyprojectdottoml)

    def extract_toml(self) -> None:
        toml = self.toml["tool"]["poetry"]
        self.name = toml["name"]
        self.version = toml["version"]
        self.tool = "poetry"
        self.description = toml["description"]
        self.license = toml["license"]
        self.homepage = f"{toml['homepage']}"
        self.repo = 'homepage'
        if 'repository' in toml.keys():
            self.homepage = f"{self.homepage} {toml['repository']}"
            self.repo = 'repository'
        self.src_uri = (
            f"{toml[self.repo]}/archive/refs/tags/"
            + "v${PV}.tar.gz -> ${P}.gh.tar.gz"
        )
        if "extras" in toml.keys():
            self.get_extras(toml)
        self.rdepend[""] = self.get_dependencies(toml["dependencies"])
        self.bdepend["test"] = self.get_name_dev_dep(toml, False)

    def get_extras(self, toml: dict[str, Any]) -> None:
        self.inherit += " optfeature"
        for f in toml["extras"]:
            self.optfeature += toml["extras"][f]

class Flit(Ebuild):
    def __init__(self, path_to_pyprojectdottoml: str):
        super().__init__(path_to_pyprojectdottoml)

    def extract_toml(self) -> None:
        toml = self.toml["tool"]["flit"]["metadata"]
        self.name = toml["dist-name"]
        self.version = ""
        self.tool = "flit"
        self.description = toml["description"]
        self.license = toml["license"]
        self.homepage = f"{toml['homepage']}"
        self.repo = 'homepage'
        if 'repository' in toml.keys():
            self.homepage = f"{self.homepage} {toml['repository']}"
            self.repo = 'repository'
        self.src_uri = (
            f"{toml[self.repo]}/archive/refs/tags/"
            + "v${PV}.tar.gz -> ${P}.gh.tar.gz"
        )
        self.rdepend[""] = self.get_dependencies(self.toml["requires"])

def search_dir(directory: str) -> list[str]:
    files = []
    if os.path.isfile(directory):
        name = os.path.basename(directory)
        if name == "pyproject.toml":
            files.append(directory)
    elif os.path.isdir(directory):
        for pot_file in os.listdir(directory):
            path = f"{directory}/{pot_file}"
            for f in search_dir(path):
                files.append(f)
    else:
        print(f"ignoring {directory}, not a file nor a directory")
    return files


if len(sys.argv) == 1:
    d = "."
else:
    d = sys.argv[1]

for f in search_dir(d):
    with open(f, "rb") as file:
        tom = tomllib.load(file)
    back = tom["build-system"]["build-backend"]
    ebuild: Optional[Ebuild] = None
    if back == "poetry.core.masonry.api":
        ebuild = Poetry(f)
    elif back == "flit_core.buildapi":
        ebuild = Flit(f)

    if ebuild is not None:
        ebuild.build()
        ebuild.write()
    else:
        print(f"No backend found for {back}")
