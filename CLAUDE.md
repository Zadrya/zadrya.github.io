# CLAUDE.md

The Zadrya website, served by GitHub Pages at `zadrya.github.io`: landing page, privacy policy and support page, in English and Spanish.

## Commands

- `make setup`: install the git hooks (lefthook), once per clone.
- `make check`: lint, license metadata and tests. Run before every commit.
- `make ci`: everything CI runs, including authorship and commitlint. Run before opening a pull request.

Local tools (Homebrew): `lefthook actionlint yamllint markdownlint-cli2 zizmor reuse shellcheck`, plus Node for commitlint.

## Rules

- **Authorship.** Sklyvan is the only author and committer. Never add `Co-Authored-By`, `Claude-Session:` or "Generated with Claude Code" to commits, pull requests or code. The `commit-msg` hook and the `authorship` CI check reject them.
- **Small commits.** One logical change per commit, conventional commit messages, refactors separate from features.
- **Branches.** `feature/<description>` or `fix/<description>`, one pull request per slice (ideally under 400 lines of diff), rebase merge once CI is green and the `reviewer` agent approves. Never push to `main`.
- **Language.** Everything is in English. Use commas, colons or parentheses instead of the em dash (`make lint` fails on U+2014).
- **Secrets.** Only in environment variables or GitHub Secrets, never in the repository, the chat or logs.
- **Licenses.** Original code carries the SPDX header `GPL-3.0-or-later`. Files without a comment syntax are covered by `REUSE.toml`.
- **No tracking.** No analytics, no third-party scripts, fonts or embeds. The site must work without JavaScript.

## Gotchas

- `index.html` is a placeholder: the real site and the Pages deployment are built in Phase 7.
- Spanish is allowed here only in the Spanish pages of the site.
- Actions must be pinned by full commit SHA: the organization enforces it and unpinned workflows do not start.
- The shared scripts in `scripts/` and the base workflows are duplicated in all four Zadrya repositories on purpose, so that each repository can run `make ci` on its own. When you change one, change it in all four.
- The `authorship` and `commitlint` checks run the scripts from the pull request head, so a pull request that edits `scripts/check-*.sh`, the `Makefile` or those workflows validates itself: review such diffs with extra care.
- Tool versions are pinned in `scripts/install-ci-tools.sh` and the `Makefile`, and Dependabot does not track them: bump them by hand.
- Dependency review (license allowlist in `.github/workflows/licenses.yml`) only runs in CI, so `make ci` cannot tell you that a new dependency has a license outside the list.
- Dependabot pull requests fail the `authorship` check by design: re-commit the bump as Sklyvan on a branch and close the Dependabot pull request (see `Application/docs/adr/0002-dependabot-and-authorship.md`).
- Before every push: `git log --format='%an <%ae>%n%B' origin/main..HEAD`.
