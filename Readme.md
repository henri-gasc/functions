# My functions

## Information

You will need to create a `GITDIR` variable which point to the root of all git repo.  
(If you don't know how, you type `cd ~`, then modify/create a file named `.profile` and add `export GITDIR="..."` in it.)  
There are explanations below for all functions.

### Update Git

Use `update_git` (without arguments) to update all repositories (and sub-repo) found in `GITDIR`, whereas use `update_git repo1 repo2 ...` to update only them.  
/!\ The root is considered to be `GITDIR`, if you want to update a project that is in a subdirectory of `GITDIR` or one that is 'next' to it, you need to use the path relative to `GITDIR`.

### Clean Git

When using `clean_git`, the program will loop through each folder and use `git gc --agressive` every time, along with showing the size evolution.

## Installation

Use `make install` as root to install the file in the `/usr/bin` folder as `update_git`.  
To customize either the name or the directory to install, you have to modify the Makefile.
