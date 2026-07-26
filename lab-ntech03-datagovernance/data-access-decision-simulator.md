# Data Access Decision Simulator

**Scenario:** EduConnect Ghana, ed-tech platform, 50,000+ students.

**Data classification tiers:**

- **PUBLIC**: marketing materials, public course catalogs
- **INTERNAL**: aggregated analytics, internal reports
- **CONFIDENTIAL**: student PII, grades, payment information

---

## Request 1: Marketing Campaign

- **From:** Sarah Owusu, Marketing Manager
- **Request:** Full student database (names, emails, phone numbers, course enrollments) for a referral campaign launching Friday.

### Data Access Decision Form

| Field | Response |
|---|---|
| **Decision** | Conditionally Approve |
| **Lifecycle Stage** | Use (existing stored data repurposed for a new business function); borders on Share once data leaves the student records system into a campaign tool |
| **Justification** | Sarah holds INTERNAL access only. Emails are classified CONFIDENTIAL, so handing over the raw list would exceed her clearance and violate least privilege regardless of urgency. Names and enrollment data are INTERNAL and within her existing access, but bulk export of full student records for an external-facing campaign still requires oversight, since aggregated internal data is being converted into a targeted contact list. Phone numbers are not necessary for an email referral campaign and should be excluded entirely (data minimization) |
| **Action Steps** | 1. Deny the direct database/export request. 2. Route the actual send through a system that already holds CONFIDENTIAL access (e.g., a marketing automation tool with a scoped, audited integration) so Sarah supplies segment criteria and creative copy but never receives raw PII. 3. Scope the data pulled to only what the campaign needs: no phone numbers, no unrelated CONFIDENTIAL fields. 4. Get sign-off from the Data Protection Officer before the send, and log the access grant with an expiry tied to the campaign window. 5. Confirm the referral campaign's data use is covered by the platform's existing privacy notice / consent basis; if not, that blocks the Friday deadline regardless of technical controls. |
| **Consult** | Data Protection Officer (access scope, consent basis), IT Security (provisioning the scoped integration), Legal (consent/notice coverage) |

---

## Request 2: Analytics Partnership

- **From:** David Mensah, Head of Product
- **Request:** Grant DataInsights Inc. (US-based) direct AWS database access via shared login credentials to run learning-pattern algorithms on activity logs and student profiles.

### Data Access Decision Form

| Field | Response |
|---|---|
| **Decision** | Deny as proposed; Conditionally Approve a redesigned version |
| **Lifecycle Stage** | Share (CONFIDENTIAL/INTERNAL data disclosed to an external third party) |
| **Justification** | Several compliance failures stack up here: (1) sharing live database login credentials is a security failure independent of data governance, since third parties should never hold direct production credentials; (2) student profiles are CONFIDENTIAL and are being handed to an external processor with no data minimization, when pseudonymized/aggregated data would likely serve the stated purpose; (3) DataInsights is US-based, so this is a cross-border transfer of personal data subject to Ghana's Data Protection Act (Act 843), which requires an adequate safeguard (contractual clauses, data subject consent, or a Data Protection Commission-recognized mechanism) before transfer; (4) there's no indication of a signed Data Processing Agreement, a Data Protection Impact Assessment, or DPC notification/registration for this new processing activity |
| **Action Steps** | 1. Revoke/never issue the shared credentials; access must go through named, individual, logged accounts or (preferably) a read-only API/data-sharing layer, not raw DB access. 2. Require a signed Data Processing Agreement with DataInsights defining purpose limitation, security obligations, breach notification, and deletion at contract end. 3. Pseudonymize or aggregate student profile fields before they leave EduConnect's environment; share only what the algorithms actually need. 4. Put a cross-border transfer safeguard in place per Act 843 (standard contractual clauses or documented consent) before any data crosses the border. 5. Run a Data Protection Impact Assessment and register/notify the Data Protection Commission if required. 6. Only after 1-5 are documented, re-open the request as a scoped, time-limited, monitored access grant. |
| **Consult** | Data Protection Officer, Legal (contract + DPA), IT Security (access architecture, credential policy), possibly the Data Protection Commission directly |

---

## Request 3: Archive & Deletion

- **From:** Comfort Asante, Customer Support Lead
- **Request:** Full account and data deletion for James Boateng ("right to be forgotten"), inactive 6 months, no pending payments.

### Data Access Decision Form

| Field | Response |
|---|---|
| **Decision** | Conditionally Approve: deletion can proceed, but not as an unqualified "delete everything" |
| **Lifecycle Stage** | Destroy (with a preceding Archive step for anything under legal retention) |
| **Justification** | Ghana's DPA gives data subjects a right to request erasure, and with no active course and no pending payments there's no operational reason to keep most of James's data. However, the right to be forgotten isn't absolute: records needed to meet a separate legal obligation, most notably financial/transaction records tied to completed payments, which are typically subject to statutory retention for tax and audit purposes, must be retained for that period, just not used for any other purpose. So the account, profile, activity logs, and course data can be deleted; payment/transaction records tied to completed courses are archived (access-restricted, minimized) until their retention period lapses, then destroyed |
| **Action Steps** | 1. Verify James's identity before acting on the request (prevents fraudulent deletion requests). 2. Confirm no legal hold, dispute, or open investigation involving his account. 3. Delete profile, PII, activity logs, and course/enrollment data from production and backups per the standard deletion procedure. 4. Move the minimum required financial records (transaction IDs, amounts, dates, not full profile) into a restricted archive tier, tagged with a retention-expiry date and a note that it exists solely for statutory compliance. 5. Notify any third-party processors who received his data (e.g., payment processor, analytics partners) so they delete/restrict their copies too. 6. Log the deletion action and issue Comfort a confirmation to send back to James, including what was retained and why. |
| **Consult** | Data Protection Officer, Legal/Finance (confirm statutory retention period for payment records), IT (execute deletion across prod + backups) |
