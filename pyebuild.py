#!/usr/bin/env python
# -*- coding: utf-8 -*-

import configparser
import os
import platform
import sys
import time
from typing import Any, Optional, TextIO

import tomllib


def update_dict(d: dict[Any, Any], u: dict[Any, Any]) -> dict[Any, Any]:
    for k, v in u.items():
        if isinstance(v, dict):
            d[k] = update_dict(d.get(k, {}), v)
        else:
            d[k] = v
    return d


def convert_cfg_to_dict(cfg_file: str) -> dict[Any, Any]:
    def join(l: list[str], value: Any) -> dict[Any, Any]:
        if len(l) == 1:
            return {l[0]: value}
        else:
            return {l[0]: join(l[1:], value)}

    def explore_cfg(section: configparser.SectionProxy) -> dict[Any, Any]:
        d: dict[Any, Any] = {}
        for i in section:
            value = section[i]
            names = i.split(".")
            if type(value) == str:
                if section[i][0] == "\n":
                    d = update_dict(d, join(names, value.split("\n")[1:]))
                else:
                    d = update_dict(d, join(names, value))
            else:
                d = update_dict(d, join(names, explore_cfg(value)))
        return d

    out: dict[Any, Any] = {}
    conf = configparser.ConfigParser()
    conf.read(cfg_file)
    for s in conf.sections():
        names = s.split(".")
        out = update_dict(out, join(names, explore_cfg(conf[s])))
    return out


class Ebuild:
    def __init__(
        self, path_to_pyprojectdottoml: str, path_to_setupcfg: str = ""
    ) -> None:
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
        self.repo = "homepage"
        self.rdepend: dict[str, list[str]] = {"": [""]}
        self.bdepend: dict[str, list[str]] = {"": [""]}
        self.optfeature: list[Optional[str]] = []
        with open(self.path, "rb") as f:
            self.toml = tomllib.load(f)
        if path_to_setupcfg != "":
            self.toml = update_dict(self.toml, convert_cfg_to_dict(path_to_setupcfg))

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
                    self.inherit += " docs"

    def extract_toml(self) -> None:
        raise NotImplementedError("You should not use this class")

    def define_source(self, toml: dict[str, Any]) -> None:
        if "homepage" in toml.keys():
            self.homepage = toml["homepage"]
        if "repository" in toml.keys():
            self.homepage = f"{self.homepage} {toml['repository']}"
            self.repo = "repository"
        if "url" in toml.keys():
            self.homepage = f"{self.homepage} {toml['url']}"
            self.repo = "url"
        self.src_uri = (
            f"{toml[self.repo]}/archive/refs/tags/" + "v${PV}.tar.gz -> ${P}.gh.tar.gz"
        )

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
        f.write(f"DISTUTILS_USE_PEP517={self.tool}\n")
        f.write("PYTHON_COMPAT=( python3_{10..12} )\n")
        if "doc" in self.iuse:
            f.write(f'\nDOCS_BUILDER="{self.doc_package}"\n')
            f.write(f'DOCS_DEPEND=""\n')
            f.write(f'DOCS_DIR="docs"\n')
            if self.doc_package == "mkdocs":
                f.write("DOCS_INITIALIZE_GIT=1\n")
        f.write(f"\ninherit {self.inherit}\n\n")
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
        if "doc" in self.iuse:
            f.write(f"# distutils_enable_sphinx docs\n")
        if self.optfeature != []:
            f.write("\npkg_postinst() {\n")
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
        vers = self.format_version(dep["version"], name)
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

    def get_dependencies(self, dependencies: dict[str, Any] | list[str]) -> list[str]:
        deps = []
        if type(dependencies) == list:
            return [f"dev-python/{d}" for d in dependencies]
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
        self.define_source(toml)
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
        self.tool = "flit"
        self.description = toml["description"]
        self.license = toml["license"]
        self.define_source(toml)
        self.rdepend[""] = self.get_dependencies(self.toml["requires"])


class SetupTools(Ebuild):
    def __init__(self, path_to_pyprojectdottoml: str):
        setup_cfg = f"{os.path.dirname(path_to_pyprojectdottoml)}/setup.cfg"
        if not os.path.isfile(setup_cfg):
            setup_cfg = ""
        super().__init__(path_to_pyprojectdottoml, path_to_setupcfg=setup_cfg)

    def extract_toml(self) -> None:
        self.tool = "setuptools"
        if "metadata" in self.toml.keys():
            toml = self.toml["metadata"]
            self.name = toml["name"]
            self.description = toml["description"]
            self.license = toml["license"]
            self.define_source(toml)
        self.bdepend[""] = self.get_dependencies(self.toml["build-system"]["requires"])
        if "options" in self.toml.keys():
            self.bdepend["extra"] = self.get_dependencies(
                [self.toml["options"]["extras_require"]["dev"]]
            )


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

def find_backend(system: dict[str, Any]) -> str:
    if "build-backend" in system.keys():
        return str(system["build-backend"])
    elif "requires" in system.keys():
        poss = system["requires"]
        if "setuptools" in poss:
            return "setuptools.build_meta"
        elif "flit" in poss:
            return "flit_core.buildapi"
        elif "poetry" in poss:
            return "poetry.core.masonry.api"
    raise KeyError(f"Could not find the backend from {system}")

if len(sys.argv) == 1:
    d = "."
else:
    d = sys.argv[1]

files = search_dir(d)
if len(files) == 0:
    print("No project detected")
for f in files:
    with open(f, "rb") as file:
        tom = tomllib.load(file)
    back = find_backend(tom["build-system"])
    ebuild: Optional[Ebuild] = None
    if back == "poetry.core.masonry.api":
        ebuild = Poetry(f)
    elif back == "flit_core.buildapi":
        ebuild = Flit(f)
    elif back == "setuptools.build_meta":
        ebuild = SetupTools(f)

    if ebuild is not None:
        ebuild.build()
        ebuild.write()
    else:
        print(f"No backend found for {back}")
