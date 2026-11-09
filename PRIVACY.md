# Privacy

Athene is a collection of local instruction files for AI coding agents. It does not run a
hosted service, collect analytics, create user profiles, or sell user data.

## Data Athene handles

Athene's skills may read the files, repository metadata, and task context that an agent already
has permission to access to complete a user-requested task. Most of this is never written down —
it's read, used for the task, and discarded. Two skills write committed files that persist outside
the agent session: Product Discovery stores an approved brief under `~/.athene/`, and any
lifecycle skill may write or update `.athene/state.md` (decisions made, open questions, current
phase) in the target repo itself. Both are plain local files the user already has full access to
and can delete; Athene has no copy of either anywhere else.

## GitHub workflows

Some optional workflows involve GitHub, such as reviewing a pull request or configuring a review
gate. They run only when the user explicitly requests that workflow. Depending on the agent and
the user's setup, the agent may use an already-authorized GitHub connection or GitHub CLI
authentication to read the selected repository or pull request, or to make the change the user
approved. Reviewing a pull request means its diff and related code are processed by whichever
agent and model the user has chosen, same as any other file Athene reads for a task — not sent
anywhere beyond that agent's normal request flow.

A normal build can also hit a topic with no matching entry in Athene's own curated source list.
When that happens, the build workflow may ask the user for a short-lived, narrowly scoped GitHub
token to file one issue proposing the new source on Athene's own public repository — never a
broader token, never reused for anything else, never written to a file or logged. The user sees
the drafted issue text and confirms it before it's posted; declining or having no token just hands
the draft to the user instead of posting it.

Athene does not read, store, display, or transmit GitHub tokens, passwords, or other credentials
outside the single call each workflow above uses one for. Authentication is otherwise handled by
the GitHub integration or CLI the user has already configured. Data needed for a requested GitHub
API call (reading a PR, posting a comment, filing an issue) goes to GitHub; Athene has no separate
endpoint, telemetry service, or webhook of its own.

## Third-party services

The agent host and any services the user connects to it have their own privacy practices. Review
those providers' policies before granting access to repositories, files, or other data.

## Changes and questions

Material changes to Athene's data handling will be documented in this file. For questions or a
privacy concern, use the support channels in [SUPPORT.md](SUPPORT.md).
