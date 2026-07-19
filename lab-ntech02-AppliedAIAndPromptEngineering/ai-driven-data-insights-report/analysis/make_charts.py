import pandas as pd
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
import matplotlib.dates as mdates

df = pd.read_csv('../data/Urban Transit Ridership Data 2024(in).csv')
df['Date'] = pd.to_datetime(df['Date'], format='%m/%d/%Y')
df = df.sort_values('Date')

plt.rcParams.update({'font.size': 11})

# 1. Daily ridership over the year, floor days highlighted
fig, ax = plt.subplots(figsize=(11, 4.5))
ax.plot(df['Date'], df['Daily_Ridership'], color='#2b6cb0', linewidth=1, label='Daily ridership')
floor = df[df['Daily_Ridership'] == 1500]
ax.scatter(floor['Date'], floor['Daily_Ridership'], color='#c0392b', s=14, zorder=5, label='Exactly 1,500 (flagged)')
ax.set_title('Daily ridership, 2024 (42 days flagged at exactly 1,500)')
ax.set_ylabel('Riders')
ax.xaxis.set_major_formatter(mdates.DateFormatter('%b'))
ax.legend(loc='upper right')
fig.tight_layout()
fig.savefig('charts/daily_ridership_timeline.png', dpi=150)
plt.close(fig)

# 2. Monthly average ridership (seasonality)
month_order = ['January','February','March','April','May','June','July','August','September','October','November','December']
monthly = df.groupby(df['Date'].dt.month_name())['Daily_Ridership'].mean().reindex(month_order)
fig, ax = plt.subplots(figsize=(9, 4.5))
bars = ax.bar(range(12), monthly.values, color='#2b6cb0')
ax.set_xticks(range(12))
ax.set_xticklabels([m[:3] for m in month_order])
ax.set_title('Average daily ridership by month')
ax.set_ylabel('Avg riders/day')
fig.tight_layout()
fig.savefig('charts/monthly_ridership.png', dpi=150)
plt.close(fig)

# 3. Day-of-week average ridership
dow_order = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday']
dow = df.groupby(df['Date'].dt.day_name())['Daily_Ridership'].mean().reindex(dow_order)
fig, ax = plt.subplots(figsize=(8, 4.5))
colors = ['#2b6cb0'] * 5 + ['#4a5568'] * 2
ax.bar(range(7), dow.values, color=colors)
ax.set_xticks(range(7))
ax.set_xticklabels([d[:3] for d in dow_order])
ax.set_ylim(0, 2300)
ax.set_title('Average ridership by day of week (weekend in gray)\nBars start at 0: differences between days are small')
ax.set_ylabel('Avg riders')
fig.tight_layout()
fig.savefig('charts/day_of_week_ridership.png', dpi=150)
plt.close(fig)

# 4. Delay vs ticket sales scatter (checking the assumed correlation)
fig, ax = plt.subplots(figsize=(6.5, 5.5))
ax.scatter(df['Delay_Count'], df['Ticket_Sales'], alpha=0.4, color='#2b6cb0', s=18)
ax.set_xlabel('Delay count (that day)')
ax.set_ylabel('Ticket sales (that day)')
r = df['Delay_Count'].corr(df['Ticket_Sales'])
ax.set_title(f'Delays vs ticket sales (r = {r:.2f}, no meaningful relationship)')
fig.tight_layout()
fig.savefig('charts/delay_vs_sales_scatter.png', dpi=150)
plt.close(fig)

print('charts written')
