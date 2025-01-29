# metadata_processor/main.py
from google.cloud import spanner
import base64
import json
import functions_framework

# Initialize Spanner client
spanner_client = spanner.Client()
instance_id = 'image-metadata'
database_id = 'image-db'
instance = spanner_client.instance(instance_id)
database = instance.database(database_id)

@functions_framework.cloud_event
def process_metadata(cloud_event):
    """Triggered by a Pub/Sub message.
    Args:
        cloud_event: Cloud Event containing the Pub/Sub message
    """
    # Get message data
    pubsub_message = base64.b64decode(cloud_event.data["message"]["data"]).decode()
    message_data = json.loads(pubsub_message)

    # Insert into Spanner
    with database.batch() as batch:
        batch.insert(
            table='ImageMetadata',
            columns=['ImageId', 'OriginalName', 'ProcessingStatus', 
                    'StoragePath', 'ProcessedAt', 'Tags'],
            values=[(
                message_data['image_id'],
                message_data['original_name'],
                'PROCESSED',
                message_data['storage_path'],
                spanner.COMMIT_TIMESTAMP,
                message_data.get('tags', [])
            )]
        )

    print(f"Successfully processed metadata for image: {message_data['image_id']}")