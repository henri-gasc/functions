# Update Git

## Information

You will need to create a `GITDIR` variable which point to the root of all git repo.  
Use `update_git` (without arguments) to update all repositories (and sub-repo) found in `GITDIR`, whereas use `update_git repo1 repo2 ...` to update only them.  
/!\ The root is considered to be `GITDIR`, if you want to update a project that is in a subdirectory of `GITDIR` or one that is 'next' to it, you need to use the path relative to `GITDIR`.

## Installation

Use `make install` as root to install the file in the `/usr/bin` folder as `update_git`.  
To customize either the name or the directory to install, you have to modify the Makefile.
