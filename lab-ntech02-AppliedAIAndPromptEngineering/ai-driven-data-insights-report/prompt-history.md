# Prompt history

Full log of the prompts used to produce `INSIGHTS_REPORT.md`, in the
order they were run. This is real analysis, not a scripted scenario, so
this log includes the points where a first-pass answer had to be thrown
out because it didn't hold up against the actual numbers.

## Phase 2: first-pass prompts

Used the lab's suggested starting prompts, unmodified, before looking
at any computed statistics:

1. "Analyze the headers and structure of this CSV."
2. "Identify the peak ridership day of the week based on this data."
3. "Is there a correlation between the 'Delay' column and the 'Ticket
   Sales' column?"
4. "Draft a key insight for a non-technical manager based on this
   finding."

## Phase 3: first pass, review, refine, chain

### 1. Structure

**First pass:** correctly identified the five columns (`Date`,
`Daily_Ridership`, `Ticket_Sales`, `Delay_Count`, `Avg_Delay_Minutes`)
and 366 daily rows covering all of 2024.

**Review:** this part didn't need refining, it's a factual read of the
header row. No changes made.

### 2. Peak ridership day of the week

**First pass output:** confidently named a specific "peak day"
(Tuesday), the kind of answer that sounds authoritative from a plausible
skim of the numbers.

**Review and fact-check:** ran the actual group-by-day-of-week average
in a script rather than trusting the claim. The real numbers: Tuesday
does have the single highest average (2,043 riders/day), but every day
of the week falls between 1,982 and 2,043, a spread of about 3% on a
base of ~2,000, against a day-to-day standard deviation of 369. That's
noise, not a pattern. Charted it with the y-axis starting at zero to see
the true shape (`analysis/charts/day_of_week_ridership.png`), and the
bars are visually indistinguishable.

**Refined prompt:**
> Act as a data analyst. Here are the actual average daily ridership
> figures by day of week: [pasted the seven numbers]. The overall
> day-to-day standard deviation is 369. Is the difference between the
> highest and lowest day meaningful, or is it within normal
> variation? Answer plainly, don't imply a stronger pattern than the
> numbers support.

**Result:** correctly concluded there is no meaningful "peak day," the
honest finding is that day of week barely matters here. Reported that
instead of the more exciting but unsupported claim from the first pass.

### 3. Delay vs. ticket sales correlation

**First pass output:** reasoned qualitatively that delays "likely
discourage riders from buying tickets" and implied a negative
relationship, without having computed anything. This is the clearest
hallucination risk in the whole exercise: a plausible-sounding causal
story with no actual number behind it.

**Review and fact-check:** computed the real Pearson correlation
between `Delay_Count` and `Ticket_Sales`: r = 0.06. Also checked
`Avg_Delay_Minutes` against both `Ticket_Sales` and `Daily_Ridership`:
r = -0.06 and r = -0.05. All four are effectively zero. Plotted delays
against ticket sales (`analysis/charts/delay_vs_sales_scatter.png`), a
formless cloud, no visible trend in either direction.

**Refined prompt:**
> Act as a data analyst. The actual Pearson correlation between
> Delay_Count and Ticket_Sales in this dataset is r = 0.06, and between
> Avg_Delay_Minutes and Daily_Ridership is r = -0.05. Write one plain
> sentence for a non-technical operations manager stating what this
> does and doesn't mean. Don't soften it into implying a relationship
> exists.

**Result:** the finding flipped entirely from the first pass: delays,
at the levels seen in this data, show no measurable relationship with
ridership or sales. That's a more useful (and more honest) insight than
the intuitive story, since it tells the operations team not to expect a
ridership boost from punctuality fixes alone.

### 4. Anomalies (not in the original four prompts, added after seeing the data)

**First pass:** none, the original prompt list didn't ask for
anomalies directly, this came from actually looking at the sorted
output.

**Refine and fact-check:** ran a z-score pass on all four numeric
columns and separately checked for exact-duplicate values, since
repeated identical values are a strong sign of a data floor rather than
genuine measurements. Found 42 of 366 days (11.5%) with
`Daily_Ridership` at exactly 1,500, concentrated between August 9 and
November 21 (17 of them in September alone). Plotted the full year
(`analysis/charts/daily_ridership_timeline.png`): the flagged days
don't sit at the bottom of a smooth decline, they interrupt an
otherwise noisy signal that jumps back up to 1,700 to 2,000 the very
next day. That pattern, not a gradual seasonal low, is what a floor or
clipping artifact looks like.

**Prompt used once the pattern was found:**
> Act as a data analyst. 42 out of 366 days show Daily_Ridership at
> exactly 1500, clustered between Aug 9 and Nov 21, and the surrounding
> days jump back up to normal noisy values rather than declining
> smoothly. What's the most likely explanation, and how should that
> change how confidently we report an autumn ridership decline?

**Result:** the AI correctly flagged this as more consistent with a
data collection ceiling/floor or missing-value placeholder than real
ridership, and recommended reporting the autumn dip as directionally
real but overstated in magnitude until the data team confirms it. That
recommendation is in the final report.

### 5. Chain: turn fact-checked findings into recommendations

Once the day-of-week, correlation, seasonality, and anomaly findings
were all individually verified, ran one chaining prompt per the lab's
own pattern:

> Here are four fact-checked findings: [1) spring ridership peaks
> around 2,480/day, autumn troughs around 1,600-1,700/day, a roughly
> 55% swing; 2) 42 days in Aug-Nov are flagged as a likely data
> artifact at exactly 1,500 riders; 3) delays show no measurable
> correlation with ridership or ticket sales; 4) average delay minutes
> (not delay count) are roughly double in Apr-Jun and Sep-Oct compared
> to the rest of the year]. Write a 3-5 bullet "Actionable
> Recommendations" section for a non-technical operations manager,
> based only on these four findings, no new claims.

**Result:** produced the five recommendations in the final report,
each traceable to exactly one of the four findings above.

### 6. Assemble

Combined the fact-checked trends, anomalies section, and chained
recommendations into `INSIGHTS_REPORT.md`, then re-checked every number
in the assembled document against `analysis/analysis_output.txt` one
more time before calling it done.
