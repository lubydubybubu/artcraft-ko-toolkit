#!/bin/bash
# Commit and push a patch repo (or this toolkit) to a PRIVATE GitHub repo of the owner after a secret scan.
# Usage: publish.sh LOCAL_REPO_DIR GITHUB_REPO_NAME "commit message"
set -euo pipefail
DIR=$1; NAME=$2; MSG=$3
GH=${GH:-gh}; GITLEAKS=${GITLEAKS:-gitleaks}
cd "$DIR"
[ -d .git ] || git init -q -b main
git config user.name >/dev/null || git config user.name "${GIT_AUTHOR_NAME:-Hermes Assistant}"
git config user.email >/dev/null || git config user.email "${GIT_AUTHOR_EMAIL:-hermes@localhost}"
"$GITLEAKS" dir . --no-banner --redact -v >/dev/null   # non-zero exit = finding -> abort (set -e)
git add -A
git diff --cached --quiet && { echo "no change"; exit 0; }
git commit -q -m "$MSG"
OWNER=$("$GH" api user --jq .login)
if ! "$GH" repo view "$OWNER/$NAME" >/dev/null 2>&1; then
  "$GH" repo create "$OWNER/$NAME" --private --description "Korean (ko) UI patch / tooling for storytold ArtCraft apps" >/dev/null
fi
git remote get-url origin >/dev/null 2>&1 || git remote add origin "https://github.com/$OWNER/$NAME.git"
"$GH" auth setup-git >/dev/null 2>&1 || true
git push -q -u origin main
LOCAL=$(git rev-parse HEAD); REMOTE=$("$GH" api "repos/$OWNER/$NAME/commits/main" --jq .sha)
[ "$LOCAL" = "$REMOTE" ] && echo "pushed $OWNER/$NAME ${LOCAL:0:8} (remote verified)" || { echo "REMOTE MISMATCH $REMOTE"; exit 1; }
