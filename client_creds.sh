#! /bin/bash

get_json_for_client()
{
cat <<EOF
{
  "client_name": "$OKTA_TENANT - ClientCreds",
  "redirect_uris": [ "https://example.com" ],
  "response_types": [ "token" ],
  "grant_types": [ "implicit", "client_credentials" ],
  "token_endpoint_auth_method": "client_secret_basic",
  "application_type": "service"
}
EOF
}

get_json_for_authorization_server()
{
cat <<EOF
{
  "audiences": [ "https://example.com" ],
  "defaultResourceUri": "https://example.com",
  "description": "$OKTA_TENANT - AuthServer",
  "name": "$OKTA_TENANT - AuthServer"
}
EOF
}

get_json_for_default_scope()
{
cat <<EOF
{
  "description": "service",
  "name": "service",
  "default": true
}
EOF
}

get_json_for_policy()
{
cat <<EOF
{
  "type": "OAUTH_AUTHORIZATION_POLICY",
  "status": "ACTIVE",
  "name": "Default Policy",
  "description": "Default Policy",
  "priority": 1,
  "conditions": {
    "clients": {
      "include": [ "ALL_CLIENTS" ]
    }
  }
}
EOF
}

get_json_for_rule()
{
cat <<EOF
{
  "type": "RESOURCE_ACCESS",
  "system": false,
  "name": "Default",
  "conditions": {
    "people": {
      "users": {
        "include": [],
        "exclude": []
      },
      "groups": {
        "include": [ "EVERYONE" ],
        "exclude": []
      }
    },
    "grantTypes": {
      "include": [ "client_credentials" ]
    },
    "scopes": { "include": [ "*" ] }
  },
  "actions": {
    "token": {
      "accessTokenLifetimeMinutes": 60,
      "refreshTokenLifetimeMinutes": 0,
      "refreshTokenWindowMinutes": 10080
    }
  }
}
EOF
}

usage()
{
  echo "$0 -t <API TOKEN> -o <OKTA TENANT HOST - ex: micah.okta.com>"
}

args=`getopt t:o:n: $*` ; errcode=$?; set -- $args

while true ; do
  case "$1" in
    -t)
      case "$2" in
        "") shift 2 ;;
        *) TOKEN=$2 ; shift 2 ;;
      esac ;;
    -o)
      case "$2" in
        "") shift 2 ;;
        *) OKTA_TENANT=$2 ; shift 2 ;;
      esac ;;
    --) shift ; break ;;
    *) echo "Internal error!" ; exit 1 ;;
  esac
done

## make sure TOKEN, OKTA_TENANT are set
if [ -z "$TOKEN" ];
then
  echo "ERROR: api token not set"
  echo $(usage)
  exit 1
fi

if [ -z "$OKTA_TENANT" ];
then
  echo "ERROR: okta tenant not set"
  echo $(usage)
  exit 1
fi

## make sure that jq is installed

command -v jq >/dev/null 2>&1 || { echo >&2 "The jq utility is required. On mac, do: 'brew install jq'. Aborting."; exit 1; }

echo "## Create Client"

create_client_response=$(curl -s \
-H "Content-Type: application/json" \
-H "Authorization: SSWS $TOKEN" \
-X POST \
-d "$(get_json_for_client)" \
https://$OKTA_TENANT/oauth2/v1/clients)

client_id=`echo "$create_client_response" | jq -r '.client_id'`
client_secret=`echo "$create_client_response" | jq -r '.client_secret'`

echo "## Create Authorization Server"

create_auth_server_response=$(curl -s \
-H "Content-Type: application/json" \
-H "Authorization: SSWS $TOKEN" \
-X POST \
-d "$(get_json_for_authorization_server)" \
https://$OKTA_TENANT/api/v1/authorizationServers)

authorization_server_id=`echo "$create_auth_server_response" | jq -r '.id'`

echo "## Create Default Scope"

create_default_scope_response=$(curl -s \
-H "Content-Type: application/json" \
-H "Authorization: SSWS $TOKEN" \
-X POST \
-d "$(get_json_for_default_scope)" \
https://$OKTA_TENANT/api/v1/authorizationServers/$authorization_server_id/scopes)

echo "## Create Policy"

create_policy_response=$(curl -s \
-H "Content-Type: application/json" \
-H "Authorization: SSWS $TOKEN" \
-X POST \
-d "$(get_json_for_policy)" \
https://$OKTA_TENANT/api/v1/authorizationServers/$authorization_server_id/policies)

policy_id=`echo "$create_policy_response" | jq -r '.id'`

echo "## Create Rule"

create_rule_response=$(curl -s \
-H "Content-Type: application/json" \
-H "Authorization: SSWS $TOKEN" \
-X POST \
-d "$(get_json_for_rule)" \
https://$OKTA_TENANT/api/v1/authorizationServers/$authorization_server_id/policies/$policy_id/rules)

echo "## All Set!"
echo
echo "Now, you can use the Client Credentials flow:"
echo "curl -u $client_id:$client_secret -d 'grant_type=client_credentials' https://$OKTA_TENANT/oauth2/$authorization_server_id/v1/token"
