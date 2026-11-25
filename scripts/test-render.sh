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
        -d github_owner_type="${5:-personal}" -d agents="${AGENTS:-[claude]}" \
        "$src" "$1" 2>"$work/copier.log" || { cat "$work/copier.log" >&2; return 1; }
}

check() { # check DEST PLATFORM [GITHUB_OWNER_TYPE]
    local dest=$1 platform=$2 cli other recipe
    if [ "$platform" = github ]; then cli=gh other=fj; else cli=fj other=gh; fi

    (cd "$dest" && just --list >/dev/null) || fail "just --list"
    grep -qxF "import '.copier/recipes.just'" "$dest/justfile" || fail "root justfile does not import the template recipes"
    [ "$(cd "$dest" && just --dry-run 2>&1)" = "just --list" ] || fail "a bare 'just' does not list the recipes"
    [ ! -e "$dest/.copier-answers.yml" ] && [ -f "$dest/.copier/answers.yml" ] || fail "answers file is not in .copier/"
    [ -f "$dest/.copier/cliff.toml" ] && [ ! -e "$dest/cliff.toml" ] || fail "cliff.toml is not in .copier/"

    if [ -e "$dest/pyproject.toml" ] || [ -d "$dest/backend" ]; then
        [ -n "$(cd "$dest" && just --summary | tr ' ' '\n' | grep -x static)" ] || fail "Python project without static"
    else
        # Without Python the project owns its checks: only a failing `check` stub.
        for unwanted in src tests Dockerfile .python-version; do
            [ ! -e "$dest/$unwanted" ] || fail "$unwanted rendered without Python"
        done
        if grep -rq "uv sync\|setup-uv" "$dest/.forgejo" "$dest/.github" 2>/dev/null; then fail "CI uses uv without Python"; fi
        if (cd "$dest" && just check >/dev/null 2>&1); then fail "the check stub must fail until it is replaced"; fi
        [ -z "$(cd "$dest" && just --summary | tr ' ' '\n' | grep -x -e static -e fix -e setup)" ] || fail "optional recipes rendered as stubs"
        (cd "$dest" && git init --quiet 2>/dev/null; touch x.txt; just stop-check </dev/null) || fail "stop-check must pass without a static recipe"
        rm -f "$dest/x.txt"; rm -rf "$dest/.git"
    fi

    for recipe in "template-update" "doctor" "stop-check" "mddiff" "mddiff develop" "review 1" "issues" "issues some query" "issue 1" "issue-new Title body.md" \
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
    # fj cannot manage branch protection, so forge-protect exists on GitHub only.
    [ "$(has forge-protect)" = "$want_parent" ] || fail "forge-protect: expected $want_parent"
    [ -x "$dest/.copier/setup.sh" ] && bash -n "$dest/.copier/setup.sh" || fail ".copier/setup.sh"
    if grep -q "type/bug" "$dest/.copier/recipes.just" "$dest/docs/workflow.md"; then
        [ "$want_type" = no ] || fail "type/ labels in an organisation project"
    else
        [ "$want_type" = yes ] || fail "type/ labels missing"
    fi

    grep -q "^ *\(if .*; then \)\?$cli " "$dest/.copier/recipes.just" || fail "justfile does not call $cli"
    if grep -n "^ *$other " "$dest/.copier/recipes.just"; then fail "justfile calls $other"; fi

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
    (cd "$dest" && find . -type f -not -path ./.copier/answers.yml -print0 |
        xargs -0 uvx --from detect-secrets==1.5.0 detect-secrets-hook) ||
        fail "detect-secrets reports findings in a fresh project"
}

for platform in forgejo github both; do
    for python in root component none; do
        for is_service in false true; do
            # Services are Python-only.
            if [ "$python" = none ] && [ "$is_service" = true ]; then continue; fi
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

# Adapters are rendered exactly for the selected agents.
check_agents() { # check_agents DEST "claude codex"
    local dest=$1 selected=" $2 "
    if [[ "$selected" == *" claude "* ]]; then
        [ "$(cat "$dest/CLAUDE.md" 2>/dev/null)" = "@AGENTS.md" ] || fail "CLAUDE.md"
        [ -L "$dest/.claude/skills" ] && [ -f "$dest/.claude/skills/plan-issue/SKILL.md" ] ||
            fail ".claude/skills is not a link to the skills"
        python3 -m json.tool "$dest/.claude/settings.json" >/dev/null 2>&1 || fail ".claude/settings.json"
        grep -q "just stop-check" "$dest/.claude/settings.json" || fail "Claude Stop hook"
        grep -q "pr merge" "$dest/.claude/settings.json" || fail "Claude deny rule for merging"
    else
        [ ! -e "$dest/CLAUDE.md" ] && [ ! -e "$dest/.claude" ] || fail "Claude adapter rendered without claude"
    fi
    if [[ "$selected" == *" codex "* ]]; then
        python3 -m json.tool "$dest/.codex/hooks.json" >/dev/null 2>&1 || fail ".codex/hooks.json"
        grep -q "just stop-check" "$dest/.codex/hooks.json" || fail "Codex Stop hook"
        grep -q '"pr", "merge"' "$dest/.codex/rules/default.rules" || fail "Codex rule for merging"
    else
        [ ! -e "$dest/.codex" ] || fail "Codex adapter rendered without codex"
    fi
    local expected=""
    if [[ "$selected" == *" claude "* ]]; then expected="claude -p"; elif [[ "$selected" == *" codex "* ]]; then expected="codex exec -"; fi
    grep -qF "reviewer=\"\${AGENT_REVIEWER:-$expected}\"" "$dest/.copier/recipes.just" || fail "default reviewer is not '$expected'"
    python3 "$repo/scripts/check_render.py" "$dest" || fail "check_render.py"
    (cd "$dest" && just --list >/dev/null) || fail "just --list"
}

for platform in forgejo github; do
    for selection in "" "claude" "codex" "claude codex"; do
        name="agents-$platform-${selection// /+}"
        echo "== $name"
        if AGENTS="[${selection// /, }]" render "$work/$name" "$platform" root false; then
            check_agents "$work/$name" "$selection"
        else
            fail "copier copy"
        fi
    done
done

# A fresh project must pass its own gates: `just check` and every pre-commit hook.
for python in root component; do
    echo "== fresh project passes its gates ($python)"
    dest="$work/gates-$python"
    if "${copier[@]}" copy --quiet --defaults --vcs-ref HEAD \
        -d project_name=demo-project -d org=acme -d forgejo_url=https://forge.example.com \
        -d platform=forgejo -d python="$python" -d hooks=python -d is_service=true \
        -d agents='[claude, codex]' \
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

# Without Python: the invalid combinations are refused, and a project that
# fills in the contract recipes passes its gates.
echo "== python=none"
for bad in "is_service=true" "hooks=python"; do
    if "${copier[@]}" copy --quiet --defaults --vcs-ref HEAD -d project_name=demo-project \
        -d platform=github -d python=none -d "$bad" "$src" "$work/bad-$bad" >/dev/null 2>&1; then
        fail "python=none with $bad was accepted"
    fi
done
dest="$work/gates-none"
if "${copier[@]}" copy --quiet --defaults --vcs-ref HEAD \
    -d project_name=demo-project -d org=acme -d forgejo_url=https://forge.example.com \
    -d platform=forgejo -d python=none -d hooks=minimal -d secrets=env-only \
    -d agents='[claude, codex]' "$src" "$dest" 2>"$work/copier.log"; then
    git -C "$dest" init --quiet --initial-branch feat/fresh
    cat >>"$dest/justfile" <<'RECIPES'

setup:
    @touch .setup-ran

static:
    @test ! -e broken.txt

check: static
    @echo checked
RECIPES
    git -C "$dest" add -A
    [ "$(cd "$dest" && just check 2>/dev/null)" = checked ] || fail "project check does not replace the stub"
    (cd "$dest" && touch broken.txt && ! just stop-check </dev/null >/dev/null 2>&1) || fail "stop-check ignores a failing static"
    rm -f "$dest/broken.txt"
    (cd "$dest" && uvx pre-commit run --all-files >"$work/hooks.log" 2>&1) ||
        { tail -n 40 "$work/hooks.log" >&2; fail "pre-commit run --all-files (none)"; }
    # The CI step and the setup script run `setup` only when it exists.
    step=$(sed -n 's/^ *run: \(if just --summary.*\)$/\1/p' "$dest/.forgejo/workflows/ci.yml")
    (cd "$dest" && bash -c "$step" && [ -e .setup-ran ]) || fail "CI setup step"
    # An update keeps the project without Python.
    git -C "$dest" add -A
    git -C "$dest" -c user.name=test -c user.email=test@example.com commit --quiet --no-verify -m "initial"
    (cd "$dest" && just template-update --quiet --defaults --vcs-ref HEAD >"$work/update.log" 2>&1) ||
        { cat "$work/update.log" >&2; fail "copier update (none)"; }
    [ ! -e "$dest/pyproject.toml" ] && [ ! -e "$dest/src" ] || fail "update added a Python skeleton"
else
    cat "$work/copier.log" >&2
    fail "copier copy (none)"
fi

# A project generated when the template still had `workflow_style` must update cleanly.
echo "== update with stale workflow_style answer"
dest="$work/stale-answer"
if render "$dest" forgejo root false; then
    echo "workflow_style: direct" >>"$dest/.copier/answers.yml"
    # The root justfile is the project's: an update must leave its changes alone,
    # and a recipe defined there must win over the template's.
    printf '\ncheck:\n    @echo project-check\n' >>"$dest/justfile"
    git -C "$dest" init --quiet
    git -C "$dest" add -A
    git -C "$dest" -c user.name=test -c user.email=test@example.com \
        commit --quiet --no-verify -m "initial"
    (cd "$dest" && just template-update --quiet --defaults --vcs-ref HEAD >"$work/update.log" 2>&1) ||
        { cat "$work/update.log" >&2; fail "copier update"; }
    if find "$dest" -name '*.rej' | grep -q .; then fail "copier update left .rej files"; fi
    grep -q "project-check" "$dest/justfile" || fail "update overwrote the project's justfile"
    [ "$(cd "$dest" && just check 2>/dev/null)" = "project-check" ] || fail "project recipe does not override the template's"
    if grep -q workflow_style "$dest/.copier/answers.yml"; then fail "stale answer survived the update"; fi
else
    fail "copier copy"
fi

if [ "$failures" -gt 0 ]; then
    echo "$failures check(s) failed" >&2
    exit 1
fi
echo "all render checks passed"
