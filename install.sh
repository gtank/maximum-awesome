#!/bin/bash

DISTRO=$(lsb_release -is)
INSTALLDIR=$HOME
INSTALLCMD="aptitude -y -q install"
PWD=$(pwd)

# install_github_bundle <user> <repo>
install_github_bundle() {
	echo "Installing bundle github.com/${1}/${2}..."

	local git_url="https://github.com/${1}/${2}.git"
	local bundle_dir="${INSTALLDIR}/.vim/bundle/${2}"

	if [ -d "${bundle_dir}" ]; then
		echo -e "\tdirectory already exists, skipping ${2}"
		return
	fi

	git clone ${git_url} ${bundle_dir}
}

install_system_package() {
	echo -e "\tInstalling ${1}..."
        sudo bash -c "${INSTALLCMD} ${1}"
}

distro_install_cmd() {
	local cmd=""
	case "${DISTRO}" in
		"Fedora")
			if [ ! -z "$(which dnf)" ]; then
				cmd="dnf -y -q install"
			else
				cmd="yum -y -q install"
			fi
			;;
		"Ubuntu")
			cmd="aptitude -y -q install"
			;;
	esac

	[[ ! -z "${cmd}" ]] && INSTALLCMD=${cmd}
}

declare -A COPIED_FILES
declare -A LINKED_FILES
declare -a PACKAGES

COPIED_FILES=(
	["vimrc.local"]="${INSTALLDIR}/.vimrc.local" \
	["vimrc.bundles.local"]="${INSTALLDIR}/.vimrc.bundles.local" \
	["tmux.conf.local"]="${INSTALLDIR}/.tmux.conf.local" \
)

LINKED_FILES=(
	["vim"]="${INSTALLDIR}/.vim" \
        ["vim"]="${INSTALLDIR}/.nvim" \
	["tmux-linux.conf"]="${INSTALLDIR}/.tmux.conf" \
	["vimrc"]="${INSTALLDIR}/.vimrc" \
	["vimrc"]="${INSTALLDIR}/.nvimrc" \
	["vimrc.bundles"]="${INSTALLDIR}/.vimrc.bundles" \
)

PACKAGES=(
	"the_silver_searcher" \
	"ctags" \
	"tmux" \
	"vim" \
	"git" \
)

echo -e "# Beginning maximum-awesome installation\n"

echo "# Copying files"
for copy_file in "${!COPIED_FILES[@]}"; do
	target=${COPIED_FILES["${copy_file}"]}
	echo -e "\t${copy_file} => ${target}"
	cp "${copy_file}" "${target}" 2>/dev/null
done

echo "# Linking files"
for file in "${!LINKED_FILES[@]}"; do
	target=${LINKED_FILES["${file}"]}
	echo -e "\t${file} => ${target}"
	ln -s "${PWD}/${file}" "${target}" 2>/dev/null
done

echo "# Installing packages"
distro_install_cmd
for package in ${PACKAGES[@]}; do
	install_system_package "${package}" 2>/dev/null
done

echo "# Installing vundle"
install_github_bundle "gmarik" "vundle"
vim -c "PluginInstall!" -c "q" -c "q"

echo "# Installing Solarized colorscheme for Gnome Terminal"
if [ ! -e "/usr/bin/dconf" ]; then
	case "${DISTRO}" in
		"Fedora")
			install_system_package "dconf"
			;;
		"Ubuntu")
			install_system_package "dconf-cli"
			;;
	esac
fi

if [ ! -d "./gnome-terminal-colors-solarized" ]; then
	git clone "https://github.com/Anthony25/gnome-terminal-colors-solarized.git"
fi

if [ -d "./gnome-terminal-colors-solarized" ]; then
	cd gnome-terminal-colors-solarized
	./install.sh
fi
