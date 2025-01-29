# image_processor/app.py
from flask import Flask, request, jsonify
from google.cloud import storage, pubsub_v1
from rembg import remove
from PIL import Image
import io
import uuid
import json
import os

app = Flask(__name__)

# Initialize clients
storage_client = storage.Client()
publisher = pubsub_v1.PublisherClient()

# Get project configuration
project_id = os.getenv('GOOGLE_CLOUD_PROJECT')
bucket_name = os.getenv('STORAGE_BUCKET')
topic_path = publisher.topic_path(project_id, 'image-processed')

@app.route('/process-image', methods=['POST'])
def process_image():
    # Verify authentication
    if 'Authorization' not in request.headers:
        return jsonify({'error': 'No authorization header'}), 401

    if 'image' not in request.files:
        return jsonify({'error': 'No image uploaded'}), 400

    try:
        # Get the image from the request
        image = request.files['image']
        original_name = image.filename
        
        # Process image with rembg
        input_image = Image.open(image)
        output_image = remove(input_image)
        
        # Save to memory buffer
        output_buffer = io.BytesIO()
        output_image.save(output_buffer, format='PNG')
        output_buffer.seek(0)
        
        # Generate unique filename
        image_id = str(uuid.uuid4())
        filename = f"processed/{image_id}.png"
        
        # Upload to GCS
        bucket = storage_client.bucket(bucket_name)
        blob = bucket.blob(filename)
        blob.upload_from_file(
            output_buffer,
            content_type='image/png',
            metadata={
                'processed': 'true',
                'processor': 'rembg'
            }
        )
        
        # Generate signed URL
        signed_url = blob.generate_signed_url(
            version="v4",
            expiration=300,  # 5 minutes
            method="GET"
        )
        
        # Publish metadata to Pub/Sub
        message_data = {
            'image_id': image_id,
            'original_name': original_name,
            'storage_path': f"gs://{bucket_name}/{filename}",
            'tags': ['background-removed']
        }
        
        publisher.publish(
            topic_path,
            json.dumps(message_data).encode('utf-8')
        )
        
        return jsonify({
            'signed_url': signed_url,
            'image_id': image_id
        })
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=int(os.environ.get('PORT', 8080)))