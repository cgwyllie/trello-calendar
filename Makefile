
default:
	hulk app/templates/*.mustache > app/templates.js
	echo "module.exports = templates;" >> app/templates.js
	stitchup -o public/app.js -m DEVELOPMENT app
	rm app/templates.js
	lessc -x app/less/app.less > public/app.css

clean:
	rm public/app.js
	rm public/app.css
