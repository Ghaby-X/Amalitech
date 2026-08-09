# Cybersecurity

Capstone governance review of "ConnectSphere," a fictional professional-networking MVP, done in the role of an independent cybersecurity governance consultant ahead of a Series A security due-diligence review. Each set is scored against its own architecture diagram: a governance review card (three risk findings + one monitoring recommendation, each tied to a core principle), an annotated corrected diagram, and a short summary of the review process.

## Files

| Folder | Purpose |
|---|---|
| `set-1-event-networking/` | Set 1 scenario: Professional Event Networking MVP (profiles, event registration, in-app messaging). Findings: unencrypted client traffic + web-server-to-database bypass paths (Confidentiality/PoLP), unparameterized SQL (Integrity), unauthenticated Admin Dashboard wired to the database (Availability). |
| `set-2-professional-connection/` | Set 2 scenario: Professional Connection Platform V1 (profiles, workshop RSVP, moderated forums). Findings: unencrypted client traffic + API key hard-coded in frontend code (Confidentiality), unparameterized SQL + an unenforced moderation gate (Integrity), unthrottled email API + default admin credentials (Availability). |

Each folder's `README.md` contains the full Governance Review Card, the annotated architecture diagram (original + corrected side by side), and the review-process summary for that set.
