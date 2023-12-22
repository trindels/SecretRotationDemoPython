import logging
import json
from datetime import datetime, timedelta, UTC
import uuid

import azure.functions as func

from azure.identity import DefaultAzureCredential

from msgraph import GraphServiceClient
from msgraph.generated.models.password_credential import PasswordCredential
from msgraph.generated.applications.item.add_password.add_password_post_request_body import AddPasswordPostRequestBody
from msgraph.generated.applications.item.remove_password.remove_password_post_request_body import RemovePasswordPostRequestBody

from azure.keyvault.secrets import SecretClient

app = func.FunctionApp(http_auth_level=func.AuthLevel.ANONYMOUS)

@app.route(route="HttpTrigger1")
async def HttpTrigger1(req: func.HttpRequest) -> func.HttpResponse:
    logging.info('Python HTTP trigger function processed a request.')

    clientId = req.params.get('oid')
    if not clientId:
        return func.HttpResponse(f"No SP Object ID Provided.")

    try:
        # Get Credentials from Managed Identity Provider
        default_credential = DefaultAzureCredential()

        # Authenticate to MS Graph
        graph_client = GraphServiceClient( default_credential )

        # Get App Registration
        appReg = await graph_client.applications_with_app_id( clientId ).get()
        logging.info( appReg.display_name )

        # Get Current Time
        curDateTime = datetime.now(tz=UTC)

        # Delete Expired Secrets From Application
        appReg.password_credentials.sort(key=lambda x: x.end_date_time)
        if len(appReg.password_credentials) > 1:
            removePassPostReqeust = RemovePasswordPostRequestBody(
                key_id = appReg.password_credentials[0].key_id
            )
            await graph_client.applications.by_application_id( appReg.id ).remove_password.post( removePassPostReqeust )

        # Generate New Secret
        addPassPostRequest = AddPasswordPostRequestBody(
            password_credential = PasswordCredential(
                display_name = f"SecretRotationDemo",
                end_date_time = curDateTime.__add__(timedelta(hours=4))
            )
        )
        newAppPass = await graph_client.applications.by_application_id( appReg.id ).add_password.post(addPassPostRequest)

        # Authenticate to Key Vault Secret Client
        kv_url = "https://trrsecretrotationdemokv.vault.azure.net/"
        kv_client = SecretClient( vault_url=kv_url, credential=default_credential )

        # Save New Secret To Key Vault
        kv_client.set_secret(
            name=clientId,
            value=newAppPass.secret_text,
            expires_on=curDateTime.__add__(timedelta(hours=3))
        )



        text = f"Hello, {appReg.display_name}.  \n\nObject ID: {appReg.id}. \n\nApp ID: {appReg.app_id}.  \n\nOther: {appReg.password_credentials} \n\nNew App Pass: {newAppPass}"
        return func.HttpResponse(f"{addPassPostRequest}\n\n{text}")
    except ValueError:
        return func.HttpResponse(f"Value Error: {e}" )
    except Exception as e:
        return func.HttpResponse(f"Exception:  {e}")


@app.event_grid_trigger(arg_name="azeventgrid")
async def RotateSecret1(azeventgrid: func.EventGridEvent):
    logging.info('Python EventGrid trigger processed an event')

    result = json.dumps({
        'id': azeventgrid.id,
        'data': azeventgrid.get_json(),
        'topic': azeventgrid.topic,
        'subject': azeventgrid.subject,
        'event_type': azeventgrid.event_type,
    })

    logging.info('Python EventGrid trigger processed an event: %s', result)

    clientId = azeventgrid.get_json()['ObjectName']
    logging.info('Client Id: %s', clientId)

    try:
        # Get Credentials from Managed Identity Provider
        default_credential = DefaultAzureCredential()

        # Authenticate to MS Graph
        graph_client = GraphServiceClient( default_credential )

        # Get App Registration
        appReg = await graph_client.applications_with_app_id( clientId ).get()
        logging.info( appReg.display_name )

        # Get Current Time
        curDateTime = datetime.now(tz=UTC)

        # Delete Expired Secrets From Application
        appReg.password_credentials.sort(key=lambda x: x.end_date_time)
        if len(appReg.password_credentials) > 1:
            removePassPostReqeust = RemovePasswordPostRequestBody(
                key_id = appReg.password_credentials[0].key_id
            )
            await graph_client.applications.by_application_id( appReg.id ).remove_password.post( removePassPostReqeust )

        # Generate New Secret
        addPassPostRequest = AddPasswordPostRequestBody(
            password_credential = PasswordCredential(
                display_name = f"SecretRotationDemo",
                end_date_time = curDateTime.__add__(timedelta(hours=4))
            )
        )
        newAppPass = await graph_client.applications.by_application_id( appReg.id ).add_password.post(addPassPostRequest)

        # Authenticate to Key Vault Secret Client
        kv_url = "https://trrsecretrotationdemokv.vault.azure.net/"
        kv_client = SecretClient( vault_url=kv_url, credential=default_credential )

        # Save New Secret To Key Vault
        kv_client.set_secret(
            name=clientId,
            value=newAppPass.secret_text,
            expires_on=curDateTime.__add__(timedelta(hours=3))
        )

    except ValueError as e:
        logging.error('ValueError: %s', e)
    except Exception as e:
        logging.error('Exception: %s', e)
