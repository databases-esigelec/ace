# Hands-on Lab: GKE and Cloud Functions Integration

## Learning Objectives
- Deploy a containerized application on GKE
- Create and deploy an image processing Cloud Function
- Set up secure communication between GKE and Cloud Functions
- Implement monitoring and observability
- Apply cloud architecture best practices

## Estimated Time: 1.5 hours

## Architecture Overview
```
┌─────────────────┐      ┌──────────────────┐
│  GKE Cluster    │      │  Cloud Function   │
│  ┌───────────┐  │      │                  │
│  │ Frontend  │  │──────▶  Process Image   │
│  │           │  │      │                  │
│  └───────────┘  │      │                  │
└─────────────────┘      └──────────────────┘
```

## Part 1: Setting up GKE

### 1.1 Create GKE Cluster
```bash
# Create a GKE cluster with workload identity enabled
gcloud container clusters create image-processing-cluster \
    --zone europe-west1-b \
    --num-nodes 2 \
    --machine-type e2-medium \
    --workload-pool=${GOOGLE_CLOUD_PROJECT}.svc.id.goog

# Get credentials
gcloud container clusters get-credentials image-processing-cluster --zone europe-west1-b
```

## Part 2: Frontend Application

### 2.1 Frontend Application Code
Create `app.py`:
```python
from flask import Flask, request, render_template_string
import requests
import os
from google.auth import default
from google.auth.transport.requests import Request

app = Flask(__name__)

# Get the Cloud Function URL from environment variable
FUNCTION_URL = os.environ['FUNCTION_URL']

@app.route('/')
def home():
    return render_template_string('''
        <!DOCTYPE html>
        <html>
        <head>
            <title>Image Processing Demo</title>
            <style>
                body { font-family: Arial, sans-serif; max-width: 800px; margin: 0 auto; padding: 20px; }
                .container { border: 1px solid #ccc; padding: 20px; border-radius: 5px; }
                .btn { background: #4285f4; color: white; padding: 10px 20px; border: none; border-radius: 4px; }
            </style>
        </head>
        <body>
            <div class="container">
                <h1>Image Processing Demo</h1>
                <form action="/process" method="POST" enctype="multipart/form-data">
                    <input type="file" name="image" accept="image/*" required>
                    <button type="submit" class="btn">Process Image</button>
                </form>
            </div>
        </body>
        </html>
    ''')

@app.route('/process', methods=['POST'])
def process():
    if 'image' not in request.files:
        return 'No image uploaded', 400
    
    # Get credentials and token
    credentials, project = default()
    credentials.refresh(Request())
    
    # Send request to Cloud Function with authentication
    image = request.files['image']
    headers = {
        'Authorization': f'Bearer {credentials.token}'
    }
    
    response = requests.post(
        FUNCTION_URL,
        files={'image': image},
        headers=headers
    )
    
    return response.content, response.status_code, {'Content-Type': 'image/png'}

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=8080)
```

### 2.2 Dockerfile
```dockerfile
FROM python:3.9-slim

WORKDIR /app

COPY requirements.txt .
RUN pip install -r requirements.txt

COPY app.py .

CMD ["python", "app.py"]
```

### 2.3 Requirements.txt
```text
flask==2.0.1
requests==2.26.0
google-auth==2.3.0
```

### 2.4 Build and Push Container
```bash
# Build the container
docker build -t gcr.io/${GOOGLE_CLOUD_PROJECT}/frontend:v1 .

# Push to Container Registry
docker push gcr.io/${GOOGLE_CLOUD_PROJECT}/frontend:v1
```

### 2.5 Kubernetes Deployment
Create `deployment.yaml`:
```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: frontend-sa
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: frontend
spec:
  replicas: 2
  selector:
    matchLabels:
      app: frontend
  template:
    metadata:
      labels:
        app: frontend
    spec:
      serviceAccountName: frontend-sa
      containers:
      - name: frontend
        image: gcr.io/${PROJECT_ID}/frontend:v1
        env:
        - name: FUNCTION_URL
          value: "https://europe-west1-${PROJECT_ID}.cloudfunctions.net/process-image"
        ports:
        - containerPort: 8080
        resources:
          requests:
            memory: "256Mi"
            cpu: "100m"
          limits:
            memory: "512Mi"
            cpu: "200m"
        readinessProbe:
          httpGet:
            path: /
            port: 8080
          initialDelaySeconds: 5
          periodSeconds: 10
        livenessProbe:
          httpGet:
            path: /
            port: 8080
          initialDelaySeconds: 15
          periodSeconds: 20
---
apiVersion: v1
kind: Service
metadata:
  name: frontend
spec:
  type: LoadBalancer
  ports:
  - port: 80
    targetPort: 8080
  selector:
    app: frontend
```

Deploy to GKE:
```bash
kubectl apply -f deployment.yaml
```

## Part 3: Cloud Function

### 3.1 Function Code
Create `main.py`:
```python
from PIL import Image
import io
from google.cloud import storage

def process_image(request):
    # Verify authentication
    auth = request.headers.get('Authorization')
    if not auth or not auth.startswith('Bearer '):
        return 'Unauthorized', 401

    if 'image' not in request.files:
        return 'No image uploaded', 400

    try:
        # Process image
        image = request.files['image']
        img = Image.open(image)
        
        # Apply transformations
        img = img.convert('L')  # Convert to grayscale
        img = img.filter(ImageFilter.FIND_EDGES)  # Apply edge detection
        
        # Save processed image
        output = io.BytesIO()
        img.save(output, format='PNG')
        
        return output.getvalue(), 200, {'Content-Type': 'image/png'}
        
    except Exception as e:
        return str(e), 500
```

### 3.2 Requirements.txt for Function
```text
Pillow==8.4.0
google-cloud-storage==1.42.0
```

### 3.3 Deploy Function
```bash
gcloud functions deploy process-image \
    --runtime python39 \
    --trigger-http \
    --region europe-west1 \
    --memory 256MB \
    --service-account functions-sa@${PROJECT_ID}.iam.gserviceaccount.com
```

## Part 4: IAM Setup

```bash
# Create service accounts if not exists
gcloud iam service-accounts create functions-sa --display-name "Cloud Functions Service Account"
gcloud iam service-accounts create frontend-sa --display-name "Frontend Service Account"

# Grant necessary permissions
gcloud projects add-iam-policy-binding ${GOOGLE_CLOUD_PROJECT} \
    --member "serviceAccount:frontend-sa@${GOOGLE_CLOUD_PROJECT}.iam.gserviceaccount.com" \
    --role "roles/cloudfunctions.invoker"
```

## Part 5: Testing

### 5.1 Get the Frontend IP
```bash
kubectl get service frontend
```

### 5.2 Monitoring Setup
```bash
# Create monitoring dashboard
gcloud monitoring dashboards create --config-from-file=dashboard.json

# Set up alerts for error rates
gcloud monitoring channels create \
    --display-name="Email Alerts" \
    --type=email \
    --email-address=your-email@domain.com
```

### 5.3 View Logs
```bash
# GKE logs
kubectl logs -l app=frontend

# Cloud Function logs
gcloud functions logs read process-image
```

## Common Issues and Troubleshooting

1. Authentication Issues
- Check IAM roles and service accounts
- Verify token generation in the frontend
- Check authorization headers

2. Network Issues
- Verify network policies
- Check firewall rules
- Ensure correct URLs and endpoints

3. Performance Issues
- Monitor CPU and memory usage
- Check container resource limits
- Review Cloud Function execution times
