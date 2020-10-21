# bioutils

A repository for generally useful bioinformatics tools

## Description

Here, we consolidate scripts for commonly-used functions such as converting filetypes or calculating descriptive statistics.

## Usage

1. Fork the repository into your own Github account
2. Clone your forked repository into a directory of choice and change into the cloned repository e.g. `cd ~/dev/bioutils`
3. Install all binaries into `~/bin/`: `for file in */bin/*; do ln -s $file ~/bin/$(basename "${file%.*}"); done`. Make sure that `~/bin/` is in your PATH, otherwise add `export PATH="$HOME/bin:$PATH"` into your `.bashrc`.

## Contribute

1. Ensure your repository is up to date: `git pull`
2. Make and checkout a new feature branch: `git checkout -B "[branch_name]"`
3. Add changed files to commit: `git add [path/to/files]`
4. Commit files: `git commit -m "[Descriptive message about commit]"`
5. Push commit to Github: `git push`
6. Go to your forked github directory and branch https://github.com/[username]/bioutils on a browser
7. Click on the green "Pull Request" button
8. During code review, repeat steps 3-5 for requested changes
9. When code review completes, the added commits will usually be squashed and merged to master
10. Now you can safely delete the new feature branch and pull the squashed commit from the base repository
