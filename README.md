# experimental-auth-package
Openwhisk Package for setting up an authentication flow in BladeRunner

> STATUS: WORK IN PROGRESS

## Logging in Users using an Authentication Sequence

To install it execute:

```bash
$ make install
```

The authentication flow is composed using a sequence of actions:

```
  login -> encrypt -> persist (SET)
```

* `login` - uses [experimental-openwhisk-passport-auth](https://git.corp.adobe.com/bladerunner/experimental-openwhisk-passport-auth) action.
* `encrypt` - uses [./action/encrypt.js](action/encrypt.js) to encrypt the Access Token, Refresh Token, and User Profile using Openwhisk Namespace API-KEY.
* `persist` - uses [experimental-openwhisk-cache-redis](https://git.corp.adobe.com/bladerunner/experimental-openwhisk-cache-redis). Other actions leveraging DynamoDB or another Azure storage could be used instead of Redis.

The end-user needs to be taken through the authentication UI of the corresponding provider.

## Retrieving the persisted info

Use the same `persist` action used during authentication to retrieve the information. B/c the information is encrypted with Openwhisk Namespace API-KEY it can only be decrypted by other actions belonging to the same namespace; there's no need to share the API-KEY with other actions. The API-KEY belonging to the namespace is injected by Openwhisk at invocation time.

```
persist (GET) -> decrypt
```
* `persist` is the same action used during Authentication
* `decrypt` - TBD.
