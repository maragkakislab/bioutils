# bioutils

A repository for generally useful bioinformatics tools

# Description

Here, we will consolidate scripts for commonly-used functions such as converting filetypes or calculating descriptive statitics.

# Usage

1. Go to https://github.com/maragkakislab/bioutils and fork the repository to your own Github account
2. Go to a directory of choice to install bioutils, suggest `~/dev`: `cd ~/dev`
3. Clone the repository into your directory: `git clone https://github.com/[username]/bioutils`
4. Install all binaries into `~/bin/`: `for file in bioutils/*/bin/*;do ln -s $file ~/bin/$(basename "${file%.*}");done`

# Making changes

1. Ensure your repository is up to date: `git pull`
2. Add changed files to commit: `git add [path/to/files]
3. Commit files: `git commit -m "[Descriptive message about commit]"
4. Go to your forked github directory https://github.com/[username]/bioutils on a browser
5. Click on the green "Pull Request" button
WIP

