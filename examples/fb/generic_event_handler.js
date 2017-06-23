/**
 * This event handler acts as an event router.
 * It receives events from Facebook and fires openwhisk triggers
 * which may be handled by other actions.
 *
 */

/**
 * sample event:
 * "entry": [
 *            {
 *                "changes": [
 *                    {
 *                        "field": "photos",
 *                        "value": {
 *                            "object_id": "106973483255900",
 *                            "verb": "update"
 *                        }
 *                    }
 *                ],
 *                changed_fields: [ 'photos' ],
 *                "id": "106971436589438",
 *                "time": 1498028278,
 *                "uid": "106971436589438"
 *            }
 *        ],
 *        "object": "user"
 *    },
 */

function _trigger(trigger_name, trigger_params, openwhisk_client) {
  return new Promise(
    (resolve, reject) => {
      console.log("Triggering " + trigger_name);
      openwhisk_client.triggers.invoke({
          triggerName: trigger_name,
          params: trigger_params
        })
        .then(result => {
          console.log('Trigger ' + trigger_name + ' fired!');
          resolve(result);
        }).catch(err => {
          console.error('Failed to fire trigger:' + trigger_name, err)
          reject(err);
        });
    }
  )
}

function main(params) {
  let verify_token = params.verify_token || "token";
  if (params["hub.mode"] == "subscribe" && params["hub.verify_token"] == verify_token) {
    // this request is just a verification request from Facebook
    return {
      headers: {
        'Content-Type': 'text/html'
      },
      body: params["hub.challenge"],
      statusCode: 200
    };
  };

  return new Promise(
    (resolve, reject) => {
      const openwhisk = require('openwhisk');

      try {
        let openwhisk_client = openwhisk({
          api: process.env['__OW_API_HOST'] + "/api/v1/"
        });
        let triggers = []; // a list of Promises to execute
        // facebook events may come in batches
        let entry = params.entry;
        console.log("Processing " + entry.length + " entries.");
        for (var i = 0; i < entry.length; i++) {
          console.log(entry[i]);
          let user_id = entry[i].id;
          let changes = entry[i].changes;
          console.log("Processing " + changes.length + " changes.");
          for (var j = 0; j < changes.length; j++) {
            let event_field = entry[i].changes[j].field;
            let event_verb = entry[i].changes[j].value.verb;
            let trigger_name = "facebook_" + event_field + "_" + event_verb;
            let trigger_params = {
              user_id: user_id,
              changes: changes[j]
            }
            //fire trigger_name (i.e. facebook_photos_update)
            triggers.push(_trigger(trigger_name, trigger_params, openwhisk_client));
          }
        }

        Promise.all(triggers)
          .then((result) => {
            resolve({
              headers: {
                'Content-Type': 'application/json'
              },
              body: {
                "event": params
              },
              statusCode: 200
            });
          })
          .catch( (err) => {
            console.error(err);
            console.log(process.env);
            reject({
              headers: {
                'Content-Type': 'application/json'
              },
              body: {
                "error": err.toString(),
                "event": params
              },
              statusCode: 200
            });
          });

      } catch (err) {
        console.err(err);
        console.log(process.env);
        reject({
          headers: {
            'Content-Type': 'application/json'
          },
          body: {
            "error": err.toString(),
            "event": params
          },
          statusCode: 200
        });
      }
    }
  );

}
