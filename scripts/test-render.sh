#!/usr/bin/env bash
# Render the template for every platform × python × is_service combination and
# check the result. Run via `just test-render` from the template repo root.
set -euo pipefail

repo=$(git rev-parse --show-toplevel)
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
copier=(uvx copier)
failures=0

# Render from a snapshot of the template files as they are in the working tree
# (committed or not), so unrelated untracked files in the repo cannot interfere.
src="$work/template-src"
mkdir "$src"
(cd "$repo" && git ls-files -co --exclude-standard -z -- copier.yaml template _shared |
    tar --null -T - -cf - | tar -xf - -C "$src")
git -C "$src" init --quiet
git -C "$src" add -A
git -C "$src" -c user.name=test -c user.email=test@example.com \
    commit --quiet --no-verify -m "snapshot"

fail() {
    echo "  FAIL: $*" >&2
    failures=$((failures + 1))
}

render() { # render DEST PLATFORM PYTHON IS_SERVICE
    "${copier[@]}" copy --quiet --defaults --vcs-ref HEAD \
        -d project_name=demo-project -d org=acme \
        -d forgejo_url=https://forge.example.com \
        -d platform="$2" -d python="$3" -d is_service="$4" -d secrets=env-only \
        "$src" "$1" 2>"$work/copier.log" || { cat "$work/copier.log" >&2; return 1; }
}

check() { # check DEST PLATFORM
    local dest=$1 platform=$2 cli other recipe
    if [ "$platform" = github ]; then cli=gh other=fj; else cli=fj other=gh; fi

    (cd "$dest" && just --list >/dev/null) || fail "just --list"

    for recipe in "issues" "issues some query" "issue 1" "issue-new Title body.md" \
        "comment 1 body.md" "prs" "pr Title body.md" "pr-diff 1" \
        "comment-pr 1 body.md" "releases" "release v1.2.3"; do
        # shellcheck disable=SC2086
        (cd "$dest" && just --dry-run $recipe >/dev/null 2>&1) || fail "just --dry-run $recipe"
    done

    grep -q "^ *\(if .*; then \)\?$cli " "$dest/justfile" || fail "justfile does not call $cli"
    if grep -n "^ *$other " "$dest/justfile"; then fail "justfile calls $other"; fi

    if grep -rn "workflow_style" "$dest"; then fail "workflow_style left in output"; fi

    # No raw forge CLI commands in the docs — everything goes through just.
    if grep -rnE '(^|[`[:space:]])(gh|fj) (issue|pr|release|repo)\b' \
        "$dest/AGENTS.md" "$dest/README.md" "$dest/docs"; then
        fail "raw gh/fj command in rendered docs"
    fi

    # The pre-commit config must load, and a fresh project must not trip
    # detect-secrets (pre-commit itself excludes the answers file).
    (cd "$dest" && uvx pre-commit validate-config .pre-commit-config.yaml >/dev/null) ||
        fail "invalid .pre-commit-config.yaml"
    (cd "$dest" && find . -type f -not -name .copier-answers.yml -print0 |
        xargs -0 uvx --from detect-secrets==1.5.0 detect-secrets-hook) ||
        fail "detect-secrets reports findings in a fresh project"
}

for platform in forgejo github both; do
    for python in root component; do
        for is_service in false true; do
            name="$platform-$python-service_$is_service"
            echo "== $name"
            if render "$work/$name" "$platform" "$python" "$is_service"; then
                check "$work/$name" "$platform"
            else
                fail "copier copy"
            fi
        done
    done
done

# A project generated when the template still had `workflow_style` must update cleanly.
echo "== update with stale workflow_style answer"
dest="$work/stale-answer"
if render "$dest" forgejo root false; then
    echo "workflow_style: direct" >>"$dest/.copier-answers.yml"
    git -C "$dest" init --quiet
    git -C "$dest" add -A
    git -C "$dest" -c user.name=test -c user.email=test@example.com \
        commit --quiet --no-verify -m "initial"
    (cd "$dest" && "${copier[@]}" update --quiet --defaults --vcs-ref HEAD >"$work/update.log" 2>&1) ||
        { cat "$work/update.log" >&2; fail "copier update"; }
    if find "$dest" -name '*.rej' | grep -q .; then fail "copier update left .rej files"; fi
else
    fail "copier copy"
fi

if [ "$failures" -gt 0 ]; then
    echo "$failures check(s) failed" >&2
    exit 1
fi
echo "all render checks passed"
