from flask import Flask, request, jsonify
from flask_cors import CORS  # ✅ Allows requests from Flutter
import pandas as pd

app = Flask(__name__)
CORS(app)  # ✅ Enable CORS for all routes

@app.route('/')
def home():
    """✅ Root Route to Check If API is Running"""
    return jsonify({"message": "Flask API is running!"})

@app.route('/process-file', methods=['POST'])
def process_file():
    """✅ Process Uploaded CSV File"""
    if 'file' not in request.files:
        return jsonify({'error': 'No file part'}), 400

    file = request.files['file']
    if file.filename == '':
        return jsonify({'error': 'No selected file'}), 400

    try:
        df = pd.read_csv(file)  # ✅ Read CSV File

        # ✅ Data Cleaning
        total_rows = len(df)
        df = df.drop_duplicates()  # Remove Duplicates
        duplicate_rows_removed = total_rows - len(df)
        df = df.fillna("N/A")  # Handle Missing Values
        df.columns = df.columns.str.lower().str.replace(' ', '_')  # Standardize Column Names

        # ✅ Convert Cleaned Data to JSON
        cleaned_data = df.to_dict(orient='records')

        return jsonify({
            "message": "File successfully processed",
            "cleaned_data": cleaned_data,
            "cleaning_summary": {
                "total_rows_processed": total_rows,
                "duplicate_rows_removed": duplicate_rows_removed,
                "missing_values_filled": int(df.isnull().sum().sum()),  # Convert to int
                "column_names_standardized": True,
            },
        })

    except Exception as e:
        return jsonify({"error": str(e)}), 500

if __name__ == '__main__':
    app.run(debug=True)
