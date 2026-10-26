# Data flow and privacy

This document describes the sample's technical data flow. It is not a privacy
statement for an application built from the sample. Resource owners are
responsible for evaluating their deployment, notices, retention settings, and
applicable requirements.

## Chat requests

1. The browser keeps the current conversation in memory.
2. On submit, the browser sends that conversation to `/chat/stream` on the
   deployed App Service app.
3. The Quart backend authenticates to the configured Azure OpenAI endpoint
   with managed identity in Azure or Azure Developer CLI credentials locally.
4. The backend sends the conversation to the Azure OpenAI Responses API with
   `store=false`.
5. The backend streams response events to the browser as newline-delimited
   JSON. The browser renders the response in the page.

The sample does not write chat content to a database or file. Resource owners
should review Azure OpenAI data, privacy, and abuse-monitoring documentation
for the service and region they use.

## Logging and telemetry

The source logs application warnings and request failures through the standard
Python and App Service logging paths. It does not add an Application Insights
SDK, analytics SDK, tracking pixel, or custom telemetry pipeline.

Azure platform logs are controlled by the resource owner's Azure
configuration. The included App Service Bicep enables short-lived file-system
HTTP logs and failed-request tracing. It does not enable Application Insights.
Do not log prompts, responses, credentials, access tokens, or customer data
when extending this sample.

## Browser dependencies

The page downloads Bootstrap, Bootstrap Icons, Bootswatch, Showdown, and
ndjson-readablestream from `cdn.jsdelivr.net`. Those requests disclose normal
web request metadata, including the client's IP address and user agent, to the
CDN operator. Host reviewed copies of these assets yourself if that external
request does not fit your deployment requirements.

## Credentials

The browser never receives Azure credentials. The backend requests a Microsoft
Entra token for `https://cognitiveservices.azure.com/.default` and passes it
to the Azure OpenAI client. `.env`, `.azure`, and local virtual environments
are excluded from version control.
