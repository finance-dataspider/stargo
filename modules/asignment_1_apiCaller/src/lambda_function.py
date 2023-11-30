import json
import re
import os
import urllib3

from urllib.parse import urlparse, urlencode, parse_qs

from botocore.vendored import requests
from boto3 import Session
from botocore.auth import SigV4Auth
from botocore.awsrequest import AWSRequest

def signing_headers(method, url_string, body, api_key):
    region = re.search("execute-api.(.*).amazonaws.com", url_string).group(1)
    url = urlparse(url_string)
    path = url.path or '/'
    querystring = '?' + urlencode(parse_qs(url.query, keep_blank_values=True), doseq=True) if url.query else ''

    safe_url = url.scheme + '://' + url.netloc.split(':')[0] + path + querystring
    request = AWSRequest(method=method.upper(), url=safe_url, data=body)
    SigV4Auth(Session().get_credentials(), "execute-api", region).add_auth(request)

    # Add x-api-key header
    request.headers['x-api-key'] = api_key

    return dict(request.headers.items())

def lambda_handler(event, context):
    try:
        method = "GET"
        url =  os.environ.get("API_URL")
        # Retrieve API Key from environment variables
        api_key = os.environ.get("API_KEY")

        if not api_key:
            return {
                'statusCode': 500,
                'body': 'Internal Server Error: Missing API Key'
            }
        body = ""

        headers = signing_headers(method, url, body, api_key)

        http = urllib3.PoolManager()

        if method.upper() == 'GET':
            response = http.request('GET', url, headers=headers)
            print(response.data)
        else:
            raise ValueError(f"Unsupported HTTP method: {method}")

        response_data = json.loads(response.data.decode('utf-8'))  # Assuming the response is in JSON format

        return {
            'statusCode': response.status,
        }
    except Exception as e:
        return {
            'statusCode': 500,
            'body': f'Internal Server Error: {str(e)}'
        }
