## OAuth2 Client Credentials Flow

Currently, there is no way to create an application in Okta's admin console
suitable for use with the `grant_type=client_credentials`.

This will be changing very soon.

In the meantime, you can use the `client_creds.sh` script to get things setup
right in your tenant.

## Usage

./client_creds.sh -t <Okta API Token> -o <Okta tenant - ex: micah.okta.com>

## Under the covers

The script does the following:

* Create an Application with application_type=service
* Create an Authorization Server
* Create a default scope named `service` for the authorization server
* Create a default policy for the authorization server
* Create a default rule for the authorization server allowing for Client Credentials
