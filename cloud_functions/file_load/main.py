import os
import time
import logging
import functions_framework
from google.cloud import dataform_v1beta1
from google.cloud import storage

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

PROJECT_ID = os.environ.get("DATAFORM_PROJECT_ID")
REGION = os.environ.get("DATAFORM_REGION")
REPOSITORY = os.environ.get("DATAFORM_REPOSITORY")
WORKSPACE = os.environ.get("DATAFORM_WORKSPACE") # Optional, defaults to "landing-workspace" if not provided

@functions_framework.cloud_event
def process_gcs_event(cloud_event):
    data = cloud_event.data
    logger.info(f"Received event: {data}")

    bucket_name = data["bucket"]
    object_name = data["name"]

    # Only process files placed in the 'landing/' directory
    if not object_name.startswith("landing/") or object_name.endswith("/"):
        logger.info(f"Ignoring object {object_name} as it's not a file in the landing folder.")
        return

    logger.info(f"Processing new file: gs://{bucket_name}/{object_name}")

    if not all([PROJECT_ID, REGION, REPOSITORY]):
         raise ValueError("DATAFORM_PROJECT_ID, DATAFORM_REGION, DATAFORM_REPOSITORY env vars required")

    dataform_client = dataform_v1beta1.DataformClient()
    repository_path = dataform_client.repository_path(PROJECT_ID, REGION, REPOSITORY)

    # 1. Create a compilation result with overridden landing_bucket and landing_file vars
    
    workspace = WORKSPACE or "landing-workspace"
    workspace_path = dataform_client.workspace_path(PROJECT_ID, REGION, REPOSITORY, workspace)

    compilation_request = dataform_v1beta1.CreateCompilationResultRequest(
        parent=repository_path,
        compilation_result=dataform_v1beta1.CompilationResult(
            workspace=workspace_path,
            code_compilation_config=dataform_v1beta1.CodeCompilationConfig(
                vars={
                    "landing_bucket": bucket_name,
                    "landing_file": object_name
                }
            )
        )
    )

    logger.info("Creating Dataform compilation result from workspace...")
    try:
        compilation_result = dataform_client.create_compilation_result(request=compilation_request)
    except Exception as e:
        logger.error(f"Failed to create Dataform compilation result: {e}")
        raise
        
    logger.info(f"Created compilation result: {compilation_result.name}")

    # 2. Trigger workflow invocation
    invocation_request = dataform_v1beta1.CreateWorkflowInvocationRequest(
        parent=repository_path,
        workflow_invocation=dataform_v1beta1.WorkflowInvocation(
            compilation_result=compilation_result.name,
            invocation_config=dataform_v1beta1.InvocationConfig(
                included_tags=["load_file"]
            )
        )
    )

    logger.info("Starting Dataform workflow invocation...")
    workflow_invocation = dataform_client.create_workflow_invocation(request=invocation_request)
    invocation_name = workflow_invocation.name
    logger.info(f"Created workflow invocation: {invocation_name}")

    # 3. Poll for completion
    while True:
        invocation = dataform_client.get_workflow_invocation(name=invocation_name)
        state = invocation.state
        logger.info(f"Workflow {invocation_name} state: {state.name}")
        
        # State Enum: 1 = RUNNING, 2 = SUCCEEDED, 3 = CANCELLED, 4 = FAILED
        if state == dataform_v1beta1.WorkflowInvocation.State.SUCCEEDED:
            logger.info("Workflow execution succeeded.")
            break
        elif state in (dataform_v1beta1.WorkflowInvocation.State.FAILED, dataform_v1beta1.WorkflowInvocation.State.CANCELLED):
            logger.error(f"Workflow failed or cancelled. State: {state.name}")
            raise RuntimeError(f"Dataform workflow did not succeed. State: {state.name}")
            
        time.sleep(10) # Poll every 10 seconds

    # 4. Move file to archive/
    archive_object_name = object_name.replace("landing/", "archive/", 1)
    
    storage_client = storage.Client()
    bucket = storage_client.bucket(bucket_name)
    source_blob = bucket.blob(object_name)

    logger.info(f"Moving {object_name} to {archive_object_name}")
    new_blob = bucket.copy_blob(source_blob, bucket, archive_object_name)
    source_blob.delete()
    logger.info("File successfully moved to archive.")
