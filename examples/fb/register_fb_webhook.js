/**
* Registers a new webhook with Facebook.
* See: https://developers.facebook.com/docs/graph-api/webhooks/#subscribefields
* https://developers.facebook.com/docs/graph-api/reference/v2.9/app/subscriptions
* @param params
*         {
            "client_id": <fb_client_id>,
            "client_secret": <fb_client_secret>,
            "webhook_url" : <url_to_webhook>,
            "verify_token": <a_verification_token>
          }
* @return a Promise which succeedes when the webhook is registers
*/
function main(params) {
  const request = require('request');
  const rp = require('request-promise');

  return new Promise(
    (resolve, reject) => {
      // POST /v2.9/{params.client_id}/subscriptions HTTP/1.1
      // Host: graph.facebook.com
      // object=user&callback_url={params.webhook_url}&verify_token={params.verify_token}
      var options = {
        method: 'POST',
        uri: 'https://graph.facebook.com/v2.9/' + params.client_id + '/subscriptions',
        form: {
          object: 'user',
          fields: 'photos,pic,picture,statuses',
          callback_url: params.webhook_url,
          verify_token: params.verify_token,
          access_token: params.client_id + '|' + params.client_secret
        },
        headers: {
          /* 'content-type': 'application/x-www-form-urlencoded' */ // Is set automatically,
        }
      };

      rp(options)
        .then(body => {
          resolve({
            success: true,
            body: body
          });
        })
        .catch(err => {
          reject({
            error: "could not subscribe",
            details: err
          })
        });
    }
  )
}
