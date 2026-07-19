# AI-Driven Data Insights Report

Uses AI to analyze a real UrbanTransit ridership dataset (366 days,
2024) and produce a plain-English insights report for a non-technical
operations team, with every claim checked against actual computed
statistics rather than trusted on the AI's word.

## Files

| File | Purpose |
| --- | --- |
| [`INSIGHTS_REPORT.md`](INSIGHTS_REPORT.md) | The submission: key trends, notable anomalies, five actionable recommendations, a prompt history summary, and reflection, in one document. |
| [`prompt-history.md`](prompt-history.md) | Full log of every prompt: first-pass answers (including two that turned out to be wrong), the fact-check against real numbers, and the refined/chained prompts that followed. |
| [`data/`](data/) | The provided dataset, unmodified. |
| [`analysis/analyze.py`](analysis/analyze.py) | The actual statistics behind every number in the report: day-of-week and monthly averages, correlations, z-score and exact-duplicate anomaly detection. Output captured in `analysis/analysis_output.txt`. |
| [`analysis/make_charts.py`](analysis/make_charts.py) | Generates the four charts embedded in the report, the "simple data visualization" cross-check the scenario asks for. |

## Method

Ran the lab's four suggested starter prompts first, with no other
context. Two of the four answers didn't hold up: a claimed "peak day
of the week" that turned out to be noise (every day is within about 3%
of every other), and an assumed delay-to-sales relationship that
doesn't exist in the data (r is approximately 0.06 in every direction
tested). Both were caught by actually computing the numbers instead of
trusting a plausible-sounding answer, then re-prompted with the real
figures to produce a corrected, appropriately unconfident finding.

## Where accuracy actually mattered

The standout anomaly, 42 days pinned at exactly 1,500 riders between
August and November, was found by checking for exact-duplicate values,
something a quick skim of the spreadsheet or a smoothed chart would
likely miss. It changes the practical recommendation: the autumn
ridership dip is real, but its reported size shouldn't be trusted until
the data pipeline for that window is checked.

One arithmetic error surfaced during final verification of the report
itself: an early draft said the autumn trough was "56% lower than the
spring peak," reusing a percentage that was actually computed the other
way around (spring is 56% higher than autumn, using autumn as the
base; autumn is 36% lower than spring, using spring as the base). Fixed
by recomputing both directions explicitly rather than assuming the
number carries over.
