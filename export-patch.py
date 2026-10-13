#!/usr/bin/env python3
"""Export ONLY the Korean-localization changes of an ArtCraft app working tree as a patch repo.

Usage: export-patch.py APP_TREE PATCH_REPO APP_NAME
Writes into PATCH_REPO:
  patches/<app>-<base>-ko.patch   git diff (binary-safe) of tracked + new files vs the upstream base commit
  BASE.txt                        upstream URL, base tag/commit the patch applies to
  CHANGED-FILES.txt               diffstat
and proves the patch applies cleanly to a pristine `git archive` of the base commit.
Upstream source code itself is never copied, only the diff.
"""
import os, subprocess, sys, tempfile, pathlib, shutil

tree, out, app = map(pathlib.Path, sys.argv[1:4]) if len(sys.argv) == 4 else sys.exit(__doc__)
app = str(app)
git = lambda *a, **k: subprocess.run(['git', *a], cwd=tree, check=True, capture_output=True, **k).stdout
base = git('rev-parse', 'HEAD').decode().strip()
try:
    tag = git('describe', '--tags', '--exact-match', 'HEAD').decode().strip()
except subprocess.CalledProcessError:
    tag = base[:12]
url = git('remote', 'get-url', 'origin').decode().strip()

with tempfile.TemporaryDirectory() as td:
    env = dict(os.environ, GIT_INDEX_FILE=os.path.join(td, 'index'))
    run = lambda *a: subprocess.run(['git', *a], cwd=tree, env=env, check=True, capture_output=True).stdout
    run('read-tree', 'HEAD'); run('add', '-A')
    patch = run('diff', '--cached', '--binary', 'HEAD')
    stat = run('diff', '--cached', '--stat=200', 'HEAD').decode()
if not patch.strip():
    sys.exit('no changes')

pdir = out / 'patches'; pdir.mkdir(parents=True, exist_ok=True)
for old in pdir.glob(f'{app}-*-ko.patch'):
    old.unlink()
pf = pdir / f'{app}-{tag}-ko.patch'; pf.write_bytes(patch)
(out / 'BASE.txt').write_text(f'upstream: {url}\ntag: {tag}\ncommit: {base}\npatch: patches/{pf.name}\n')
(out / 'CHANGED-FILES.txt').write_text(stat)

with tempfile.TemporaryDirectory() as td:  # apply check on a pristine base
    arc = subprocess.run(['git', 'archive', base], cwd=tree, check=True, capture_output=True).stdout
    subprocess.run(['tar', '-x', '-C', td], input=arc, check=True)
    subprocess.run(['git', 'init', '-q'], cwd=td, check=True)
    r = subprocess.run(['git', 'apply', '--check', str(pf.resolve())], cwd=td, capture_output=True, text=True)
    if r.returncode:
        sys.exit('patch does not apply cleanly:\n' + r.stderr)
print(f'{pf} ({len(patch)} bytes) applies cleanly to {tag} {base[:8]}')
