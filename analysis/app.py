"""
Flask API service for sleep analysis.
Can be run as a standalone service or in Docker.
"""
from flask import Flask, request, jsonify
from flask_cors import CORS
from sleep_analyzer import analyze_sleep_data, analyze_sleep_trends
import json
import os

app = Flask(__name__)
CORS(app)  # Enable CORS for all routes

@app.route('/health', methods=['GET'])
def health():
    """Health check endpoint."""
    return jsonify({
        'status': 'healthy',
        'service': 'sleep-analyzer',
    }), 200

@app.route('/analyze', methods=['POST'])
def analyze():
    """
    Analyze sleep data endpoint.
    
    Expects JSON body with sleep data:
    {
        "sessions": [...],
        "stages": [...],
        "start_time": "...",
        "end_time": "..."
    }
    """
    try:
        data = request.get_json()
        
        if not data:
            return jsonify({
                'error': 'No data provided'
            }), 400
        
        # Perform analysis
        result = analyze_sleep_data(data)
        
        return jsonify(result), 200
    
    except Exception as e:
        return jsonify({
            'error': str(e)
        }), 500

@app.route('/analyze/trends', methods=['POST'])
def analyze_trends():
    """
    Analyze sleep trends over time.
    
    Expects JSON body with:
    {
        "sessions": [...],
        "days": 30
    }
    """
    try:
        data = request.get_json()
        
        if not data:
            return jsonify({
                'error': 'No data provided'
            }), 400
        
        sessions = data.get('sessions', [])
        days = data.get('days', 30)
        
        result = analyze_sleep_trends(sessions, days)
        
        return jsonify(result), 200
    
    except Exception as e:
        return jsonify({
            'error': str(e)
        }), 500

if __name__ == '__main__':
    port = int(os.environ.get('PORT', 8000))
    app.run(host='0.0.0.0', port=port, debug=False)

