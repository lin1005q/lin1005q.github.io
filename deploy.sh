rm -rf _site
npm run build
upx sync --delete _site /
