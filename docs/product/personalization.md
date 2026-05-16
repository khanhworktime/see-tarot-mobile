# Personalization — BE-centric (v1)

Status: planned. Reconciled per decision 0005. The dedicated AI
personalization module does NOT exist yet (future BE work, separate
sub-project). v1 uses data BE already stores.

## Model (v1)

| Data | Owner | Source |
| --- | --- | --- |
| Profile: `birthDate`, `timezone`, `preferredIntent`, `name` | BE | `/auth/get-session`, `PATCH /profile`, `POST /profile/onboard` |
| Reflections (journal on a reading) | BE (server-side, append-only) | `POST /readings/:id/reflect`, `GET /readings/:id/reflections` |
| On-device | iOS | cache only (hydrated readings, artwork, preferences) |

The earlier "raw sensitive text never leaves device" hard rule is REMOVED
(contradicted existing server-side reflections). Privacy posture = server-side
trust, same as web.

## Onboarding

`onboardedAt == null` (from `/auth/get-session`) ⇒ show onboarding →
`POST /profile/onboard { birthDate, name? }`. `preferredIntent` can prefill the
oracle topic picker.

## Future (out of v1)

Dedicated AI personalization module on BE that uses profile + reflection
history to tailor reading prompts. iOS keeps a `PersonalizationProvider`
interface seam so it can adopt richer personalized output without UI rework
when BE ships it. No on-device prompt assembly in v1.

## Open Questions

- Derived-context schema + whether personalization needs reflection history
  granularity — defined with the future BE module.
