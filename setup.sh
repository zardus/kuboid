#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"/scripts
ADMIN_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"/admin

if ! which pod_names >/dev/null
then
	echo "Adding kuboid to bashrc."
	cat <<END >> ~/.bashrc
# kuboid
export PATH=$SCRIPT_DIR:\$PATH
export PATH=$ADMIN_DIR:\$PATH
END
fi
