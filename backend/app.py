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

hardcodedFile = "backend\cache\Bakery_cleaned.csv"

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

    
@app.route('/get-revenue-recommendations', methods=['POST'])
def get_revenue_recommendations():
    """Generate revenue recommendations based on submitted data"""
    try:
        # Parse the incoming JSON data
        payload = request.get_json()
        
        if not payload or 'data' not in payload:
            return jsonify({'error': 'No data provided'}), 400
            
        # Extract data from the payload
        data = payload['data']
        prediction_type = payload.get('predictionType', 'revenue')
        data_context = payload.get('dataContext', {})
        
        # Convert cleaned_data list of dictionaries to DataFrame
        if 'cleaned_data' in data and isinstance(data['cleaned_data'], list):
            df = pd.DataFrame(data['cleaned_data'])
        else:
            return jsonify({'error': 'Invalid data format'}), 400
            
        # Generate recommendations using the existing function
        recommendations = generate_revenue_recommendations(df)
        
        return jsonify(recommendations)
        
    except Exception as e:
        # Return detailed error for debugging
        error_message = f"Error generating recommendations: {str(e)}"
        print(error_message)  # Log for server debugging
        return jsonify({"error": error_message}), 500

def generate_revenue_recommendations(df, data_insights=None, stats_insights=None):
    """Generate highly specific revenue-focused recommendations from the data
    
    Parameters:
    df (pandas.DataFrame): The cleaned data DataFrame
    data_insights (dict, optional): Pre-computed data insights
    stats_insights (dict, optional): Pre-computed statistical insights
    
    Returns:
    dict: A dictionary with insights and revenue-specific recommendations
    """
    recommendations = {"recommendations": [], "insights": ""}
    
    try:
        # Identify revenue-related columns
        revenue_cols = [col for col in df.columns if any(term in col.lower() for term in 
                         ['revenue', 'income', 'profit', 'margin', 'earnings', 'roi', 'price', 
                          'monetization', 'arpu', 'arppu', 'ltv', 'gmv', 'arr', 'mrr'])]
        
        # Fall back to numeric columns if no revenue columns found
        if not revenue_cols:
            revenue_cols = df.select_dtypes(include=['number']).columns.tolist()[:2]
        
        # Get potential dimensional columns
        product_cols = [col for col in df.columns if any(term in col.lower() for term in 
                         ['product', 'item', 'category', 'service', 'sku', 'type'])]
        time_cols = [col for col in df.columns if any(term in col.lower() for term in 
                      ['date', 'month', 'year', 'time', 'period', 'day', 'quarter'])]
        customer_cols = [col for col in df.columns if any(term in col.lower() for term in 
                          ['customer', 'client', 'user', 'account', 'segment'])]
        
        insights_text = "Revenue Analysis: "
        recommendations_list = []
        
        # 1. Revenue Stream Analysis
        if revenue_cols:
            primary_revenue = revenue_cols[0]
            
            # Basic revenue metrics
            total_revenue = df[primary_revenue].sum()
            avg_revenue = df[primary_revenue].mean()
            max_revenue = df[primary_revenue].max()
            
            # Add to insights
            insights_text += f"Total revenue is {total_revenue:.2f} with an average of {avg_revenue:.2f} per record. "
            
            # Top revenue opportunities
            if product_cols and revenue_cols:
                for product_col in product_cols:
                    revenue_by_product = df.groupby(product_col)[primary_revenue].sum().sort_values(ascending=False)
                    
                    if not revenue_by_product.empty:
                        top_product = revenue_by_product.index[0]
                        second_product = revenue_by_product.index[1] if len(revenue_by_product) > 1 else None
                        
                        top_revenue = revenue_by_product.iloc[0]
                        contribution_pct = (top_revenue / total_revenue) * 100
                        
                        # Create product revenue recommendation
                        recommendations_list.append({
                            "title": f"Maximize Revenue from {top_product}: Your Top Performer at ${top_revenue:.2f}",
                            "description": f"{top_product} generates {contribution_pct:.1f}% of your total revenue (${top_revenue:.2f} of ${total_revenue:.2f}).",
                            "data_evidence": f"Product revenue analysis shows {top_product} generating ${top_revenue:.2f} in revenue.",
                            "action_items": [
                                f"Increase pricing for {top_product} by 5-10% to boost revenue from ${top_revenue:.2f} to ${top_revenue*1.07:.2f}",
                                f"Create premium tier offerings for {top_product} with 15-20% higher price points",
                                f"Implement value-based pricing strategy for {top_product} to reflect its market leadership",
                                f"Develop upsell and cross-sell opportunities with {top_product} to increase average transaction value"
                            ]
                        })
            
            # 2. Revenue Growth Opportunity
            if time_cols and revenue_cols:
                for time_col in time_cols:
                    try:
                        # Convert to datetime if possible
                        if df[time_col].dtype != 'datetime64[ns]':
                            df[time_col] = pd.to_datetime(df[time_col], errors='ignore')
                        
                        if df[time_col].dtype == 'datetime64[ns]':
                            # Analyze revenue over time
                            time_series = df.set_index(time_col).groupby(pd.Grouper(freq='M'))[primary_revenue].sum()
                            
                            if len(time_series) > 1:
                                # Calculate growth trends
                                latest_period = time_series.index[-1]
                                latest_value = time_series.iloc[-1]
                                
                                earliest_period = time_series.index[0]
                                earliest_value = time_series.iloc[0]
                                
                                # Calculate growth rate
                                growth_rate = ((latest_value / earliest_value) - 1) * 100 if earliest_value > 0 else 0
                                
                                # Extrapolate future growth
                                projected_value = latest_value * (1 + (growth_rate/100))
                                
                                # Format times for display
                                latest_period_str = latest_period.strftime('%B %Y')
                                earliest_period_str = earliest_period.strftime('%B %Y')
                                
                                # Create revenue growth recommendation
                                growth_direction = "grew" if growth_rate > 0 else "declined"
                                recommendations_list.append({
                                    "title": f"Accelerate Revenue Growth From ${latest_value:.2f} to ${projected_value:.2f}",
                                    "description": f"Revenue {growth_direction} by {abs(growth_rate):.1f}% from {earliest_period_str} (${earliest_value:.2f}) to {latest_period_str} (${latest_value:.2f}).",
                                    "data_evidence": f"Time series analysis shows ${earliest_value:.2f} to ${latest_value:.2f} ({growth_direction} by {abs(growth_rate):.1f}%)",
                                    "action_items": [
                                        f"Set aggressive growth targets to reach ${projected_value*1.2:.2f} by next quarter",
                                        f"Implement price optimization strategy to improve revenue from ${latest_value:.2f} to ${latest_value*1.15:.2f}",
                                        f"Develop recurring revenue streams to add ${latest_value*0.2:.2f} in predictable monthly revenue",
                                        f"Launch premium tier offerings to increase average transaction value by 25%"
                                    ]
                                })
                    except Exception as e:
                        continue
            
            # 3. Customer Monetization Strategy
            if customer_cols and revenue_cols:
                for customer_col in customer_cols:
                    customer_revenue = df.groupby(customer_col)[primary_revenue].sum().sort_values(ascending=False)
                    customer_count = len(customer_revenue)
                    
                    if customer_count > 0:
                        # Calculate customer monetization metrics
                        arpu = total_revenue / customer_count
                        top_customer_revenue = customer_revenue.iloc[0]
                        top_customer = customer_revenue.index[0]
                        
                        # Calculate monetization gap
                        monetization_potential = ((top_customer_revenue / arpu) - 1) * 100
                        
                        # Add customer insights
                        insights_text += f"Average revenue per customer is ${arpu:.2f}, while your top customer generates ${top_customer_revenue:.2f}. "
                        
                        # Create monetization recommendation
                        recommendations_list.append({
                            "title": f"Increase Average Revenue per Customer from ${arpu:.2f} to ${arpu*1.3:.2f}",
                            "description": f"Your top customer ({top_customer}) generates ${top_customer_revenue:.2f}, showing {monetization_potential:.1f}% upside potential compared to your average of ${arpu:.2f}.",
                            "data_evidence": f"Customer analysis shows ARPU: ${arpu:.2f} vs. top customer: ${top_customer_revenue:.2f}",
                            "action_items": [
                                f"Implement tiered pricing strategy to increase ARPU from ${arpu:.2f} to ${arpu*1.3:.2f}",
                                f"Develop upsell strategy for mid-tier customers based on top customer ({top_customer}) spending patterns",
                                f"Create loyalty program with premium pricing tiers to increase customer LTV by 40%",
                                f"Introduce premium support packages to add ${arpu*0.2:.2f} in additional revenue per customer"
                            ]
                        })
        
        # Complete the insights
        recommendations["insights"] = insights_text if len(insights_text) > 20 else f"Analysis of your data with {len(df)} rows reveals multiple revenue optimization opportunities."
        recommendations["recommendations"] = recommendations_list
        
        # Fallback if no specific recommendations were created
        if not recommendations_list:
            for col in revenue_cols[:2]:  # Limit to first two revenue columns
                current_value = df[col].sum() if pd.api.types.is_numeric_dtype(df[col]) else 0
                recommendations["recommendations"].append({
                    "title": f"Optimize {col} Revenue Stream from ${current_value:.2f} to ${current_value*1.25:.2f}",
                    "description": f"Your {col} revenue stream currently generates ${current_value:.2f} with potential for 25% growth.",
                    "data_evidence": f"Revenue analysis shows current {col}: ${current_value:.2f}",
                    "action_items": [
                        f"Implement value-based pricing to increase {col} from ${current_value:.2f} to ${current_value*1.25:.2f}",
                        f"Create premium tier for {col} with 30% higher price point",
                        f"Develop upsell strategy to boost average transaction value by 20%",
                        f"Optimize pricing tiers based on customer willingness to pay analysis"
                    ]
                })
    
    except Exception as e:
        # Create fallback recommendation
        recommendations["insights"] = f"Basic revenue analysis of your {len(df)} records."
        recommendations["recommendations"] = [{
            "title": "Implement Revenue Optimization Strategy",
            "description": "Analysis of your data reveals opportunities to optimize revenue streams.",
            "data_evidence": f"Dataset contains {len(df)} records with revenue potential.",
            "action_items": [
                "Develop tiered pricing strategy for core products",
                "Implement value-based pricing to increase margins",
                "Create premium offerings with higher price points",
                "Optimize discount strategy to maximize revenue"
            ]
        }]
    
    return recommendations

@app.route('/get-sales-recommendations', methods=['POST'])
def get_sales_recommendations():
    """Generate sales recommendations based on submitted data"""
    try:
        # Parse the incoming JSON data
        payload = request.get_json()
        
        if not payload or 'data' not in payload:
            return jsonify({'error': 'No data provided'}), 400
            
        # Extract data from the payload
        data = payload['data']
        prediction_type = payload.get('predictionType', 'sales')
        data_context = payload.get('dataContext', {})
        
        # Convert cleaned_data list of dictionaries to DataFrame
        if 'cleaned_data' in data and isinstance(data['cleaned_data'], list):
            df = pd.DataFrame(data['cleaned_data'])
        else:
            return jsonify({'error': 'Invalid data format'}), 400
            
        # Generate recommendations using the existing function
        recommendations = generate_sales_recommendations(df)
        
        return jsonify(recommendations)
        
    except Exception as e:
        # Return detailed error for debugging
        error_message = f"Error generating recommendations: {str(e)}"
        print(error_message)  # Log for server debugging
        return jsonify({"error": error_message}), 500

def generate_sales_recommendations(df, data_insights=None, stats_insights=None):
    """Generate highly specific sales-focused recommendations from the data
    
    Parameters:
    df (pandas.DataFrame): The cleaned data DataFrame
    data_insights (dict, optional): Pre-computed data insights
    stats_insights (dict, optional): Pre-computed statistical insights
    
    Returns:
    dict: A dictionary with insights and sales-specific recommendations
    """
    recommendations = {"recommendations": [], "insights": ""}
    
    try:
        # Identify sales-related columns
        sales_cols = [col for col in df.columns if any(term in col.lower() for term in 
                      ['sales', 'units', 'volume', 'quantity', 'orders', 'transactions', 'conversion', 
                       'deals', 'leads', 'opportunities', 'sales_count', 'unit_sold'])]
        
        # Fall back to numeric columns if no sales columns found
        if not sales_cols:
            sales_cols = df.select_dtypes(include=['number']).columns.tolist()[:2]
        
        # Get potential dimensional columns
        product_cols = [col for col in df.columns if any(term in col.lower() for term in 
                         ['product', 'item', 'category', 'service', 'sku', 'type'])]
        time_cols = [col for col in df.columns if any(term in col.lower() for term in 
                      ['date', 'month', 'year', 'time', 'period', 'day', 'quarter'])]
        region_cols = [col for col in df.columns if any(term in col.lower() for term in 
                        ['region', 'location', 'country', 'area', 'territory', 'city', 'state', 'market'])]
        channel_cols = [col for col in df.columns if any(term in col.lower() for term in 
                         ['channel', 'platform', 'source', 'medium', 'campaign', 'store', 'outlet'])]
        
        insights_text = "Sales Analysis: "
        recommendations_list = []
        
        # 1. Product Sales Performance Analysis
        if sales_cols:
            primary_sales = sales_cols[0]
            
            # Basic sales metrics
            total_sales = df[primary_sales].sum()
            avg_sales = df[primary_sales].mean()
            max_sales = df[primary_sales].max()
            
            # Add to insights
            insights_text += f"Total sales volume is {total_sales:.0f} units with an average of {avg_sales:.1f} units per record. "
            
            # Top product sales analysis
            if product_cols and sales_cols:
                for product_col in product_cols:
                    sales_by_product = df.groupby(product_col)[primary_sales].sum().sort_values(ascending=False)
                    
                    if not sales_by_product.empty:
                        top_product = sales_by_product.index[0]
                        second_product = sales_by_product.index[1] if len(sales_by_product) > 1 else None
                        lowest_product = sales_by_product.index[-1] if len(sales_by_product) > 1 else None
                        
                        top_sales = sales_by_product.iloc[0]
                        second_sales = sales_by_product.iloc[1] if len(sales_by_product) > 1 else 0
                        lowest_sales = sales_by_product.iloc[-1] if len(sales_by_product) > 1 else 0
                        
                        contribution_pct = (top_sales / total_sales) * 100
                        performance_gap = ((top_sales / second_sales) - 1) * 100 if second_sales > 0 else 0
                        
                        # Create product sales recommendation
                        recommendations_list.append({
                            "title": f"Maximize Sales Volume for {top_product}: Your Top Performer at {top_sales:.0f} Units",
                            "description": f"{top_product} accounts for {contribution_pct:.1f}% of your total sales ({top_sales:.0f} of {total_sales:.0f} units), outperforming {second_product} by {performance_gap:.1f}%.",
                            "data_evidence": f"Product sales analysis shows {top_product}: {top_sales:.0f} units vs. {second_product}: {second_sales:.0f} units.",
                            "action_items": [
                                f"Scale distribution for {top_product} to increase unit sales from {top_sales:.0f} to {top_sales*1.25:.0f}",
                                f"Bundle {top_product} with {lowest_product} to boost sales of underperforming product ({lowest_sales:.0f} units)",
                                f"Create promotional campaign featuring {top_product} as flagship offering to increase visibility",
                                f"Develop cross-sell strategy pairing {top_product} with complementary products to increase order value"
                            ]
                        })
        
        # 2. Sales Channel Optimization
        if channel_cols and sales_cols:
            for channel_col in channel_cols:
                sales_by_channel = df.groupby(channel_col)[primary_sales].sum().sort_values(ascending=False)
                
                if not sales_by_channel.empty:
                    top_channel = sales_by_channel.index[0]
                    second_channel = sales_by_channel.index[1] if len(sales_by_channel) > 1 else None
                    lowest_channel = sales_by_channel.index[-1] if len(sales_by_channel) > 1 else None
                    
                    top_channel_sales = sales_by_channel.iloc[0]
                    second_channel_sales = sales_by_channel.iloc[1] if len(sales_by_channel) > 1 else 0
                    lowest_channel_sales = sales_by_channel.iloc[-1] if len(sales_by_channel) > 1 else 0
                    
                    channel_contribution = (top_channel_sales / total_sales) * 100
                    channel_gap = ((top_channel_sales / second_channel_sales) - 1) * 100 if second_channel_sales > 0 else 0
                    
                    # Create channel recommendation
                    recommendations_list.append({
                        "title": f"Optimize {top_channel} Channel Performance: Your Leading Sales Driver at {top_channel_sales:.0f} Units",
                        "description": f"{top_channel} drives {channel_contribution:.1f}% of your total sales volume ({top_channel_sales:.0f} of {total_sales:.0f} units), outperforming {second_channel} by {channel_gap:.1f}%.",
                        "data_evidence": f"Channel analysis shows {top_channel}: {top_channel_sales:.0f} units vs. {second_channel}: {second_channel_sales:.0f} units.",
                        "action_items": [
                            f"Scale {top_channel} investment to increase unit sales from {top_channel_sales:.0f} to {top_channel_sales*1.3:.0f}",
                            f"Revitalize {lowest_channel} channel with new promotions to boost from {lowest_channel_sales:.0f} to {lowest_channel_sales*2:.0f} units",
                            f"Cross-train sales teams on {top_channel} best practices to improve overall performance",
                            f"Implement targeted incentives for sales teams to increase {second_channel} performance by 30%"
                        ]
                    })
        
        # 3. Regional Sales Strategy
        if region_cols and sales_cols:
            for region_col in region_cols:
                sales_by_region = df.groupby(region_col)[primary_sales].sum().sort_values(ascending=False)
                
                if not sales_by_region.empty:
                    top_region = sales_by_region.index[0]
                    second_region = sales_by_region.index[1] if len(sales_by_region) > 1 else None
                    lowest_region = sales_by_region.index[-1] if len(sales_by_region) > 1 else None
                    
                    top_region_sales = sales_by_region.iloc[0]
                    second_region_sales = sales_by_region.iloc[1] if len(sales_by_region) > 1 else 0
                    lowest_region_sales = sales_by_region.iloc[-1] if len(sales_by_region) > 1 else 0
                    
                    region_contribution = (top_region_sales / total_sales) * 100
                    region_gap = ((top_region_sales / lowest_region_sales) - 1) * 100 if lowest_region_sales > 0 else 0
                    
                    # Create regional sales recommendation
                    recommendations_list.append({
                        "title": f"Expand {top_region} Market Dominance: Leading Sales Territory at {top_region_sales:.0f} Units",
                        "description": f"{top_region} generates {region_contribution:.1f}% of your total sales ({top_region_sales:.0f} of {total_sales:.0f} units), outperforming your weakest region ({lowest_region}) by {region_gap:.1f}%.",
                        "data_evidence": f"Regional analysis shows {top_region}: {top_region_sales:.0f} units vs. {lowest_region}: {lowest_region_sales:.0f} units.",
                        "action_items": [
                            f"Replicate {top_region} sales tactics in {lowest_region} to increase from {lowest_region_sales:.0f} to {lowest_region_sales*2:.0f} units",
                            f"Expand sales team in {top_region} to capitalize on existing momentum and grow by 20%",
                            f"Develop tailored promotions for {second_region} to increase sales from {second_region_sales:.0f} to {second_region_sales*1.35:.0f} units",
                            f"Implement territory-specific incentives based on growth potential in each region"
                        ]
                    })
        
        # 4. Sales Growth Trend Analysis
        if time_cols and sales_cols:
            for time_col in time_cols:
                try:
                    # Convert to datetime if possible
                    if df[time_col].dtype != 'datetime64[ns]':
                        df[time_col] = pd.to_datetime(df[time_col], errors='ignore')
                    
                    if df[time_col].dtype == 'datetime64[ns]':
                        # Analyze sales over time
                        time_series = df.set_index(time_col).groupby(pd.Grouper(freq='M'))[primary_sales].sum()
                        
                        if len(time_series) > 1:
                            # Calculate growth trends
                            latest_period = time_series.index[-1]
                            latest_value = time_series.iloc[-1]
                            
                            earliest_period = time_series.index[0]
                            earliest_value = time_series.iloc[0]
                            
                            # Find peak sales period
                            peak_period = time_series.idxmax()
                            peak_value = time_series.max()
                            
                            # Calculate growth rate
                            growth_rate = ((latest_value / earliest_value) - 1) * 100 if earliest_value > 0 else 0
                            
                            # Format times for display
                            latest_period_str = latest_period.strftime('%B %Y')
                            earliest_period_str = earliest_period.strftime('%B %Y')
                            peak_period_str = peak_period.strftime('%B %Y')
                            
                            # Create sales growth recommendation
                            growth_direction = "grew" if growth_rate > 0 else "declined"
                            recommendations_list.append({
                                "title": f"Accelerate Sales Growth from {latest_value:.0f} to {latest_value*1.3:.0f} Units Monthly",
                                "description": f"Sales volume {growth_direction} by {abs(growth_rate):.1f}% from {earliest_period_str} ({earliest_value:.0f} units) to {latest_period_str} ({latest_value:.0f} units), with peak performance in {peak_period_str} ({peak_value:.0f} units).",
                                "data_evidence": f"Time series shows growth from {earliest_value:.0f} to {latest_value:.0f} units ({growth_direction} by {abs(growth_rate):.1f}%)",
                                "action_items": [
                                    f"Implement strategies from {peak_period_str} ({peak_value:.0f} units) to reach new sales peak of {peak_value*1.2:.0f} units",
                                    f"Develop seasonality-based promotions based on {peak_period_str} performance",
                                    f"Create sales acceleration program to increase monthly sales from {latest_value:.0f} to {latest_value*1.3:.0f} units",
                                    f"Set territory-specific targets based on historical growth patterns from {earliest_period_str} to {latest_period_str}"
                                ]
                            })
                except Exception as e:
                    continue
        
        # 5. Product Mix Optimization
        if product_cols and sales_cols and len(product_cols) > 0:
            product_col = product_cols[0]
            product_mix = df.groupby(product_col)[primary_sales].sum()
            
            # Calculate product mix metrics
            total_products = len(product_mix)
            
            if total_products > 1:
                # Sort products by sales volume
                sorted_products = product_mix.sort_values(ascending=False)
                
                # Calculate Pareto metrics (80/20 rule)
                cumulative_sales = sorted_products.cumsum()
                cumulative_pct = cumulative_sales / total_sales * 100
                
                # Find number of products accounting for 80% of sales
                core_products_count = (cumulative_pct <= 80).sum() + 1
                core_products_pct = (core_products_count / total_products) * 100
                
                # Get top 3 and bottom 3 products
                top_products = sorted_products.head(3)
                bottom_products = sorted_products.tail(3)
                
                # Create product mix recommendation
                insights_text += f"Your top {core_products_count} products ({core_products_pct:.1f}% of catalog) generate 80% of total sales. "
                
                top3_names = ", ".join(top_products.index[:3].astype(str))
                bottom3_names = ", ".join(bottom_products.index[:3].astype(str))
                
                recommendations_list.append({
                    "title": f"Optimize Product Mix: {core_products_count} Products Drive 80% of Your {total_sales:.0f} Units",
                    "description": f"Your top performers ({top3_names}) drive significant sales volume, while your bottom performers ({bottom3_names}) have minimal impact.",
                    "data_evidence": f"Product mix analysis shows {core_products_count} of {total_products} products ({core_products_pct:.1f}%) generate 80% of sales.",
                    "action_items": [
                        f"Focus marketing resources on top 3 products: {top3_names} to increase volumes by 25%",
                        f"Evaluate discontinuing bottom performers: {bottom3_names} with combined sales of only {bottom_products.sum():.0f} units",
                        f"Develop bundle strategy pairing top sellers with low performers to boost overall sales velocity",
                        f"Implement product portfolio rationalization to focus on {core_products_count} core products"
                    ]
                })
        
        # Complete the insights
        recommendations["insights"] = insights_text if len(insights_text) > 20 else f"Analysis of your data with {len(df)} rows reveals multiple sales optimization opportunities."
        recommendations["recommendations"] = recommendations_list
        
        # Fallback if no specific recommendations were created
        if not recommendations_list:
            for col in sales_cols[:2]:  # Limit to first two sales columns
                current_value = df[col].sum() if pd.api.types.is_numeric_dtype(df[col]) else 0
                recommendations["recommendations"].append({
                    "title": f"Boost {col} Volume from {current_value:.0f} to {current_value*1.3:.0f} Units",
                    "description": f"Your {col} currently stands at {current_value:.0f} units with potential for 30% growth.",
                    "data_evidence": f"Sales analysis shows current {col}: {current_value:.0f} units",
                    "action_items": [
                        f"Implement targeted sales promotions to increase {col} from {current_value:.0f} to {current_value*1.3:.0f} units",
                        f"Develop sales enablement training to improve conversion rates by 15%",
                        f"Create competitive displacement strategy to gain market share from competitors",
                        f"Optimize sales process to reduce sales cycle length by 20%"
                    ]
                })
    
    except Exception as e:
        # Create fallback recommendation
        recommendations["insights"] = f"Basic sales analysis of your {len(df)} records."
        recommendations["recommendations"] = [{
            "title": "Implement Sales Acceleration Strategy",
            "description": "Analysis of your data reveals opportunities to optimize sales performance.",
            "data_evidence": f"Dataset contains {len(df)} records with sales improvement potential.",
            "action_items": [
                "Develop targeted sales promotions for top products",
                "Implement sales team training and enablement program",
                "Create competitive displacement strategy to gain market share",
                "Optimize sales process to reduce friction and accelerate deals"
            ]
        }]
    
    return recommendations

@app.route('/get-expense-recommendations', methods=['POST'])
def get_expense_recommendations():
    """Generate expense recommendations based on submitted data"""
    try:
        # Parse the incoming JSON data
        payload = request.get_json()
        
        if not payload or 'data' not in payload:
            return jsonify({'error': 'No data provided'}), 400
            
        # Extract data from the payload
        data = payload['data']
        prediction_type = payload.get('predictionType', 'expense')
        data_context = payload.get('dataContext', {})
        
        # Convert cleaned_data list of dictionaries to DataFrame
        if 'cleaned_data' in data and isinstance(data['cleaned_data'], list):
            df = pd.DataFrame(data['cleaned_data'])
        else:
            return jsonify({'error': 'Invalid data format'}), 400
            
        # Generate recommendations using the existing function
        recommendations = generate_expense_recommendations(df)
        
        return jsonify(recommendations)
        
    except Exception as e:
        # Return detailed error for debugging
        error_message = f"Error generating recommendations: {str(e)}"
        print(error_message)  # Log for server debugging
        return jsonify({"error": error_message}), 500

def generate_expense_recommendations(df, data_insights=None, stats_insights=None):
    """Generate highly specific expense-focused recommendations from the data
    
    Parameters:
    df (pandas.DataFrame): The cleaned data DataFrame
    data_insights (dict, optional): Pre-computed data insights
    stats_insights (dict, optional): Pre-computed statistical insights
    
    Returns:
    dict: A dictionary with insights and expense-specific recommendations
    """
    recommendations = {"recommendations": [], "insights": ""}
    
    try:
        # Identify expense-related columns
        expense_cols = [col for col in df.columns if any(term in col.lower() for term in 
                         ['expense', 'cost', 'spend', 'expenditure', 'payment', 'outlay',
                          'budget', 'overhead', 'opex', 'capex', 'fee', 'charge'])]
        
        # Fall back to numeric columns if no expense columns found
        if not expense_cols:
            expense_cols = df.select_dtypes(include=['number']).columns.tolist()[:2]
        
        # Get potential dimensional columns
        category_cols = [col for col in df.columns if any(term in col.lower() for term in 
                         ['category', 'type', 'class', 'group', 'department', 'division'])]
        time_cols = [col for col in df.columns if any(term in col.lower() for term in 
                      ['date', 'month', 'year', 'time', 'period', 'day', 'quarter'])]
        vendor_cols = [col for col in df.columns if any(term in col.lower() for term in 
                          ['vendor', 'supplier', 'provider', 'contractor'])]
        
        insights_text = "Expense Analysis: "
        recommendations_list = []
        
        # 1. Expense Overview Analysis
        if expense_cols:
            primary_expense = expense_cols[0]
            
            # Basic expense metrics
            total_expense = df[primary_expense].sum()
            avg_expense = df[primary_expense].mean()
            max_expense = df[primary_expense].max()
            
            # Add to insights
            insights_text += f"Total expenses are ${total_expense:.2f} with an average of ${avg_expense:.2f} per record. "
            
            # Top expense categories
            if category_cols and expense_cols:
                for category_col in category_cols:
                    expense_by_category = df.groupby(category_col)[primary_expense].sum().sort_values(ascending=False)
                    
                    if not expense_by_category.empty:
                        top_category = expense_by_category.index[0]
                        second_category = expense_by_category.index[1] if len(expense_by_category) > 1 else None
                        
                        top_expense = expense_by_category.iloc[0]
                        contribution_pct = (top_expense / total_expense) * 100
                        
                        # Create category expense recommendation
                        recommendations_list.append({
                            "title": f"Optimize {top_category} Expenses: Your Highest Cost at ${top_expense:.2f}",
                            "description": f"{top_category} represents {contribution_pct:.1f}% of your total expenses (${top_expense:.2f} of ${total_expense:.2f}).",
                            "data_evidence": f"Category analysis shows {top_category} consuming ${top_expense:.2f} in expenses.",
                            "action_items": [
                                f"Implement cost reduction initiative for {top_category} to reduce expenses from ${top_expense:.2f} to ${top_expense*0.85:.2f}",
                                f"Renegotiate contracts with {top_category} vendors to achieve 10-15% savings",
                                f"Conduct spend audit for {top_category} to identify and eliminate wasteful spending",
                                f"Benchmark {top_category} spending against industry standards to identify optimization targets"
                            ]
                        })
            
            # 2. Expense Trend Analysis
            if time_cols and expense_cols:
                for time_col in time_cols:
                    try:
                        # Convert to datetime if possible
                        if df[time_col].dtype != 'datetime64[ns]':
                            df[time_col] = pd.to_datetime(df[time_col], errors='ignore')
                        
                        if df[time_col].dtype == 'datetime64[ns]':
                            # Analyze expenses over time
                            time_series = df.set_index(time_col).groupby(pd.Grouper(freq='M'))[primary_expense].sum()
                            
                            if len(time_series) > 1:
                                # Calculate trend
                                latest_period = time_series.index[-1]
                                latest_value = time_series.iloc[-1]
                                
                                earliest_period = time_series.index[0]
                                earliest_value = time_series.iloc[0]
                                
                                # Calculate growth rate
                                growth_rate = ((latest_value / earliest_value) - 1) * 100 if earliest_value > 0 else 0
                                
                                # Identify highest expense period
                                peak_period = time_series.idxmax()
                                peak_value = time_series.max()
                                
                                # Format times for display
                                latest_period_str = latest_period.strftime('%B %Y')
                                earliest_period_str = earliest_period.strftime('%B %Y')
                                peak_period_str = peak_period.strftime('%B %Y')
                                
                                # Create expense trend recommendation
                                trend_direction = "increased" if growth_rate > 0 else "decreased"
                                recommendations_list.append({
                                    "title": f"Control {latest_period_str} Expense Growth: ${latest_value:.2f} ({abs(growth_rate):.1f}% {trend_direction})",
                                    "description": f"Expenses have {trend_direction} by {abs(growth_rate):.1f}% from {earliest_period_str} (${earliest_value:.2f}) to {latest_period_str} (${latest_value:.2f}). Peak spending of ${peak_value:.2f} occurred in {peak_period_str}.",
                                    "data_evidence": f"Time series analysis shows ${earliest_value:.2f} to ${latest_value:.2f} ({trend_direction} by {abs(growth_rate):.1f}%)",
                                    "action_items": [
                                        f"Implement expense controls to reduce {latest_period_str} expenses from ${latest_value:.2f} to ${latest_value*0.9:.2f}",
                                        f"Analyze {peak_period_str} peak spending of ${peak_value:.2f} to identify cost reduction opportunities",
                                        f"Establish monthly expense budget caps of ${latest_value*0.85:.2f} based on historical trend analysis",
                                        f"Implement quarterly spend reviews to control expense growth factors"
                                    ]
                                })
                    except Exception as e:
                        continue
            
            # 3. Vendor Spend Analysis
            if vendor_cols and expense_cols:
                for vendor_col in vendor_cols:
                    vendor_expense = df.groupby(vendor_col)[primary_expense].sum().sort_values(ascending=False)
                    
                    if not vendor_expense.empty:
                        top_vendor = vendor_expense.index[0]
                        top_vendor_expense = vendor_expense.iloc[0]
                        vendor_count = len(vendor_expense)
                        
                        # Calculate vendor concentration
                        top_vendor_pct = (top_vendor_expense / total_expense) * 100
                        
                        # Calculate top 3 vendor concentration if possible
                        top3_concentration = "N/A"
                        if len(vendor_expense) >= 3:
                            top3_expense = vendor_expense.iloc[:3].sum()
                            top3_concentration = (top3_expense / total_expense) * 100
                        
                        # Add vendor insights
                        insights_text += f"Top vendor ({top_vendor}) accounts for ${top_vendor_expense:.2f} ({top_vendor_pct:.1f}% of total expenses). "
                        
                        # Create vendor recommendation
                        recommendations_list.append({
                            "title": f"Optimize {top_vendor} Vendor Spend: ${top_vendor_expense:.2f} ({top_vendor_pct:.1f}% of expenses)",
                            "description": f"Your top vendor ({top_vendor}) accounts for ${top_vendor_expense:.2f} ({top_vendor_pct:.1f}% of total expenses). " + 
                                         (f"Your top 3 vendors represent {top3_concentration:.1f}% of total spend." if top3_concentration != "N/A" else ""),
                            "data_evidence": f"Vendor analysis shows {top_vendor}: ${top_vendor_expense:.2f} of ${total_expense:.2f} total expenses",
                            "action_items": [
                                f"Renegotiate contract with {top_vendor} to reduce annual costs by 15% (${top_vendor_expense*0.15:.2f})",
                                f"Implement vendor consolidation strategy to reduce vendor count from {vendor_count} to {max(3, int(vendor_count*0.7))}",
                                f"Establish volume-based discount structure with {top_vendor} to achieve 10-15% savings",
                                f"Develop competitive bidding process for {top_vendor} services to benchmark pricing"
                            ]
                        })
                        
            # 4. Cost Efficiency Analysis
            if expense_cols and len(expense_cols) >= 2:
                # Compare different expense types
                primary_expense = expense_cols[0]
                secondary_expense = expense_cols[1]
                
                primary_total = df[primary_expense].sum()
                secondary_total = df[secondary_expense].sum()
                
                # Calculate ratio between expense types
                if secondary_total > 0:
                    expense_ratio = primary_total / secondary_total
                    
                    recommendations_list.append({
                        "title": f"Optimize Expense Allocation: {primary_expense}/{secondary_expense} Ratio of {expense_ratio:.2f}",
                        "description": f"Your {primary_expense} (${primary_total:.2f}) to {secondary_expense} (${secondary_total:.2f}) ratio is {expense_ratio:.2f}.",
                        "data_evidence": f"Expense analysis shows {primary_expense}: ${primary_total:.2f}, {secondary_expense}: ${secondary_total:.2f}, ratio: {expense_ratio:.2f}",
                        "action_items": [
                            f"Rebalance expense allocation to optimize {primary_expense}/{secondary_expense} ratio from {expense_ratio:.2f} to {min(expense_ratio*0.8, expense_ratio+0.5):.2f}",
                            f"Reduce {primary_expense if primary_total > secondary_total else secondary_expense} by ${max(primary_total, secondary_total)*0.1:.2f} to improve expense efficiency",
                            f"Implement cost controls to maintain optimal expense ratios across categories",
                            f"Establish budget guidelines based on ideal {primary_expense}/{secondary_expense} ratio of {min(expense_ratio*0.8, expense_ratio+0.5):.2f}"
                        ]
                    })
        
        # 5. Seasonal Expense Planning
        if time_cols and expense_cols:
            for time_col in time_cols:
                try:
                    # Convert to datetime if possible
                    if df[time_col].dtype != 'datetime64[ns]':
                        df[time_col] = pd.to_datetime(df[time_col], errors='ignore')
                    
                    if df[time_col].dtype == 'datetime64[ns]':
                        # Extract month information
                        df['month'] = df[time_col].dt.month
                        
                        # Analyze expenses by month
                        monthly_expenses = df.groupby('month')[expense_cols[0]].sum()
                        
                        if len(monthly_expenses) > 1:
                            # Find highest and lowest expense months
                            highest_month = monthly_expenses.idxmax()
                            highest_month_value = monthly_expenses.max()
                            
                            lowest_month = monthly_expenses.idxmin()
                            lowest_month_value = monthly_expenses.min()
                            
                            # Calculate variability
                            month_variance = (highest_month_value / lowest_month_value) if lowest_month_value > 0 else 1
                            
                            # Month names for display
                            month_names = {1:'January', 2:'February', 3:'March', 4:'April', 5:'May', 6:'June', 
                                          7:'July', 8:'August', 9:'September', 10:'October', 11:'November', 12:'December'}
                            
                            highest_month_name = month_names.get(highest_month, f"Month {highest_month}")
                            lowest_month_name = month_names.get(lowest_month, f"Month {lowest_month}")
                            
                            # Only create recommendation if there's significant seasonal variance
                            if month_variance > 1.2:
                                recommendations_list.append({
                                    "title": f"Manage Seasonal Expense Variation: {highest_month_name} (${highest_month_value:.2f}) vs {lowest_month_name} (${lowest_month_value:.2f})",
                                    "description": f"Your expenses in {highest_month_name} (${highest_month_value:.2f}) are {((highest_month_value/lowest_month_value)-1)*100:.1f}% higher than in {lowest_month_name} (${lowest_month_value:.2f}).",
                                    "data_evidence": f"Seasonal analysis shows {highest_month_name}: ${highest_month_value:.2f}, {lowest_month_name}: ${lowest_month_value:.2f}, variance: {month_variance:.2f}x",
                                    "action_items": [
                                        f"Implement expense smoothing strategies to reduce {highest_month_name} costs by ${(highest_month_value-lowest_month_value)*0.5:.2f}",
                                        f"Establish seasonal budget allocations with {highest_month_name} cap of ${highest_month_value*0.9:.2f}",
                                        f"Time major purchases to align with {lowest_month_name} or other low-expense periods",
                                        f"Develop cash flow management plan to accommodate {((highest_month_value/lowest_month_value)-1)*100:.1f}% seasonal expense variation"
                                    ]
                                })
                except Exception as e:
                    continue
        
        # Complete the insights
        recommendations["insights"] = insights_text if len(insights_text) > 20 else f"Analysis of your data with {len(df)} rows reveals multiple expense optimization opportunities."
        recommendations["recommendations"] = recommendations_list
        
        # Fallback if no specific recommendations were created
        if not recommendations_list:
            for col in expense_cols[:2]:  # Limit to first two expense columns
                current_value = df[col].sum() if pd.api.types.is_numeric_dtype(df[col]) else 0
                recommendations["recommendations"].append({
                    "title": f"Reduce {col} Expenses from ${current_value:.2f} to ${current_value*0.85:.2f}",
                    "description": f"Your {col} expenses currently total ${current_value:.2f} with potential for 15% reduction.",
                    "data_evidence": f"Expense analysis shows current {col}: ${current_value:.2f}",
                    "action_items": [
                        f"Implement cost-saving initiative to reduce {col} from ${current_value:.2f} to ${current_value*0.85:.2f}",
                        f"Conduct spend audit to identify unnecessary {col} expenses",
                        f"Establish budget controls to prevent {col} expense overruns",
                        f"Benchmark {col} spending against industry standards to identify reduction targets"
                    ]
                })
    
    except Exception as e:
        # Create fallback recommendation
        recommendations["insights"] = f"Basic expense analysis of your {len(df)} records."
        recommendations["recommendations"] = [{
            "title": "Implement Expense Reduction Strategy",
            "description": "Analysis of your data reveals opportunities to optimize expenses.",
            "data_evidence": f"Dataset contains {len(df)} records with expense optimization potential.",
            "action_items": [
                "Conduct comprehensive spend audit to identify cost reduction opportunities",
                "Implement vendor consolidation strategy to improve purchasing power",
                "Establish budget controls to prevent expense overruns",
                "Develop cost-conscious culture with departmental expense targets"
            ]
        }]
    
    return recommendations

if __name__ == '__main__':
    app.run(host="0.0.0.0", port=5000, debug=True)
