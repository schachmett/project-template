"""Checks on one rendered project that are awkward in shell.

Usage: check_render.py [--no-releases] PROJECT_DIR

--no-releases: the project was rendered with releases=false, so the release
skill must be absent.

Prints one line per problem and exits non-zero if there is any.
"""

import re
import sys
from pathlib import Path

SKILLS = ("plan-issue", "implement-issue", "review-pr")
RELEASE_SKILL = "release"
LINK = re.compile(r"\[[^\]]*\]\(([^)\s]+)\)")
RAW_FORGE_CLI = re.compile(r"(^|[`\s])(gh|fj) (-H \S+ )?(issue|pr|release|repo|milestone|label|api)\b", re.MULTILINE)
REMOVED_DOCS = ("agent-workflow.md", "quality-gates.md", "docs/testing.md")


def check_skills(root: Path, releases: bool) -> list[str]:
    problems: list[str] = []
    if not releases and (root / ".agents" / "skills" / RELEASE_SKILL).exists():
        problems.append(f"unexpected skill: {RELEASE_SKILL}")
    for name in (*SKILLS, RELEASE_SKILL) if releases else SKILLS:
        path = root / ".agents" / "skills" / name / "SKILL.md"
        if not path.is_file():
            problems.append(f"missing skill: {name}")
            continue
        text = path.read_text()
        match = re.match(r"---\n(.*?)\n---\n", text, re.DOTALL)
        if match is None:
            problems.append(f"{name}: no frontmatter")
            continue
        fields = dict(line.split(": ", 1) for line in match.group(1).splitlines() if ": " in line)
        if fields.get("name") != name:
            problems.append(f"{name}: frontmatter name is {fields.get('name')!r}")
        if not fields.get("description"):
            problems.append(f"{name}: no description")
    return problems


def check_markdown(root: Path) -> list[str]:
    problems: list[str] = []
    for path in sorted(root.rglob("*.md")):
        if ".venv" in path.parts or ".git" in path.parts:
            continue
        rel = path.relative_to(root)
        text = path.read_text()
        prose = re.sub(r"```.*?```", "", text, flags=re.DOTALL)
        for target in LINK.findall(prose):
            if re.match(r"[a-z]+:", target) or target.startswith("#"):
                continue
            file_part = target.split("#", 1)[0]
            if not (path.parent / file_part).exists():
                problems.append(f"{rel}: broken link {target}")
        for removed in REMOVED_DOCS:
            if removed in text:
                problems.append(f"{rel}: mentions removed doc {removed}")
        if RAW_FORGE_CLI.search(text):
            problems.append(f"{rel}: raw gh/fj command")
    return problems


def main() -> int:
    args = sys.argv[1:]
    releases = "--no-releases" not in args
    root = Path(next(arg for arg in args if arg != "--no-releases"))
    problems = check_skills(root, releases) + check_markdown(root)
    for problem in problems:
        print(problem)
    return 1 if problems else 0


if __name__ == "__main__":
    sys.exit(main())
