from flask import Flask, request, render_template_string, redirect
import requests
import os
from google.auth import default
from google.auth.transport.requests import Request

app = Flask(__name__)

FUNCTION_URL = os.environ['FUNCTION_URL']

@app.route('/')
def home():
    return render_template_string('''
        <!DOCTYPE html>
        <html>
        <head>
            <title>Background Removal Demo</title>
            <style>
                body { font-family: Arial, sans-serif; max-width: 800px; margin: 0 auto; padding: 20px; }
                .container { border: 1px solid #ccc; padding: 20px; border-radius: 5px; }
                .btn { background: #4285f4; color: white; padding: 10px 20px; border: none; border-radius: 4px; }
                .result { margin-top: 20px; }
                img { max-width: 100%; height: auto; }
            </style>
        </head>
        <body>
            <div class="container">
                <h1>Background Removal Demo</h1>
                <form action="/process" method="POST" enctype="multipart/form-data">
                    <input type="file" name="image" accept="image/*" required>
                    <button type="submit" class="btn">Remove Background</button>
                </form>
                {% if image_url %}
                <div class="result">
                    <h2>Processed Image:</h2>
                    <img src="{{ image_url }}" alt="Processed image">
                </div>
                {% endif %}
            </div>
        </body>
        </html>
    ''', image_url=request.args.get('image_url'))

@app.route('/process', methods=['POST'])
def process():
    if 'image' not in request.files:
        return 'No image uploaded', 400
    
    # Get credentials and token
    credentials, project = default()
    credentials.refresh(Request())
    
    # Send request to Cloud Function
    image = request.files['image']
    headers = {
        'Authorization': f'Bearer {credentials.token}'
    }
    
    response = requests.post(
        FUNCTION_URL,
        files={'image': image},
        headers=headers
    )
    
    if response.status_code == 200:
        result = response.json()
        return redirect(f'/?image_url={result["signed_url"]}')
    else:
        return f'Error: {response.text}', response.status_code

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=8080)