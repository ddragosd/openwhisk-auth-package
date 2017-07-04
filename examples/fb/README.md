## Handling Facebook events

This example shows how to listen to Facebook events, like when the user has added an image, or was tagged in one, and invoke an action as a result. The key for this workflow is to register the webhook correctly with facebook, and then retrieve the user's token in order to access the uploaded images. For getting user's access token, the user needs to go through the login process, in order to give the application access to photos.

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

Authenticate in Facebook using the action configured during setup, step 1. Open:  `https://<openwhisk_host>/api/v1/web/<namespace>/facebook/authenticate` .

Then add a new image in Facebook.

Next, check the result of the webhook in OpenWhisk:

```bash
$ wsk activation list --limit 5
```

If everything is working normally, you should see something similar to the activations bellow:

```bash
activations
444 photos_update_handler
333 facebook_photos_update_rule
222 facebook_photos_update
111 webhook
```

The `webhook` defined by the `generic_event_handler.js` action was invoked first. It then fired the `facebook_photos_update` trigger, which invoked `photos_update_handler` action (`photos_update_handler.js`) through the `facebook_photos_update_rule` rule.

This rule was enabled by executing:

```bash
$ wsk trigger update facebook_photos_update
$ wsk rule update facebook_photos_update_rule facebook_photos_update facebook/photos_update_handler
$ wsk rule enable facebook_photos_update_rule
```

`facebook/photos_update_handler` is the action created from `photos_update_handler.js`:

```bash
$ wsk action update facebook/photos_update_handler ./examples/fb/photos_update_handler.js
```


Finally, let's check that the user's images are accessed correctly. The `photos_update_handler` action outputs direct links to those images.

```bash
$ wsk activation get 444 --summary
activation result for /guest/photos_update_handler (success at 2017-06-23 03:37:03 -0700 PDT)
{
    "id": "1015xxxxxx",
    "images": [
        {
            "height": 544,
            "source": "https://scontent.xx.fbcdn.net/v/59E3C963",
            "width": 1266
        }]
}
```

From this point on, we can build a sequence that takes this images from FB and does something with them; it could sync them into another photo storage solution, apply some filters, or do anything else. The sky is the limit.

#### Troubleshooting
If the incoming event from Facebook doesn't include the changed values, follow the steps in https://developers.facebook.com/docs/graph-api/webhooks#subscribing and go to the `App Dashboard` -> `Products` -> `Webhooks` -> `Edit subscription`, and make sure the `Include Values` says `YES`.
