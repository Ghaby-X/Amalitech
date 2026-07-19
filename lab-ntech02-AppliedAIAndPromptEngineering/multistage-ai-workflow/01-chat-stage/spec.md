# Stage 1 output (chat-based AI, unedited)

Raw response to `prompt.md`, pasted verbatim. This is a **spec, not
code**: turning it into a working page is stage 2's job.

---

## 1. Concept

**Ember & Oak**, a modern wood-fired American grill. The vibe is
rustic-upscale: exposed brick, open flame, a menu built around
slow-cooked, smoked, and charred dishes. Warm, confident, a little
smoky, not fussy fine dining, not a diner either.

## 2. Page sections

### Hero
- **Purpose:** first impression, immediate call to action.
- **Headline:** "Fire. Wood. Flavor."
- **Subheadline:** "Wood-fired American cooking in the heart of downtown."
- **Button:** "Reserve a Table"

### About
- **Purpose:** establish the story and credibility.
- **Copy:** "Ember & Oak opened in 2019 with one idea: everything tastes
  better over live fire. Our kitchen is built around a custom wood-fired
  grill and smoker, and our menu changes with what's in season and what
  the fire does best."

### Menu highlights
- **Purpose:** show, don't just tell, give visitors a reason to book.
- **Items:**
  1. Smoked Beef Short Rib: 12-hour smoked, bourbon glaze, $32
  2. Charred Cauliflower Steak: chili oil, herb yogurt, toasted pine nuts, $19
  3. Wood-Fired Half Chicken: citrus brine, salsa verde, $24
  4. Embered Carrots: brown butter, dukkah, $12
  5. Oak-Smoked Chocolate Tart: sea salt, smoked cream, $11

### Hours & location
- **Purpose:** the practical info people actually come for.
- **Copy:** "412 Kiln Street, Downtown · Tue–Sun 5pm–11pm · Closed
  Mondays"

### Reservation / contact
- **Purpose:** convert interest into a booking.
- **Copy:** "Tables go fast on weekends, reserve ahead."
- **Fields:** Name, Email, Date, Party size
- **Button:** "Request Reservation"

### Footer
- **Purpose:** wrap-up, secondary links.
- **Content:** repeat address, social links (Instagram, Facebook),
  copyright line.

## 3. Visual direction

- **Palette:** charcoal black (structure/text), warm ember-orange
  (accent/CTAs), cream/off-white (background/breathing room), deep oak
  brown (secondary accent). Intent: warm and smoky, not clinical.
- **Typography:** a serif for headings (craft, heritage, a bit of
  weight) paired with a clean sans-serif for body copy (readability).
- **Mood:** warm, confident, tactile, like standing near a wood fire.

## 4. Non-functional requirements

- Mobile responsive (single column on small screens).
- Semantic HTML (`header`, `nav`, `main`, `section`, `footer`, etc.).
- Accessible: alt text on any imagery, labeled form fields, sufficient
  color contrast for text on the palette above.
- No build tooling, no external frameworks: plain HTML/CSS/JS only.

## 5. Out of scope

- Real payment processing.
- A real reservation backend. The form should be front-end only for
  this exercise (e.g. show a confirmation message on submit, no actual
  network request).
- A menu CMS or multi-page site: this is a single landing page.
