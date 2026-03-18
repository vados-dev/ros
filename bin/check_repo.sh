#!/usr/bin/env bash

cd "${REPO_DIR:-.}"

dirty="$(git ls-files -u || true)"
lsfiles="$(git ls-files --others --exclude-standard || true)"

# Conflict or unresolved state: stop and notify.
if [[ -n "$dirty" ]]; then
    echo "[check_repo] repo has conflicts, stop"
    echo "[check_repo] unmerged files:"
    printf "%s\n" "$dirty"
    echo "[check_repo] resolve conflicts and run: git add <files> && git commit"
    bash bin/notify_telegram.sh "STOP: repo conflicts in $(pwd)"
    exit 1
fi

# Exit 0 only when repo is NOT clean to allow autocommit flow.
if git diff --quiet && git diff --cached --quiet && [[ -z "$lsfiles" ]]; then
    echo "[check_repo] repo clean. Exit 1 from check_repo.sh."
    exit 1
else
    echo "[check_repo] repo not clean. Exit 0 from check_repo.sh."
    exit 0
fi
