---
title: "OpenCode Session Management"
type: research
status: proposed
created: 2026-11-17
updated: 2026-11-17
tags: [opencode, remote, session, api]
---

# OpenCode Session Management

This document answers the first research question from the remote-development
initiative: what native facilities exist to discover, monitor, and interact with
all OpenCode sessions, including subagents and long-running work.

## Verified environment

| Item | Value |
|------|-------|
| OpenCode version | `opencode v2.0.32` |
| Host | NixOS workstation (`t490s`) |
| Background service | `http://127.0.0.1:49374` |
| Verified commands | `opencode api session.list`, `opencode api GET /api/session/active` |

Verified calls returned a live list of sessions, project IDs, parent/child
relationships, active status, and token/model usage. No remote-client test was
performed because that requires a second device; the local API surface is the
source of truth for what a remote client can see.

## Core architecture (fact)

OpenCode 2 is client/server. A single background service owns sessions,
configuration, integrations, permissions, credentials, and tool execution. The
TUI, desktop app, web UI, mobile app, and the `@opencode/client` SDK are all
clients of the same server. Changing the server password signs every client out
[OpenCode Web docs][oc-web].

This means session management is not a separate add-on; it is exposed through
the same HTTP API that the local TUI already uses.

## Session discovery

### CLI

```bash
opencode session list
opencode session list --max-count 20 --format json
```

### HTTP API

| Method | Path | Purpose |
|--------|------|---------|
| GET | `/api/session` | Ordered, paginated list of all sessions |
| GET | `/api/session/active` | Active sessions with `running`/`idle` status |
| GET | `/api/session/{id}` | Session details |
| GET | `/api/session/{id}/children` | Child sessions (subagents) |
| GET | `/api/session/{id}/todo` | Session todo list |

`GET /api/session` supports `parentID=null` to list only root sessions,
`directory`, `project`, `archived`, `search`, and cursor pagination
[OpenCode API docs][oc-api].

### Verified behavior

`opencode api session.list --param limit=5` returned:

- session `id`, `projectID`, `agent`, `model`, `cost`, `tokens`
- `parentID` for subagent sessions
- `outcome` (`succeeded`, etc.) and `time` objects
- `location.directory`

`GET /api/session/active` returned a map of session IDs to `{ "type": "running" }`.

## Session state, activity, and subagent visibility

The server emits a server-sent event stream on `GET /api/event`. The documented
event types include:

- session lifecycle: `session.created`, `session.forked`, `session.deleted`
- execution: `session.execution.started`, `.succeeded`, `.failed`, `.interrupted`
- step/tool detail: `session.step.started`, `.streamed`, `.ended`,
  `session.tool.called`, `.success`, `.failed`
- permissions and input: `permission.asked`, `permission.replied`,
  `form.created`, `form.replied`, `session.inbox.*`
- subagent linkage: child sessions carry `parentID`; jobs are listed under
  `/api/experimental/job`

The event stream is **live-only** with no replay and no automatic reconnection
[OpenCode client docs][oc-client]. Consumers must reconnect and resync after a
drop.

## Waiting-for-input / permission states

| Interaction | API path |
|-------------|----------|
| Pending permission requests | `GET /api/permission/request` |
| Session permission requests | `GET/POST /api/session/{id}/permission` |
| Reply to a permission request | `POST /api/session/{id}/permission/{rid}/reply` |
| Session inbox items | `GET /api/session/{id}/inbox` |
| Reply to an inbox item | `PATCH /api/session/{id}/inbox/{iid}` |
| Session forms | `GET/POST /api/session/{id}/form` |
| Reply to a form | `POST /api/session/{id}/form/{fid}/reply` |

These endpoints allow a remote client to see what the agent is blocked on and
approve or reject it.

## Conversation history and resuming

| Capability | API path |
|------------|----------|
| Send a prompt | `POST /api/session/{id}/prompt` |
| Run a command | `POST /api/session/{id}/command` |
| Run a shell command | `POST /api/session/{id}/shell` |
| Interrupt execution | `POST /api/session/{id}/interrupt` |
| Read messages | `GET /api/session/{id}/message` |
| Read session log | `GET /api/experimental/session/{id}/log` |
| Export session | `GET /api/experimental/session/{id}/export` |
| Import session | `POST /api/experimental/session/import` |

Because all clients share the same server, opening a session in the web UI or
mobile app resumes the exact same conversation and working directory that the
TUI or a subagent was using.

## Desktop “Recent Sessions” vs full inventory

The desktop app and TUI show recent sessions for quick access. The API
(`/api/session` with pagination) returns the complete inventory, including
archived sessions and child sessions. For monitoring every running agent, the
API is the authoritative source.

## API / SDK for custom dashboards

The official TypeScript client (`@opencode/client`) is generated from the same
OpenAPI contract as the server and includes `session.list`, `session.prompt`,
`event.subscribe`, etc. In Node/Bun it can auto-discover the local background
service via `Service.ensure()` [OpenCode client docs][oc-client].

A custom dashboard is possible, but the native web UI already exposes the same
session list, conversation view, permission prompts, and input box. Unless we
need project-specific policy enforcement, a custom dashboard adds maintenance
without adding capability.

## Recommendations

1. **Prefer native clients.** Use OpenCode Web (browser/PWA) and/or the mobile
   app for remote monitoring and intervention. They are first-class clients,
   not wrappers.
2. **Use the API only for automation.** Use `opencode api` or
   `@opencode/client` for scripted health checks, not for day-to-day remote use.
3. **Do not build a custom orchestration platform.** The server already provides
   inventory, events, prompts, permissions, and subagent visibility.
4. **Treat events as live-only.** Any remote monitoring tool must reconnect and
   resync; it cannot request historical events from the stream.

## Limitations and open questions

| Topic | Finding |
|-------|---------|
| `/api/session/status` | Older docs describe a global status endpoint; the current API exposes `/api/session/active` instead. Verified behavior is the latter. |
| Event replay | None. Disconnected clients miss events. |
| Subagent job details | `/api/experimental/job` exists but was not exercised for this research. |
| Session log durability | The experimental log route relies on server-side persistence settings that may not be enabled by the default CLI install [SDK streaming notes][sdk-stream]. |
| Cross-project view | The API can list sessions across all loaded locations; clients scope requests by project. |

[oc-web]: https://opencode.ai/v2/docs/cli/web
[oc-api]: https://opencode.ai/v2/docs/api
[oc-client]: https://opencode.ai/v2/docs/build/client
[sdk-stream]: https://github.com/opencode-dotnet/opencode-sdk-dotnet/blob/master/docs/guide/streaming.md
