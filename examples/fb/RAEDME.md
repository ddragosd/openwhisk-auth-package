## Handling Facebook events

This example shows how to listen to Facebook events, like when the user has added an image, or was tagged in one, and invoke an action as a result.

* `photos_update_handler.js` is the action handling the event when a new image is added.
* `generic_event_handler.js` is the action invoked by Facebook directly on each event that occurs. This action is an event router: it takes the incoming event from Facebook, and fires Openwhisk triggers, based on the type of changes.


### Setup

  ```bash
  $ cd ../../
  $ PROVIDER=facebook  CLIENT_ID=XX CLIENT_SECRET=BBB SCOPES=user_posts,user_photos make examples-fb
  ```
This command sets up the following actions in OpenWhisk:
1. First, it configures the authentication sequence for Facebook
2. It registers the `generic_event_handler.js` action as a Facebook webhook
3. It creates a trigger for `facebook_photos_update` event. This event is triggered from the `generic_event_handler` action.
4. It registers `photos_update_handler.js` action with the trigger.

### Testing

Authenticate in Facebook using the action configured during setup, step 1. Open:  `https://<openwhisk_host>/api/v1/web/guest/facebook/authenticate` .

Then add a new image in Facebook.

Next, check the result of the webhook in OpenWhisk:

```bash
$ wsk activation list --limit 5
```
