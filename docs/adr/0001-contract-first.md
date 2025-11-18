# ADR 0001 — Contract-first Core

Status: Accepted
Date: YYYY-MM-DD

## Context
Core must be stable and small.

## Decision
Core will contain only interfaces/primitives/policies. No concrete implementations.

## Consequences
- Implementations live in app/ or features/*/data
- Any breaking change requires ADR & migration note.

