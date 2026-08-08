# autopushd

A tiny systemd daemon that auto-commits and pushes your dirty git repos — on a timer, on logout, and right before your laptop suspends. So the work you forgot to push is never actually lost.

No file-watcher, no daemon babysitting `inotify` events on every keystroke. Just three cheap, well-timed triggers that cover the moments people actually lose work: closing the lid, shutting down, or simply forgetting for hours.

## Why

You work on a project on your desktop. You close the terminal, don't push, go to bed. Next day at the studio, on your laptop, the repo is stale and you can't continue where you left off.

`autopushd` fixes this by making "did I push" a non-question.

## What it does, per repo

For every git repo (with an `origin` remote) under the directories you configure:

1. If dirty: `git add -A && git commit` — authored as **`Autopushd Bot <autopushd@local>`**, so bot commits never blend into your real history (`git log --author="Autopushd Bot"` to filter).
2. `git pull --rebase --autostash` against the tracked upstream (handles local/remote branch name mismatches correctly).
3. If ahead: push.
4. Auto-heals `https://github.com/...` origins to `git@github.com:...` — HTTPS remotes silently fail non-interactive pushes with no credential helper; this is usually the real reason a "sync" script goes quiet on you.

Everything is logged to `~/.config/autopushd/autopushd.log`. Nothing is force-pushed, nothing is force-merged — if `pull --rebase` hits a real conflict, that repo is skipped and logged, never auto-resolved.

## Triggers

| Trigger | Mechanism | Covers |
|---|---|---|
| Every 15 min | `systemd --user` timer | forgetting entirely |
| Logout / shutdown | `ExecStop` on a user service | graceful shutdown |
| Suspend / lid close | `/usr/lib/systemd/system-sleep/` hook | the case that actually loses work |

The suspend hook runs as root (systemd requirement) but re-enters your user's systemd environment to pick up your real `SSH_AUTH_SOCK`, so it authenticates exactly as you would.

## Install

```bash
git clone git@github.com:horiastanxd/autopushd.git
cd autopushd
./install.sh
```

Then edit `~/.config/autopushd/roots.txt` with the parent directories you want scanned recursively (e.g. `~/Projects`). The installer offers the suspend hook as an opt-in step (needs `sudo` once, to drop one file in `/usr/lib/systemd/system-sleep/`).

Requires: Linux with `systemd --user` sessions, `git`, `flock`. No dependencies beyond coreutils.

## Uninstall

```bash
./uninstall.sh
```

## Comparison

[gitwatch](https://github.com/gitwatch/gitwatch) is the established tool here, but it's a different shape: it watches a single folder via `inotify`/`fswatch` and commits on every file change, which is great for a notes vault, noisy for a normal dev repo. `autopushd` instead runs on a small number of meaningful triggers across every repo you point it at, and treats bot commits as first-class (distinct author) rather than diluting your real commit history.

## Safety

- Never force-pushes, never touches history.
- A real merge conflict during `pull --rebase` is skipped and logged — it will not silently drop or overwrite anything.
- One `flock`-guarded lock file prevents overlapping runs.

## License

MIT
