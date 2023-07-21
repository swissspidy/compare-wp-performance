#!/usr/bin/env bash

if ! command -v wp-env &> /dev/null; then
    echo "wp-env not installed globally. Run \`npm i -g @wordpress/env\`"
    exit
fi

# Install wpp-research if missing

if [ ! -d "./wpp-research" ]; then
	git clone https://github.com/GoogleChromeLabs/wpp-research.git
	(cd ./wpp-research && nvm i && npm ci)
fi

OLD_VERSION=${1-latest}
NEW_VERSION=${2-trunk}

# Configure WordPress versions

if [[ $OLD_VERSION == 'trunk' ]]; then
	OLD_VERSION='master'
fi

if [[ $NEW_VERSION == 'trunk' ]]; then
	NEW_VERSION='master'
fi

echo "Old version: $OLD_VERSION"

if [[ $OLD_VERSION != 'latest' ]]; then
	echo "{\"core\":\"WordPress/WordPress#$OLD_VERSION\"}" > old/.wp-env.override.json
fi

echo "New version: $NEW_VERSION"
echo "{\"core\":\"WordPress/WordPress#$NEW_VERSION\"}" > new/.wp-env.override.json

# Install WordPress

(cd old && wp-env start)
(cd new && wp-env start)

# Update permalink structure

(cd old && wp-env run tests-cli wp rewrite structure '/%postname%/' -- --hard)
(cd new && wp-env run tests-cli wp rewrite structure '/%postname%/' -- --hard)

# Import mock data

(cd old && wp-env run tests-cli curl https://raw.githubusercontent.com/WordPress/theme-test-data/b9752e0533a5acbb876951a8cbb5bcc69a56474c/themeunittestdata.wordpress.xml -- --output /tmp/themeunittestdata.wordpress.xml)
(cd old && wp-env run tests-cli wp import /tmp/themeunittestdata.wordpress.xml -- --authors=create)
(cd new && wp-env run tests-cli curl https://raw.githubusercontent.com/WordPress/theme-test-data/b9752e0533a5acbb876951a8cbb5bcc69a56474c/themeunittestdata.wordpress.xml -- --output /tmp/themeunittestdata.wordpress.xml)
(cd new && wp-env run tests-cli wp import /tmp/themeunittestdata.wordpress.xml -- --authors=create)

# Deactivate WordPress Importer

(cd old && wp-env run tests-cli wp plugin deactivate wordpress-importer)
(cd new && wp-env run tests-cli wp plugin deactivate wordpress-importer)

# Install block theme

(cd old && wp-env run tests-cli wp theme activate twentytwentythree)
(cd new && wp-env run tests-cli wp theme activate twentytwentythree)

cd ./wpp-research || exit

# Benchmark Web Vitals

npm run research --silent -- benchmark-web-vitals -u http://localhost:8881/ -n 20 -p -o csv > before.csv
npm run research --silent -- benchmark-web-vitals -u http://localhost:8891/ -n 20 -p -o csv > after.csv
node ../scripts/results.js "Web Vitals (Block Theme)" before.csv after.csv

# Benchmark Server-Timing

npm run research --silent  -- benchmark-server-timing -u http://localhost:8881/ -n 100 -p -o csv > before.csv
npm run research --silent  -- benchmark-server-timing -u http://localhost:8891/ -n 100 -p -o csv > after.csv
node ../scripts/results.js "Server-Timing (Block Theme)" before.csv after.csv

# Install classic theme

cd ../
(cd old && wp-env run tests-cli wp theme activate twentytwentyone)
(cd new && wp-env run tests-cli wp theme activate twentytwentyone)

cd ./wpp-research || exit

# Benchmark Web Vitals

npm run research --silent -- benchmark-web-vitals -u http://localhost:8881/ -n 20 -p -o csv > before.csv
npm run research --silent -- benchmark-web-vitals -u http://localhost:8891/ -n 20 -p -o csv > after.csv
node ../scripts/results.js "Web Vitals (Classic Theme)" before.csv after.csv

# Benchmark Server-Timing

npm run research --silent  -- benchmark-server-timing -u http://localhost:8881/ -n 100 -p -o csv > before.csv
npm run research --silent  -- benchmark-server-timing -u http://localhost:8891/ -n 100 -p -o csv > after.csv
node ../scripts/results.js "Server-Timing (Classic Theme)" before.csv after.csv
