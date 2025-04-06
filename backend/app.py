import os
import hashlib
import pandas as pd
from flask import Flask, json, request, jsonify
from flask_cors import CORS

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

@app.route('/process-final-result', methods=['POST'])
def process_final_result():
    """
    Calculate revenue, expenses, profit, and margin based on the selected features.
    Expects form fields:
      - featureClassifications: a JSON string with the classification map.
      - cache_filename: the filename of the cached CSV.
    """
    try:
        # Retrieve data from form fields instead of JSON.
        classification_map_json = request.form.get('featureClassifications', '{}')
        classification_map = json.loads(classification_map_json)
        cache_filename = request.form.get('cache_filename')
        
        if not cache_filename:
            return jsonify({"error": "No cache filename provided"}), 400
        
        # Check the cache filename refers to the cached file.
        if not os.path.exists(cache_filename):
            return jsonify({"error": "Cached file not found"}), 404
        
        df = pd.read_csv(cache_filename)

        # Identify the revenue and expense columns based on the classification_map.
        revenue_cols = [col for col, classification in classification_map.items()
                        if classification.lower() == "revenue" and col in df.columns]
        expense_cols = [col for col, classification in classification_map.items()
                        if classification.lower() == "expense" and col in df.columns]

        # Sum the values in each group; assumes the columns contain numeric data.
        revenue = df[revenue_cols].sum().sum() if revenue_cols else 0
        expenses = df[expense_cols].sum().sum() if expense_cols else 0
        profit = revenue - expenses
        margin = (profit / revenue * 100) if revenue != 0 else 0

        return jsonify({
            "revenue": revenue,
            "expenses": expenses,
            "profit": profit,
            "margin": margin
        }), 200

    except Exception as e:
        return jsonify({"error": str(e)}), 500

@app.route('/process-selections', methods=['POST'])
def process_selections():
    """Process Uploaded CSV File, extract features (column names), and return them for selection."""
    if 'file' not in request.files:
        return jsonify({'error': 'No file part'}), 400

    file = request.files['file']
    if file.filename == '':
        return jsonify({'error': 'No selected file'}), 400

    try:
        # Generate hash and extract original filename
        file_hash = get_file_hash(file)
        original_filename = os.path.splitext(file.filename)[0]
        cache_filename = f"{original_filename}_read.csv"
        cache_path = os.path.join(CACHE_FOLDER, cache_filename)

        # Check if the file exists in cache
        if os.path.exists(cache_path):
            df = pd.read_csv(cache_path)
            cached = True
        else:
            df = pd.read_csv(file)
            # Cache the file for later use
            df.to_csv(cache_path, index=False)
            cached = False

        # Extract column names (features) from the dataset
        columns = df.columns.tolist()

        # Return the list of columns to the user along with cache info if desired
        return jsonify({
            'columns': columns,
            'cached': cached,
            'cache_filename': cache_path
        }), 200

    except Exception as e:
        return jsonify({"error": str(e)}), 500

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
        cleaned_filename = f"{original_filename}_cleaned.csv"
        cache_path = os.path.join(CACHE_FOLDER, cleaned_filename)

        # Check if read file already exists
        if os.path.exists(cache_path):
            df = pd.read_csv(cache_path)  # Load from cache
            cached = True
        else:
            df = pd.read_csv(file)  # Read CSV File
            total_rows = len(df)
            df = df.drop_duplicates()  # Remove Duplicates
            duplicate_rows_removed = total_rows - len(df)
            df = df.fillna("N/A")  # Handle Missing Values
            df.columns = df.columns.str.lower().str.replace(' ', '_')  # Standardize Column Names
            
            df.to_csv(cache_path, index=False)  # Save cleaned file to cache
            cached = False

        cleaned_data = df.to_dict(orient='records')

        return jsonify({
            "message": "File successfully processed",
            "cleaned_filename": cleaned_filename,
            "cleaned_data": cleaned_data,
            "cached": cached,
            "cleaning_summary": {
                "total_rows_processed": len(df),
                "duplicate_rows_removed": duplicate_rows_removed if not cached else "Loaded from cache",
                "missing_values_filled": int(df.isnull().sum().sum()) if not cached else "Loaded from cache",
                "column_names_standardized": True,
            },
        })

    except Exception as e:
        return jsonify({"error": str(e)}), 500

if __name__ == '__main__':
    app.run(debug=True, port=5000)