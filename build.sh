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
mkdir target

generate_script install
generate_script setup
generate_script extra
generate_script disk-add
generate_script utils
