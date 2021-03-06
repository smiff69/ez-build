#!/usr/bin/env bats
load test-util

eventually() {
  for try in $(seq 1 30); do
    set +e
    output="$(eval ${@})"
    status=$?
    set -e

    if [[ ${status} == 0 ]]; then
      return 0
    fi
    sleep 1
  done

  echo "${output}"
  return ${status}
}

setup() {
  load_fixture typical-project

  if [[ "${BATS_TEST_NUMBER}" -eq 1 ]]; then
    {
      kill $(cat ez-build.pid) && wait $(cat ez-build.pid)
    } 2>/dev/null

    ${EZ_BUILD_BIN} --interactive 2>&1 > build.log &
    EZPID=$!
    disown ${EZPID}
    echo ${EZPID} > ez-build.pid
  fi
}

teardown() {
  if [[ "$BATS_TEST_NUMBER" -eq "${#BATS_TEST_NAMES[@]}" ]]; then
    {
      kill $(cat ez-build.pid) && wait $(cat ez-build.pid)
    } 2>/dev/null
    rm *.{pid,log}
  fi

  unload_fixture typical-project
}

@test "'ez-build --interactive' should wait for changes" {
  eventually 'assert_equal "Watching source files for changes..." "$(tail -1 build.log)"'
}

@test "'ez-build --interactive' should rebuild files when they are modified" {
  touch src/a.js
  eventually 'assert_equal "js – src/a.js -> lib/a.js,lib/a.js.map" "$(tail -1 build.log)"'
}

@test "'ez-build --interactive' should build files when they are added" {
  refute_exists src/added.js
  touch src/added.js
  eventually 'assert_exists lib/added.js'
  eventually 'assert_exists lib/added.js.map'
}