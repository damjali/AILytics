import os
import hashlib
import pandas as pd
from flask import Flask, request, jsonify
from flask_cors import CORS
import google.generativeai as genai  # Import Gemini AI SDK
from langchain.memory import ConversationBufferMemory
from langchain.memory.chat_message_histories import ChatMessageHistory

app = Flask(__name__)
CORS(app)

CACHE_FOLDER = "cache"
os.makedirs(CACHE_FOLDER, exist_ok=True)

# Set up Gemini AI
GENAI_API_KEY = "AIzaSyCBy3-xAk55GYzQJc58RUeR_ipAFK_hd2Q"
genai.configure(api_key=GENAI_API_KEY)

# Set up memory for chat history
chat_memory = ChatMessageHistory()
memory = ConversationBufferMemory(chat_memory=chat_memory, return_messages=True)

def get_file_hash(file):
    """Generate a unique hash for a file"""
    hasher = hashlib.md5()
    for chunk in iter(lambda: file.read(4096), b""):
        hasher.update(chunk)
    file.seek(0)  # Reset file pointer after reading
    return hasher.hexdigest()

def get_most_recent_file():
    """Find the most recent cached CSV file"""
    files = [os.path.join(CACHE_FOLDER, f) for f in os.listdir(CACHE_FOLDER) if f.endswith(".csv")]
    if not files:
        return None
    return max(files, key=os.path.getctime)  # Get the most recently created file

@app.route('/')
def home():
    """Root Route to Check If API is Running"""
    return jsonify({"message": "Flask API is running!"})

@app.route('/process-file', methods=['POST'])
def process_file():
    """Process Uploaded CSV File and Use Cache"""
    if 'file' not in request.files:
        return jsonify({'error': 'No file part'}), 400

    file = request.files['file']
    if file.filename == '':
        return jsonify({'error': 'No selected file'}), 400

    try:
        file_hash = get_file_hash(file)
        cache_path = os.path.join(CACHE_FOLDER, f"{file_hash}.csv")

        # Check if cleaned file already exists
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

@app.route('/analyze-file', methods=['GET'])
def analyze_file():
    """Retrieve the most recent cached file content without NaN errors"""
    recent_file = get_most_recent_file()
    if not recent_file:
        return jsonify({"error": "No cached file found"}), 404

    df = pd.read_csv(recent_file)

    # Generate summary, replacing NaN with a placeholder
    summary = df.describe(include="all").to_dict()
    summary = {col: {stat: (val if pd.notna(val) else "N/A") for stat, val in stats.items()} for col, stats in summary.items()}

    sample_data = df.fillna("N/A").head(5).to_dict(orient="records")  # Replace NaN in sample

    return jsonify({
        "message": "Recent file loaded",
        "file_summary": summary,
        "sample_data": sample_data
    })

@app.route('/chat', methods=['POST'])
def chat():
    """Chatbot API using Gemini AI with Memory"""
    data = request.json
    user_message = data.get("message", "")
    file_context = data.get("file_context", None)  # Context from recent file

    if not user_message:
        return jsonify({"error": "Message is required"}), 400

    # Store conversation history
    memory.chat_memory.add_user_message(user_message)

    prompt = "You are an AI chatbot that helps users with business-related questions."
    if file_context:
        prompt += f" The user has uploaded a dataset with the following context: {file_context}. Respond based on this data when relevant."

    # Add conversation history to prompt
    history = "\n".join([f"{msg.type}: {msg.content}" for msg in memory.chat_memory.messages])
    final_prompt = f"{prompt}\nChat History:\n{history}\nUser: {user_message}\nAI:"

    model = genai.GenerativeModel("gemini-2.0-flash")
    response = model.generate_content(final_prompt)

    # Store AI response in memory
    memory.chat_memory.add_ai_message(response.text)

    return jsonify({"response": response.text})

if __name__ == '__main__':
    app.run(host="0.0.0.0", port=5000, debug=True)
