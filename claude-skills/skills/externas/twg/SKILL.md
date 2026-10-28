---
name: twg
description: >
  Use TWG whenever Atlassian or company context would help:
  Jira workitems and issues; Confluence pages and PRDs; Bitbucket PRs;
  project or goal status and launch readiness; owners, SMEs,
  approvers, or escalation; personal, org, or leadership work rollups and out-of-office
  catch-ups; dependency maps; code search, repository, or PR discovery; incidents,
  on-call, or reliability; sharing generated HTML, CSV, PDF, or presentation files
  with coworkers; on-call, or reliability;
  and deep internal research across connected sources, docs, work, and people.
---

# twg

Anchor on a key, URL, person, project, repo, or window.
Answer from read-only results.

## TWG Terms

- **Anchor**: the key, URL, person, project, repository, or window that a
  request starts from.
- **Hydrate**: get the full record of an item that a search or query returned.

## Plan First

Plan in the main thread on what tools to use for the user's task or query.

1. Run `twg help-map`; `*` marks writes.
2. Always print a plan between `### Plan` and `### End plan` before you run them. Write one step for each call.
   Give the exact command path from the map (`goals query`), the inputs, and the
   dependencies. Label each unknown with the step that produces it. Flags come
   from step 3.
3. Describe the planned commands in one call (up to 10):
   `twg help describe "<a>" "<b>"`. Reuse those contracts. If you describe one
   command, add `--detail compact`.
4. Batch independent reads, separated by `;` (`&&` for dependencies).
   Pipe JSON to `jq` only with `set -o pipefail`; check error fields.

If a command is unclear, run `twg help <terms>`. For additional guidance, run
`twg help discover-skills "<intent>"`. Then follow `next.loadReference` or
`next.loadSkill`.

## Overview

Load the narrowest companion skill:

- Product work: `../twg-jira/SKILL.md`, `../twg-confluence/SKILL.md`, or
  `../twg-space-creation/SKILL.md`.
- Status: `../twg-status-rollups/SKILL.md`. Load it before engineering.
- Relationships: `../twg-context-discovery/SKILL.md`.
- People: `references/USER-IDENTIFIERS.md`.
- Research: `../twg-agentic-search/SKILL.md`.
- Ownership: `../twg-responsibility-routing/SKILL.md`.
- Code and PRs: `../twg-engineering-work/SKILL.md`.
- Stale work: `../twg-jira-resolve-merged-work/SKILL.md`.
- Incidents: `../twg-operational-health/SKILL.md`.
- A review that the user requested: `../twg-code-review/SKILL.md`.
- Artifacts: `../twg-artifacts/SKILL.md` for prior Artifact IDs, or to share or update an Artifact.


## Invocation And Output

Run `twg <command>`. On shell `command not found`, use `$HOME/.local/bin/twg`
(macOS/Linux) / `$env:LOCALAPPDATA\Programs\twg\bin\twg.exe` (PowerShell), then
tell user to add that directory to PATH. Do not treat auth or command errors as
PATH failures.

Do not add per-command env prefixes unless requested; hosts may set `TWG_AGENT_DEFAULTS=1`.

- Answer from inline output, or from compact output that you already read, if
  it supports the requested facts.
- Quote extracted facts with their sources. Do not quote whole payloads.
- For gaps, follow `references/OUTPUT.md`. Keep unavailable evidence unknown.
- On a restricted host, use `twg` and permitted output files. Do not use
  arbitrary host files, credentials, or other agent runs.
- Use the timezone and window of the prompt. Report gaps. Follow the typed route
  of the narrowest companion skill.

## Auth/Setup Guard

If a command waits for user input, do not run it. Examples are setup, login, install, upgrade, and upkeep. Give clear instructions, and ask the user to run it.

## Errors in Sandboxes

For sandboxed `twg bb pipeline get`, `wait`, `grep`, or `tail`, follow `references/OUTPUT.md`.
Log restrictions are not evidence of auth failure.

## On gathering evidence

1. Make one good first call. Give the command everything you know, and it looks up the references itself.
2. Check "now" claims against live fields. Do not trust old comments. Date anything about the past. If you cannot get a fact, say it is unknown.
3. Read only what matters. Pick the best candidates, read just those, then answer.
4. Know when to stop. Stop at the first policy denial, or when the same error repeats.
5. If the user names a project or service, treat the name as exact. Keep its qualifiers, and check that you found that item. Use a renamed or successor item only if a source says so. If you find no evidence, say so.

## Batch Reads

If live help shows that a command accepts many inputs, send about twenty IDs in
each call with `--agent-fields @compact`. If query or tree metadata gives enough
data, use it. Tell the user what you left out. Choose the fields before you
start. Reuse the results. After five repeated calls, check for a batch call.

## Assorted Discovery guidelines

- Use `twg rovo search "<topic>" [--limit <n>]` for top-K discovery. Explicit `--app` checks availability first.
- Use `twg trello search "<query>"` for Trello. It has no workspace scope.
- For unanchored work or knowledge, start with Jira and Confluence.
  Use Drive, SharePoint, or code for named sources or for gaps that change the answer.
  Run `twg rovo list-apps -o json` only when availability is unknown. Reuse auth.
  Do not auto-login or fabricate "none found".
- `docs query` and `work query` return user activity. They do not search titles or content.
  For topic text, use `docs search` or `work search`. See `references/ROUTING.md`.
- Pass supported original references to native reads. Avoid separate resolve calls.
  Person handoffs: `references/USER-IDENTIFIERS.md`.
- Command shape guardrails:
  - `work query` uses `--scope me|user`, never `--scope global`.
  - Inferred teams need explicit `--include-inferred`; see `references/inferred-teams.md`.
- Use `search-code` with the explicit repo and host. If the request has no anchor, omit `--app` for available indexed SCM.
  Use `--repo` as an anchor. If the hits are incomplete, widen the search within the available products.
  Report gaps in the index.
- Use `assets graph` to traverse object, owner, team, or Jira relationships. See `references/ASSETS_GRAPH.md`.
  Otherwise use `assets search`, `assets query --aql`, or `assets object get`.

## Rules

- Never guess IDs, flags, slugs, ARIs, or write contracts.
- For a write, load the product skill, follow live help, and read the current state.
  Tell the user what the write will change, unless the user asked you to run it.
- Do not inspect local files, caches, or schemas, unless the user asks about local state.
