import hashlib
import os
from flask import Flask, request, jsonify
from flask_cors import CORS
import pandas as pd
import io

app = Flask(__name__)
CORS(app)  # Enable CORS for all routes

CACHE_FOLDER = "cache"
os.makedirs(CACHE_FOLDER, exist_ok=True)  # Create cache folder if it doesn't exist

@app.route('/')
def home():
    """Root Route to Check If API is Running"""
    return jsonify({"message": "Flask API is running!"})

def get_file_hash(file):
    """Generate a unique hash for a file"""
    hasher = hashlib.md5()
    for chunk in iter(lambda: file.read(4096), b""):
        hasher.update(chunk)
    file.seek(0)  # Reset file pointer after reading
    return hasher.hexdigest()

@app.route('/process-file', methods=['POST'])
def process_file():
    """Process Uploaded CSV File and Use Cache"""
    if 'file' not in request.files:
        return jsonify({'error': 'No file part'}), 400

    file = request.files['file']
    if file.filename == '':
        return jsonify({'error': 'No selected file'}), 400

    try:
        # Generate hash and extract original filename
        file_hash = get_file_hash(file)
        original_filename = os.path.splitext(file.filename)[0]
        read_filename = f"{original_filename}_read.csv"
        cache_path = os.path.join(CACHE_FOLDER, read_filename)

        # Check if read file already exists
        if os.path.exists(cache_path):
            df = pd.read_csv(cache_path)  # Load from cache
            cached = True
        else:
            df = pd.read_csv(file)  # Read CSV File
            data = request.get_json()
            if not data or 'classifications' not in data:
                return jsonify({'error': 'No classification data provided'}), 400
            
            

    except Exception as e:
        return jsonify({"error": str(e)}), 500

@app.route('/process_data', methods=['POST'])
def process_data():
    global csv_data
    data = request.get_json()
    if not data or 'classifications' not in data:
        return jsonify({'error': 'No classification data provided'}), 400
    
    classifications = data['classifications']  # Expected format: { "column_name": "revenue"/"expense"/"ignore", ... }
    
    # Check if CSV data is available
    if csv_data is None:
        return jsonify({'error': 'No CSV data available. Please upload a CSV file first.'}), 400

    # Identify columns for revenue and expenses
    revenue_cols = [col for col, cl in classifications.items() if cl == 'revenue' and col in csv_data.columns]
    expense_cols = [col for col, cl in classifications.items() if cl == 'expense' and col in csv_data.columns]
    
    try:
        # Calculate totals. Assumes the CSV columns contain numeric data.
        revenue = csv_data[revenue_cols].sum().sum() if revenue_cols else 0
        expenses = csv_data[expense_cols].sum().sum() if expense_cols else 0
        profit = revenue - expenses
        margin = (profit / revenue * 100) if revenue != 0 else 0

        # Return the computed data as JSON
        return jsonify({
            'revenue': revenue,
            'expenses': expenses, 
            'profit': profit,
            'margin': margin
        }), 200
    except Exception as e:
        return jsonify({'error': str(e)}), 500

if __name__ == '__main__':
    app.run(debug=True, port=5001)
