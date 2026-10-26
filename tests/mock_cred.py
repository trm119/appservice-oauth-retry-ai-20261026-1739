# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

import azure.core.credentials_async


class MockAzureCredential(azure.core.credentials_async.AsyncTokenCredential):
    pass
