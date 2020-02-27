npm run build-app
rm -rf ./static/css
rm -rf ./static/img
rm -rf ./static/js
rm -f index.html
mv ./dist/static/* ./static
mv ./dist/index.html ./
rm -rf ./dist