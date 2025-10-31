#!/usr/bin/env bash

# Install wpp-research if missing

if [ ! -d "./wpp-research" ]; then
	git clone https://github.com/GoogleChromeLabs/wpp-research.git
	(cd ./wpp-research && nvm i && npm ci)
fi

OLD_VERSION=${1-latest}
NEW_VERSION=${2-trunk}
THEME=${3-twentytwentyone}
SKIP_INIT=${4-false}
OUTPUT=${5-markdown}
SKIP_FORMATTING=${6-false}
PRINT_TO_FILES=${7-false}

# Configure WordPress versions

rm -rf old/.wp-env.override.json
rm -rf new/.wp-env.override.json

if [[ $OLD_VERSION == 'trunk' ]]; then
	OLD_VERSION='master'
fi

if [[ $NEW_VERSION == 'trunk' ]]; then
	NEW_VERSION='master'
fi

echo "Old version: $OLD_VERSION"

if [[ $OLD_VERSION != 'latest' ]]; then
	if [[ "$OLD_VERSION" == *".zip"* ]]; then
		echo "{\"core\":\"$OLD_VERSION\"}" >> old/.wp-env.override.json
	else
		echo "{\"core\":\"WordPress/WordPress#$OLD_VERSION\"}" >> old/.wp-env.override.json
	fi
fi

echo "New version: $NEW_VERSION"

if [[ "$NEW_VERSION" == *".zip"* ]]; then
	echo "{\"core\":\"$NEW_VERSION\"}" >> new/.wp-env.override.json
else
	echo "{\"core\":\"WordPress/WordPress#$NEW_VERSION\"}" >> new/.wp-env.override.json
fi

if [[ $SKIP_INIT != 'true' ]]; then

	# Install WordPress

	(cd old && npm i && npm run wp-env --silent start)
	(cd new && npm i && npm run wp-env --silent start)

	# Update permalink structure

	(cd old && npm run wp-env --silent run tests-cli wp rewrite structure '/%postname%/' -- --hard)
	(cd new && npm run wp-env --silent run tests-cli wp rewrite structure '/%postname%/' -- --hard)

	# Delete any data that might already exist by re-installing WordPress.
	# Prevents mock data from being duplicated on subsequent runs.

	(cd old && npm run wp-env --silent run tests-cli wp db reset -- --yes)
	(cd old && npm run wp-env --silent run tests-cli wp core install -- --url=http://localhost:8891 --title=old --admin_user=admin --admin_password=password --admin_email=wordpress@example.com --skip-email)
	(cd new && npm run wp-env --silent run tests-cli wp db reset -- --yes)
	(cd new && npm run wp-env --silent run tests-cli wp core install -- --url=http://localhost:8881 --title=new --admin_user=admin --admin_password=password --admin_email=wordpress@example.com --skip-email)

	# Activate plugins (again)

	(cd old && npm run wp-env --silent run tests-cli wp plugin activate performance-lab wordpress-importer)
	(cd new && npm run wp-env --silent run tests-cli wp plugin activate performance-lab wordpress-importer)

	# Import mock data

	(cd old && npm run wp-env --silent run tests-cli curl https://raw.githubusercontent.com/WordPress/theme-test-data/b9752e0533a5acbb876951a8cbb5bcc69a56474c/themeunittestdata.wordpress.xml -- --output /tmp/themeunittestdata.wordpress.xml)
	(cd old && npm run wp-env --silent run tests-cli wp import /tmp/themeunittestdata.wordpress.xml -- --authors=create)
	(cd new && npm run wp-env --silent run tests-cli curl https://raw.githubusercontent.com/WordPress/theme-test-data/b9752e0533a5acbb876951a8cbb5bcc69a56474c/themeunittestdata.wordpress.xml -- --output /tmp/themeunittestdata.wordpress.xml)
	(cd new && npm run wp-env --silent run tests-cli wp import /tmp/themeunittestdata.wordpress.xml -- --authors=create)

	# Deactivate WordPress Importer

	(cd old && npm run wp-env --silent run tests-cli wp plugin deactivate wordpress-importer)
	(cd new && npm run wp-env --silent run tests-cli wp plugin deactivate wordpress-importer)

else

	(cd old && npm run wp-env --silent start)
	(cd new && npm run wp-env --silent start)

fi

# Install theme

(cd old && npm run wp-env --silent run tests-cli wp theme activate $THEME)
(cd new && npm run wp-env --silent run tests-cli wp theme activate $THEME)

## Post debuging info.
echo "Old version – Theme info"
(cd old && npm run wp-env run tests-cli wp theme list)

echo "New version – Theme info"
(cd new && npm run wp-env run tests-cli wp theme list)

cd ./wpp-research || exit

# Benchmark Web Vitals

npm run research --silent -- benchmark-web-vitals -u http://localhost:8881/ -n 20 -c "Fast 4G" -p -o csv > before.csv
npm run research --silent -- benchmark-web-vitals -u http://localhost:8891/ -n 20 -c "Fast 4G" -p -o csv > after.csv
if [[ $PRINT_TO_FILES == 'true' ]]; then
	if [[ $OUTPUT == 'csv' ]]; then
		node ../scripts/results.js "Web Vitals ($THEME)" before.csv after.csv $OUTPUT $SKIP_FORMATTING > web-vitals-$THEME.csv
	else
		node ../scripts/results.js "Web Vitals ($THEME)" before.csv after.csv $OUTPUT $SKIP_FORMATTING > web-vitals-$THEME.md
	fi
else
	node ../scripts/results.js "Web Vitals ($THEME)" before.csv after.csv $OUTPUT $SKIP_FORMATTING
fi

# Benchmark Server-Timing

npm run research --silent  -- benchmark-server-timing -u http://localhost:8881/ -n 100 -p -o csv > before.csv
npm run research --silent  -- benchmark-server-timing -u http://localhost:8891/ -n 100 -p -o csv > after.csv
if [[ $PRINT_TO_FILES == 'true' ]]; then
	if [[ $OUTPUT == 'csv' ]]; then
		node ../scripts/results.js "Server-Timing ($THEME)" before.csv after.csv $OUTPUT $SKIP_FORMATTING > server-timing-$THEME.csv
	else
		node ../scripts/results.js "Server-Timing ($THEME)" before.csv after.csv $OUTPUT $SKIP_FORMATTING > server-timing-$THEME.md
	fi
else
	node ../scripts/results.js "Server-Timing ($THEME)" before.csv after.csv $OUTPUT $SKIP_FORMATTING
fi

# Shutdown sites again

cd ../
(cd old && npm run wp-env --silent stop)
(cd new && npm run wp-env --silent stop)
