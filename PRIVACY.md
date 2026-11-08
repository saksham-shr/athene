# Privacy

Athene is a collection of local instruction files for AI coding agents. It does not run a
hosted service, collect analytics, create user profiles, or sell user data.

## Data Athene handles

Athene's skills may read the files, repository metadata, and task context that an agent already
has permission to access in order to complete a user-requested task. Athene itself does not
persist that information outside the agent and services the user has chosen to use.

## GitHub workflows

Some optional workflows involve GitHub, such as reviewing a pull request or configuring a review
gate. They run only when the user explicitly requests that workflow. Depending on the agent and
the user's setup, the agent may use an already-authorized GitHub connection or GitHub CLI
authentication to read the selected repository or pull request, or to make the change the user
approved.

Athene does not read, store, display, or transmit GitHub tokens, passwords, or other credentials.
Authentication is handled by the GitHub integration or CLI the user has already configured. Data
needed for a requested GitHub action is sent to GitHub only; Athene has no separate endpoint,
telemetry service, or webhook.

## Third-party services

The agent host and any services the user connects to it have their own privacy practices. Review
those providers' policies before granting access to repositories, files, or other data.

## Changes and questions

Material changes to Athene's data handling will be documented in this file. For questions or a
privacy concern, use the support channels in [SUPPORT.md](SUPPORT.md).
