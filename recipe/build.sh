#!/usr/bin/env bash

build_linux()
{
    find -type f -exec sed -i'' "s|/etc/cni/net\.d|$PREFIX/etc/cni/net\.d|g" {} \;
    ./build_linux.sh

    mkdir -p "$PREFIX/lib/cni"
    cp -avf bin/* "$PREFIX/lib/cni"
}

case $(uname -s) in
    "Linux")
        build_linux
        ;;
esac


# If/when https://github.com/conda/conda-build/issues/4121 is supported, the
# following can be greatly simplified.
gather_licenses() {
  # shellcheck disable=SC2039  # Allow widely supported non-POSIX local keyword.
  local module output tmp_dir acc_dir
  output="${1}"
  shift
  tmp_dir="$(pwd)/gather-licenses-tmp"
  acc_dir="$(pwd)/gather-licenses-acc"
  mkdir "${acc_dir}"
  cat > "${output}" <<'EOF'
--------------------------------------------------------------------------------
The output below is generated with `go-licenses csv` and `go-licenses save`.
================================================================================
EOF
  for module ; do
    cat >> "${output}" <<EOF

go-licenses csv ${module}
================================================================================
EOF
    go-licenses csv "${module}" | sort >> "${output}"
    go-licenses save "${module}" --save_path="${tmp_dir}"
    chmod -R +rw "${acc_dir}" "${tmp_dir}"
    cp -r "${tmp_dir}"/* "${acc_dir}"/
    rm -r "${tmp_dir}"
  done
  # shellcheck disable=SC2016  # Not expanding $ in single quotes intentional.
  find "${acc_dir}" -type f | sort | xargs -L1 sh -c '
cat <<EOF

--------------------------------------------------------------------------------
${2#${1%/}/}
================================================================================
EOF
cat "${2}"
' -- "${acc_dir}" >> "${output}"
  rm -r "${acc_dir}"
}

pushd plugins
plugins="$(
  find meta main ipam \
    -mindepth 1 -maxdepth 1 -type d \! -name windows
)"
popd
export GOPATH="$(pwd)/gopath"

# shellcheck disable=SC2046,SC2086  # Expansion of $(...) / ${...} intentional.
gather_licenses ./thirdparty-licenses.txt \
  $( printf 'github.com/containernetworking/plugins/plugins/%s\n' ${plugins} )
