import os
import hashlib
import pandas as pd
from flask import Flask, request, jsonify
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
        cache_filename = f"{original_filename}_{file_hash}_read.csv"
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
            'cached': cached
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