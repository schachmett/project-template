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

render() { # render DEST PLATFORM PYTHON IS_SERVICE [GITHUB_OWNER_TYPE]
    "${copier[@]}" copy --quiet --defaults --vcs-ref HEAD \
        -d project_name=demo-project -d org=acme \
        -d forgejo_url=https://forge.example.com \
        -d platform="$2" -d python="$3" -d is_service="$4" -d secrets=env-only \
        -d github_owner_type="${5:-personal}" \
        "$src" "$1" 2>"$work/copier.log" || { cat "$work/copier.log" >&2; return 1; }
}

check() { # check DEST PLATFORM [GITHUB_OWNER_TYPE]
    local dest=$1 platform=$2 cli other recipe
    if [ "$platform" = github ]; then cli=gh other=fj; else cli=fj other=gh; fi

    (cd "$dest" && just --list >/dev/null) || fail "just --list"

    for recipe in "issues" "issues some query" "issue 1" "issue-new Title body.md" \
        "issue-new Title body.md type/bug prio/high" "issue-label 1 type/bug" \
        "issue-unlabel 1 type/bug" "issue-blocked-by 2 1" "issue-unblock 2 1" \
        "issue-close 1 body.md" "labels" "labels-init" \
        "comment 1 body.md" "prs" "pr Title body.md" "pr-view 1" "pr-body 1 body.md" \
        "pr-diff 1" \
        "comment-pr 1 body.md" "releases" "release v1.2.3"; do
        # shellcheck disable=SC2086
        (cd "$dest" && just --dry-run $recipe >/dev/null 2>&1) || fail "just --dry-run $recipe"
    done

    # Sub-issues exist on GitHub only; native issue types only for organisations,
    # which get no type/ labels in return.
    local owner=${3:-personal} want_parent=no want_type=no
    [ "$platform" != github ] || want_parent=yes
    if [ "$platform" = github ] && [ "$owner" = organization ]; then want_type=yes; fi
    has() { (cd "$dest" && just --dry-run "$@" >/dev/null 2>&1) && echo yes || echo no; }
    [ "$(has issue-parent 2 1)" = "$want_parent" ] || fail "issue-parent: expected $want_parent"
    [ "$(has issue-type 1 Bug)" = "$want_type" ] || fail "issue-type: expected $want_type"
    if grep -q "type/bug" "$dest/justfile" "$dest/docs/workflow.md"; then
        [ "$want_type" = no ] || fail "type/ labels in an organisation project"
    else
        [ "$want_type" = yes ] || fail "type/ labels missing"
    fi

    grep -q "^ *\(if .*; then \)\?$cli " "$dest/justfile" || fail "justfile does not call $cli"
    if grep -n "^ *$other " "$dest/justfile"; then fail "justfile calls $other"; fi

    if grep -rn "workflow_style" "$dest"; then fail "workflow_style left in output"; fi

    # Skills, markdown links, removed docs, raw gh/fj commands.
    python3 "$repo/scripts/check_render.py" "$dest" || fail "check_render.py"

    # Every rendered file ends with exactly one newline and has no trailing
    # whitespace, as the end-of-file-fixer and trailing-whitespace hooks demand.
    while IFS= read -r -d '' file; do
        [ -s "$file" ] || continue
        if [ -n "$(tail -c 1 "$file")" ] || [ -z "$(tail -c 2 "$file" | head -c 1 | tr -d '\n')" ] && [ "$(wc -c <"$file")" -gt 1 ]; then
            fail "bad end of file: ${file#"$dest"/}"
        fi
        if grep -qE '[[:blank:]]+$' "$file"; then fail "trailing whitespace: ${file#"$dest"/}"; fi
    done < <(find "$dest" -type f -not -name '*.typed' -print0)

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
            [ "$platform" = github ] || continue
            echo "== $name (organization)"
            if render "$work/$name-org" "$platform" "$python" "$is_service" organization; then
                check "$work/$name-org" "$platform" organization
            else
                fail "copier copy"
            fi
        done
    done
done

# A fresh project must pass its own gates: `just check` and every pre-commit hook.
for python in root component; do
    echo "== fresh project passes its gates ($python)"
    dest="$work/gates-$python"
    if "${copier[@]}" copy --quiet --defaults --vcs-ref HEAD \
        -d project_name=demo-project -d org=acme -d forgejo_url=https://forge.example.com \
        -d platform=forgejo -d python="$python" -d hooks=python -d is_service=true \
        -d secrets=env-only "$src" "$dest" 2>"$work/copier.log"; then
        git -C "$dest" init --quiet --initial-branch feat/fresh
        if [ "$python" = component ]; then pydir="$dest/backend"; else pydir="$dest"; fi
        (cd "$pydir" && uv sync --quiet) || fail "uv sync"
        git -C "$dest" add -A
        (cd "$dest" && just check >"$work/check.log" 2>&1) ||
            { tail -n 40 "$work/check.log" >&2; fail "just check ($python)"; }
        (cd "$dest" && uvx pre-commit run --all-files >"$work/hooks.log" 2>&1) ||
            { tail -n 40 "$work/hooks.log" >&2; fail "pre-commit run --all-files ($python)"; }
    else
        cat "$work/copier.log" >&2
        fail "copier copy"
    fi
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
