#!/bin/sh

function generate_script {
  echo '#!/bin/sh' > target/$1.sh
  echo >> target/$1.sh
  # echo 'set -x' >> target/$1.sh
  # echo >> target/$1.sh

  sed --quiet '/^```sh/,/^```/ p' < $1.md | sed '/^```sh/ d' | sed 's/^```//g' >> target/$1.sh

  chmod u+x target/$1.sh
}

rm --recursive --force target
mkdir --parents target/utils

generate_script disk-add
generate_script install
generate_script setup-base
generate_script setup-laptop

generate_script utils/cpu
generate_script utils/disk
generate_script utils/misc
generate_script utils/swap
generate_script utils/user
