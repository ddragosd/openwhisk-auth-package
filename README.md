# experimental-auth-package
Openwhisk Package for setting up an authentication flow.
This package supports multiple authentication providers with OAuth2 implementations.

> STATUS: WORK IN PROGRESS

## Logging in Users using an Authentication Sequence

The goal is to create an authentication flow that is composed from a sequence of actions:

```
  login -> encrypt -> persist (SET) -> register_my_webhook (not implemented here) -> redirect (not implemented here)
```

* `login` - uses [experimental-openwhisk-passport-auth](https://git.corp.adobe.com/bladerunner/experimental-openwhisk-passport-auth) action.
* `encrypt` - uses [./action/encrypt.js](action/encrypt.js) to encrypt the Access Token, Refresh Token, and User Profile using Openwhisk Namespace API-KEY.
* `persist` - uses [experimental-openwhisk-cache-redis](https://git.corp.adobe.com/bladerunner/experimental-openwhisk-cache-redis). Other actions leveraging DynamoDB or another Azure storage could be used instead of Redis.

The user experience starts with the login action, which takes the end-user through the authentication UI of the corresponding provider. Once the login is successful the sequence executes all the actions, and at the end, the last action should redirect the user to a home page.

### Installing supporting actions

For a quick setup use:

```bash
$ make install
```

This command sets up 2 packages in a user's namespace( `system` in the example bellow ):

```bash
$ wsk package get oauth --summary
  package /system/oauth
   action /system/oauth/login

$ wsk package get cache --summary
  package /system/cache
   action /system/cache/encrypt
   action /system/cache/persist
```

* the `oauth` package contains the `login` action with no default parameters;
* the `cache` package contains the `encrypt` and `persist` actions

> NOTE: These packages could be publicly available from a `system` package,
so that other namespaces can reference/bind to them. This offers the flexibility to
maintain the supporting actions in a single place, vs having them copied and installed
in each namespace.

### Configuring Adobe as an authentication provider

```bash
$ CLIENT_ID=AAA CLIENT_SECRET=BBB SCOPES=a,b,c,d make adobe-oauth
```

This command uses `/system/oauth/login` to create a package binding,
configuring the credentials via default parameters. Then it creates the final action as a sequence ( `login -> encrypt -> persist`). To make for a nicer URI, the sequence action is placed in its own package so that it's presented to the end users as: `/api/v1/web/guest/adobe/authenticate`.

### Configuring GitHub as an authentication provider

```make
PROVIDER=github CLIENT_ID=XX CLIENT_SECRET=BBB make oauth
```

### Configuring Facebook as an authentication provider

```make
PROVIDER=facebook CLIENT_ID=XX CLIENT_SECRET=BBB SCOPES=user_posts,user_photos make oauth
```
#### End-to-end example
See [examples/fb](examples/fb/).

### Configuring Twitter as an authentication provider

```make
PROVIDER=twitter CLIENT_ID=XX CLIENT_SECRET=BBB make oauth
```

## Retrieving the persisted info

Use the same `persist` action used during authentication to retrieve the information. B/c the information is encrypted with Openwhisk Namespace API-KEY it can only be decrypted by actions within the same namespace. The API-KEY belonging to the namespace is injected by Openwhisk as an environment variable at invocation time.

```
persist (GET) -> decrypt
```
* `persist` is the same action used during Authentication
* `decrypt` - TBD.
