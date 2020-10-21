# bioutils

A repository for generally useful bioinformatics tools

# Description

Here, we will consolidate scripts for commonly-used functions such as converting filetypes or calculating descriptive statitics.

# Usage

1. Fork the repository into your own Github account
2. Clone your forked repository into a directory of choice and change into the cloned repository e.g. `cd ~/dev/bioutils`
3. Install all binaries into `~/bin/`: `for file in bioutils/*/bin/*;do ln -s $file ~/bin/$(basename "${file%.*}");done`

# Making changes

1. Ensure your repository is up to date: `git pull`
2. Make and checkout a new branch: `git checkout -B "[branch_name]"`
3. Add changed files to commit: `git add [path/to/files]`
4. Commit files: `git commit -m "[Descriptive message about commit]"`
5. Push commit to Github: `git push`
6. Go to your forked github directory and branch https://github.com/[username]/bioutils on a browser
7. Click on the green "Pull Request" button
8. Repeat steps 3-5 for any additional changes
9. Squash branch and merge to master
10. Merge to origin master repository
