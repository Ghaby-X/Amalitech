# Stage 2 notes (CLI-based AI)

Input: `../01-chat-stage/spec.md`
Output: `../site/index.html`, `../site/styles.css`, `../site/script.js`

The chat stage produced intent (colors "with intent, not hex codes,"
typography "pairing," a form with no backend). Turning that into a
working page means making concrete decisions the spec deliberately left
open. Those decisions are the actual value this stage adds:

## Judgment calls made

| Spec said | Implementation decision | Why |
|---|---|---|
| "Charcoal black, warm ember-orange, cream, deep oak brown (intent, not hex codes)" | `#211d1a` charcoal, `#a8441f` ember, `#faf3e8` cream, `#6b4a34` oak | Picked the ember shade dark enough that white button text clears WCAG AA contrast (~4.7:1), reserving a lighter `--ember-light` for decorative-only use so it's never load-bearing for text contrast. |
| "Serif for headings, sans for body" | `Georgia/Times New Roman` heading stack, system-UI sans body stack | Spec explicitly ruled out external frameworks/build tooling, which rules out a Google Fonts `<link>` too (that's a live external dependency, same category of risk). Used a serif already present on essentially every OS instead. |
| "Front-end only [reservation] form... no actual network request" | `script.js` intercepts `submit`, runs native `checkValidity()`, then swaps in a confirmation message and resets the form | Spec ruled out a backend but still implied the form should feel functional. Native HTML5 `required`/`type=email`/`type=date` validation is reused instead of hand-rolled validation, since the spec's own accessibility requirement (labeled fields) is easier to satisfy correctly with native semantics. |
| "Mobile responsive, single column on small screens" | Single `@media (min-width: 640px)` breakpoint that widens the menu grid to two columns and bumps the hero heading size; everything else is single-column by default | Spec gave a requirement, not a breakpoint scheme. Picked the smallest set of overrides that satisfies it rather than a full grid system, matching "no build tooling." |
| Menu items given as a flat list with price | Implemented as a `<ul>` of `<li class="menu-item">`, price visually paired with each name via flexbox | Kept markup semantic (list of items) rather than a table, since these aren't tabular data with shared columns beyond name/price. |

## Deviations from a literal reading

- The spec's "Reserve a Table" button appears twice in its section list
  (hero button and nav). Implemented as two links to the same
  `#reserve` anchor rather than duplicating the button as a fixed
  floating element, since the spec didn't ask for a sticky CTA, only a
  sticky *header*, which was inferred from "first impression" framing
  the hero was given and confirmed reasonable rather than assumed
  silently.

## Verification

See the workflow `README.md` for how this was run and checked in a
browser.
