#!/usr/bin/env bash
if [ ! -d "./wpp-research" ]; then
	git clone https://github.com/GoogleChromeLabs/wpp-research.git
	(cd ./wpp-research && nvm i && npm ci)
fi

OLD_VERSION=${1-latest}
NEW_VERSION=${2-trunk}

if [[ $OLD_VERSION == 'trunk' ]]; then
	OLD_VERSION='master'
fi

if [[ $NEW_VERSION == 'trunk' ]]; then
	NEW_VERSION='master'
fi

# Install core version
wp core update --version=$OLD_VERSION --force

# Install block theme
wp theme activate twentytwentythree

# Benchmark Web Vitals

npm run research --silent benchmark-web-vitals -u http://wp-test.local/ -n 20 -p -o csv > 2023-cwv-before.csv

# Benchmark Server-Timing

npm run research --silent  benchmark-server-timing -u http://wp-test.local/ -n 100 -p -o csv > 2023-st-before.csv

# Install classic theme

wp theme activate twentytwentyone

# Benchmark Web Vitals

npm run research --silent benchmark-web-vitals -u http://wp-test.local/ -n 20 -p -o csv > 2021-cwv-before.csv

# Benchmark Server-Timing

npm run research --silent  benchmark-server-timing -u http://wp-test.local/ -n 100 -p -o csv > 2021-st-before.csv

# Update to the new version to compare.
wp core update --version=$NEW_VERSION --force

# Benchmark Web Vitals

npm run research --silent benchmark-web-vitals -u http://wp-test.local/ -n 20 -p -o csv > 2023-cwv-after.csv

# Benchmark Server-Timing

npm run research --silent  benchmark-server-timing -u http://wp-test.local/ -n 100 -p -o csv > 2023-st-after.csv

# Install classic theme

wp theme activate twentytwentyone

# Benchmark Web Vitals

npm run research --silent benchmark-web-vitals -u http://wp-test.local/ -n 20 -p -o csv > 2021-cwv-after.csv

# Benchmark Server-Timing

npm run research --silent  benchmark-server-timing -u http://wp-test.local/ -n 100 -p -o csv > 2021-st-after.csv

# Run Reports
node ../scripts/results.js "Web Vitals (Block Theme)" 2023-cwv-before.csv 2023-cwv-after.csv
node ../scripts/results.js "Server-Timing (Block Theme)" 2023-st-before.csv 2023-st-after.csv
node ../scripts/results.js "Web Vitals (Classic Theme)" 2021-cwv-before.csv 2021-cwv-after.csv
node ../scripts/results.js "Server-Timing (Classic Theme)" 2021-st-before.csv 2021-st-after.csv
