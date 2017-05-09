# disk.o
Bash-Script to recursively index disks or directories as browseable, searchable HTML files.

## Usage
`./disko.sh inputpath diskname`

where `inputpath` is the directory the recursive indexing will start    
and `diskname` is a string your HTML file will be named    

The HTML files are generated into the current working directory.    
The `diskolib` dir needs to be there as well for the generated HTML to work properly.

## Note
Written for/on OS X.    
Makes use of homebrew's `gls` and `gfind`, so install these prior using.    
Should work on GNU/Linux with `ls` and `find`    

Written for personal use, not extensively tested yet, so use at own risk.
