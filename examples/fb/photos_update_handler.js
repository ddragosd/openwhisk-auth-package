/**
 * This action listens to facebook_photos_update trigger.
 * It expects an input object like the one bellow:
 * {
 *   "changes": {
 *      "field": "photos",
 *      "value": {
 *        "object_id": "106973483255900",
 *        "verb": "update"
 *      }
 *   },
 *   user_id: 11111111
 * }
 */
function main(params) {
  const rp = require('request-promise');
  return new Promise(
    (resolve, reject) => {
      let photo_id = params.changes.value.object_id
      let user_id = params.user_id
      let verb = params.changes.value.verb
      let user_info = {
        getToken: _getUserToken
      }

      console.log("Handling photo event:" + verb);

      switch (verb) {
        case "update":
          console.log("Getting user info for user:" + user_id);

          user_info.getToken(user_id) // obtain user's token
            .then((info) => {
              console.log("Successfully obtained userToken.");
              // GET /v2.8/${photo_id}?access_token=<TBD>&debug=all&fields=images%2Cheight&format=json&method=get&pretty=0&suppress_http_code=1
              // Host: graph.facebook.com
              var options = {
                method: 'GET',
                uri: 'https://graph.facebook.com/v2.9/' + photo_id,
                qs: {
                  fields: "images",
                  format: "json",
                  access_token: info.token,
                  pretty: 0,
                  suppress_http_code: 1
                },
                json: true
              }

              rp(options)
                .then(images => {
                  resolve(images);
                })
                .catch(err => {
                  reject({
                    error: "could not get user images",
                    details: err
                  })
                });
            })
            .catch(err => {
              reject({
                error: "could not get user info",
                details: err.toString()
              })
            });
          break;
        default:
          reject({
            error: "unknown_error",
            event: params
          })
          break;
      }
    }
  );
}

function _getUserDetails(user_id, fields) {
  let caching_action = "cache/persist";
  console.log("_getUserDetails(" + user_id, "," + fields + ")");

  return new Promise(
    (resolve, reject) => {
      const openwhisk = require('openwhisk');
      let openwhisk_client = openwhisk({
        api: process.env['__OW_API_HOST'] + "/api/v1/"
      });

      openwhisk_client.actions.invoke({
        actionName: caching_action,
        blocking: true,
        result: true,
        params: {
          key: user_id,
          fields: fields
        }
      }).then(result => {
        console.log("Got User info.");
        resolve(result.response.result.value);
      }).catch(err => {
        console.log(process.env);
        console.log("Could not get user details.");
        console.error(err);
        console.error("Could not invoke caching action: " + caching_action);
        reject(err);
      })
    }
  )
}

function _getUserToken(user_id) {
  return _getUserDetails(user_id, "token");
}

function _getUserRefreshToken(user_id) {
  return _getUserDetails(user_id, "refreshToken");
}

function _getUserProfile(user_id) {
  return _getUserDetails(user_id, "profile");
}
