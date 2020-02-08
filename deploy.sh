rm -rf _site
jekyll build
upx sync --delete _site /
