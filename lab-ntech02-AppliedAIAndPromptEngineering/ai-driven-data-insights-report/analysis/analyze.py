import pandas as pd
import numpy as np

pd.set_option('display.width', 120)

df = pd.read_csv('../data/Urban Transit Ridership Data 2024(in).csv')
df['Date'] = pd.to_datetime(df['Date'], format='%m/%d/%Y')
df['DayOfWeek'] = df['Date'].dt.day_name()
df['Month'] = df['Date'].dt.month_name()
df['MonthNum'] = df['Date'].dt.month
df['IsWeekend'] = df['Date'].dt.dayofweek >= 5

print('=== BASIC SHAPE ===')
print(f"Rows: {len(df)}")
print(f"Date range: {df['Date'].min().date()} to {df['Date'].max().date()}")
print(df.isna().sum().to_string())
print()

print('=== OVERALL SUMMARY STATS ===')
print(df[['Daily_Ridership', 'Ticket_Sales', 'Delay_Count', 'Avg_Delay_Minutes']].describe().to_string())
print()

print('=== DAY-OF-WEEK AVERAGES ===')
dow_order = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday']
dow = df.groupby('DayOfWeek')[['Daily_Ridership', 'Ticket_Sales', 'Delay_Count', 'Avg_Delay_Minutes']].mean().reindex(dow_order)
print(dow.round(1).to_string())
print()
print('Weekday vs weekend average ridership:')
print(df.groupby('IsWeekend')['Daily_Ridership'].mean().round(1).to_string())
print()

print('=== MONTHLY AVERAGES (seasonality) ===')
month_order = ['January','February','March','April','May','June','July','August','September','October','November','December']
monthly = df.groupby('Month')[['Daily_Ridership', 'Ticket_Sales', 'Delay_Count', 'Avg_Delay_Minutes']].mean().reindex(month_order)
print(monthly.round(1).to_string())
print()
print('Top 3 months by avg ridership:')
print(monthly['Daily_Ridership'].sort_values(ascending=False).head(3).round(1).to_string())
print('Bottom 3 months by avg ridership:')
print(monthly['Daily_Ridership'].sort_values().head(3).round(1).to_string())
print()

print('=== CORRELATIONS ===')
print('Delay_Count vs Ticket_Sales:      r =', round(df['Delay_Count'].corr(df['Ticket_Sales']), 3))
print('Avg_Delay_Minutes vs Ticket_Sales: r =', round(df['Avg_Delay_Minutes'].corr(df['Ticket_Sales']), 3))
print('Delay_Count vs Daily_Ridership:    r =', round(df['Delay_Count'].corr(df['Daily_Ridership']), 3))
print('Avg_Delay_Minutes vs Daily_Ridership: r =', round(df['Avg_Delay_Minutes'].corr(df['Daily_Ridership']), 3))
print('Daily_Ridership vs Ticket_Sales:   r =', round(df['Daily_Ridership'].corr(df['Ticket_Sales']), 3))
print()

print('=== TICKET SALES vs RIDERSHIP GAP ===')
df['SalesMinusRidership'] = df['Ticket_Sales'] - df['Daily_Ridership']
print(df['SalesMinusRidership'].describe().round(1).to_string())
print('Days where |gap| > 2 standard deviations:')
gap_mean, gap_std = df['SalesMinusRidership'].mean(), df['SalesMinusRidership'].std()
gap_outliers = df[np.abs(df['SalesMinusRidership'] - gap_mean) > 2 * gap_std]
print(gap_outliers[['Date', 'DayOfWeek', 'Daily_Ridership', 'Ticket_Sales', 'SalesMinusRidership']].to_string(index=False))
print()

print('=== ANOMALY DETECTION (z-score > 3 within each column) ===')
for col in ['Daily_Ridership', 'Ticket_Sales', 'Delay_Count', 'Avg_Delay_Minutes']:
    z = (df[col] - df[col].mean()) / df[col].std()
    outliers = df[np.abs(z) > 3]
    print(f'--- {col} (mean={df[col].mean():.1f}, std={df[col].std():.1f}) ---')
    if len(outliers):
        print(outliers[['Date', 'DayOfWeek', col]].assign(z=z[np.abs(z) > 3].round(2)).to_string(index=False))
    else:
        print('none above |z|>3')
    print()

print('=== ANOMALY DETECTION (z-score > 2.5, wider net) ===')
for col in ['Daily_Ridership', 'Delay_Count', 'Avg_Delay_Minutes']:
    z = (df[col] - df[col].mean()) / df[col].std()
    outliers = df[np.abs(z) > 2.5]
    print(f'--- {col} ---')
    print(outliers[['Date', 'DayOfWeek', col]].assign(z=z[np.abs(z) > 2.5].round(2)).to_string(index=False))
    print()

print('=== HIGH DELAY DAYS (top 10 by Avg_Delay_Minutes) ===')
print(df.nlargest(10, 'Avg_Delay_Minutes')[['Date', 'DayOfWeek', 'Delay_Count', 'Avg_Delay_Minutes', 'Daily_Ridership', 'Ticket_Sales']].to_string(index=False))
print()

print('=== LOWEST RIDERSHIP DAYS (bottom 10) ===')
print(df.nsmallest(10, 'Daily_Ridership')[['Date', 'DayOfWeek', 'Daily_Ridership', 'Ticket_Sales', 'Delay_Count', 'Avg_Delay_Minutes']].to_string(index=False))
print()

print('=== HIGHEST RIDERSHIP DAYS (top 10) ===')
print(df.nlargest(10, 'Daily_Ridership')[['Date', 'DayOfWeek', 'Daily_Ridership', 'Ticket_Sales', 'Delay_Count', 'Avg_Delay_Minutes']].to_string(index=False))

df.to_csv('cleaned_with_features.csv', index=False)
