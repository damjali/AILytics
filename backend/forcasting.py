from flask import Flask, request, jsonify
import pandas as pd
from statsmodels.tsa.forecasting.stl import STLForecast
from statsmodels.tsa.arima.model import ARIMA
from datetime import datetime
import os

app = Flask(__name__)
os.chdir("backend\cache")
print("Current working directory:", os.getcwd())
# Load your sales data (assumes the uploaded file is saved locally)
df = pd.read_csv("Chocojar_cleaned.csv")
df['TransactionDate'] = pd.to_datetime(df['TransactionDate'], dayfirst=True)

# Pre-aggregate
daily_summary = df.groupby('TransactionDate').agg(
    revenue=('SellingPrice(RM)', 'sum'),
    expenses=('CostPrice(RM)', 'sum'),
    profit=('Profit(RM)', 'sum')
).asfreq('D', fill_value=0)

forecast_periods = {
    '1_month': 30,
    '3_months': 90,
    '5_months': 150,
    '1_year': 365
}

def forecast_series(ts, periods):
    model = STLForecast(ts, ARIMA, model_kwargs={"order": (1, 1, 1)}, period=7)
    results = model.fit()
    return results.forecast(periods)

@app.route('/forecast')
def forecast():
    forecast_type = request.args.get('type', 'sales')
    period_key = request.args.get('period', '1_month')
    periods = forecast_periods.get(period_key, 30)

    if forecast_type not in ['sales', 'revenue', 'expense']:
        return jsonify({'error': 'Invalid forecast type'}), 400

    revenue = forecast_series(daily_summary['revenue'], periods)
    expenses = forecast_series(daily_summary['expenses'], periods)
    profit = forecast_series(daily_summary['profit'], periods)

    forecast_data = []
    for i in range(periods):
        date = (daily_summary.index[-1] + pd.Timedelta(days=i + 1)).strftime('%Y-%m-%d')
        rev = float(revenue[i])
        exp = float(expenses[i])
        prof = float(profit[i])
        margin = round((prof / rev * 100) if rev != 0 else 0, 2)

        forecast_data.append({
            'Date': date,
            'Forecasted_Revenue': rev,
            'Forecasted_Expenses': exp,
            'Forecasted_Profit': prof,
            'Forecasted_Margin(%)': margin
        })

    return jsonify(forecast_data)
