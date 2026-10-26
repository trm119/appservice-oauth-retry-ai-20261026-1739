# Deploy with existing resources

You can deploy the application to an existing Linux App Service app or use
Azure Developer CLI with an existing Azure OpenAI resource.

## Existing App Service app

Configure the App Service app with:

* Python 3.12 on Linux.
* A system-assigned managed identity, or a user-assigned managed identity with
  its client ID in `AZURE_CLIENT_ID`.
* The `Cognitive Services OpenAI User` role on the target Azure OpenAI
  resource.
* `AZURE_OPENAI_ENDPOINT` and `AZURE_OPENAI_CHAT_DEPLOYMENT` app settings.
* `RUNNING_IN_PRODUCTION=true`.
* Startup command `gunicorn --config gunicorn.conf.py app:app`.

Deploy the repository root with an App Service source deployment method that
runs Oryx or otherwise installs `requirements.txt`.

## Azure Developer CLI with existing Azure OpenAI

Set these environment values before `azd up`:

```shell
azd env set CREATE_AZURE_OPENAI false
azd env set AZURE_OPENAI_RESOURCE <resource-name>
azd env set AZURE_OPENAI_RESOURCE_GROUP <resource-group-name>
azd env set AZURE_OPENAI_ENDPOINT https://<resource-name>.openai.azure.com/
azd env set AZURE_OPENAI_CHAT_DEPLOYMENT <deployment-name>
```

The deployment identity must have permission to create a role assignment on
the Azure OpenAI resource. Set `CREATE_ROLE_FOR_USER=false` if the current user
does not need an additional `Cognitive Services OpenAI User` assignment.

The Bicep model values are unused when `CREATE_AZURE_OPENAI=false`, but the
parameter file still supplies defaults so the template remains valid.
