#!/bin/bash

trap '{ echo -e "error ${?}\nthe command executing at the time of the error was\n${BASH_COMMAND}\non line ${BASH_LINENO[0]}" && tail -n 10 ${INSTALL_LOG} && exit $? }' ERR

export DEBIAN_FRONTEND="noninteractive"

# Packages
export PACKAGES=(
	'nginx'
	'php5-fpm'
	'php5-mysql'
	'php-apc'
	'php5-imagick'
	'php5-imap'
	'php5-mcrypt'
	'php5-gd'
	'libssh2-php'
	'git'
	'php5-cli'
	'curl'
	'php5-curl'
	'php5-memcached'
	'php5-geoip'
	'php5-dev'
)

pre_install() {
    apt-key adv --keyserver keyserver.ubuntu.com --recv-keys ABF5BD827BD9BF62 2>&1 || return 1
    echo 'deb http://nginx.org/packages/mainline/debian jessie nginx' > /etc/apt/sources.list.d/nginx-mainline-jessie.list 2>&1 || return 1
    
	apt-get update -q 2>&1 || return 1
	apt-get install -yq ${PACKAGES[@]} 2>&1 || return 1

	curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/bin 2>&1 || return 1

    chmod +x /usr/local/bin/* 2>&1 || return 1

    return 0
}

install_piwik() {
    git clone https://github.com/piwik/piwik.git /data 2>&1 || return 1
    cd /data 2>&1 || return 1

    git submodule init 2>&1 || return 1
    git submodule update 2>&1 || return 1

    /usr/bin/composer.phar install --no-dev --optimize-autoloader --no-interaction  2>&1 || return 1
    chown -R www-data:www-data /data 2>&1 || return 1

    mv /data/config /var/lib/piwik/ 2>&1 || return 1
    ln -s /var/lib/piwik/config /data/config 2>&1 || return 1

    mv /data/plugins /var/lib/piwik/ 2>&1 || return 1
    ln -s /var/lib/piwik/plugins /data/plugins 2>&1 || return 1

    return 0
}

post_install() {
    apt-get autoremove 2>&1 || return 1
	apt-get autoclean 2>&1 || return 1
	rm -fr /var/lib/apt /usr/src/build 2>&1 || return 1

	return 0
}

build() {
	if [ ! -f "${INSTALL_LOG}" ]
	then
		touch "${INSTALL_LOG}" || exit 1
	fi

	tasks=(
        'pre_install'
        'install_piwik'
	)

	for task in ${tasks[@]}
	do
		echo "Running build task ${task}..." || exit 1
		${task} | tee -a "${INSTALL_LOG}" || exit 1
	done
}

if [ $# -eq 0 ]
then
	echo "No parameters given! (${@})"
	echo "Available functions:"
	echo

	compgen -A function

	exit 1
else
	for task in ${@}
	do
		echo "Running ${task}..." 2>&1 || exit 1
		${task} || exit 1
	done
fi
