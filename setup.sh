#! /bin/bash
for name in *; do
  if [ ! -d "${name}" ]; then
    target="${HOME}/.${name}"
    if ! [[ "${name}" =~ ^(install.sh|setup.sh|README.sh)$ ]]; then

      if [ -e "${target}" ]; then             # Does the config file already exist?
        if [ ! -L "${target}" ]; then         # as a pure file?
          mv "${target}" "${target}.backup"   # Then backup it
          echo "-----> Moved your old ${target} config file to ${target}.backup"
        fi
      fi

      if [ ! -e "${target}" ]; then
        echo "-----> Symlinking your new ${target}"
        ln -s "${PWD}/${name}" "${target}"
      fi
    fi
  fi
done
