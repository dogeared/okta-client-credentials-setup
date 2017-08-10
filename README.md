## OAuth2 Client Credentials Flow

There are a number of steps to create an environment in Okta suitable to use the
OAuth2 Client Credentials flow. There's no one button or one place to set it up
in the admin console.

You can use the `client_creds.sh` script to get things setup right in your
tenant.

## Usage

```
./client_creds.sh -t <Okta API Token> -o <Okta tenant - ex: micah.okta.com>
```

## Under the covers

The script does the following:

* Create an Application with application_type=service
* Create an Authorization Server
* Create a default scope named `service` for the authorization server
* Create a default policy for the authorization server
* Create a default rule for the authorization server allowing for Client Credentials
