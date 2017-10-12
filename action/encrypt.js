var crypto = require('crypto');

/**
 * The entry point for this action.
 * It should be invoked once the authentication has succeeded.
 * @param params Input object
 * @returns {Promise}
 */
function main(params) {
  console.log(params);

  return new Promise((resolve, reject) => {

    // make sure the authentication succeeded
    if (params.body == null || typeof(params.body) == "undefined") {
      reject(params);
    }

    if (params.body.profile == null || typeof(params.body.profile) == "undefined") {
      reject(params);
    }

    console.log("params.body.profile.id=" + params.body.profile.id);
    // TODO: encrypt value
    // the response bellow should be sent to the persistence action
    resolve({
      // cache key is based on the User ID
      key: ":oauth:" + params.body.profile.id,
      value: {
        token: params.body.token,
        refresh_token: params.body.refreshToken,
        profile: params.body.profile._raw
      },
      context: params.body.context
    });
  });
}

function _link_accounts(identities) {
  var linked_ids = [];
  if (identities == null ) {
    return [];
  }
  // an array of key,value pairs used to persist the linked ids
  var identities_as_string = JSON.stringify(identities);
  for(var i=0; i< identities.length; i++ ) {
    linked_ids.push({
      key: ":oauth:" + identities[i].user_id,
      value: {
        linked_ids: identities_as_string
      }
    });
  }
  return linked_ids;
}

function test_web_action(params) {
  console.log(params);
  return {
    headers: { 'Content-Type': 'application/json' },
    statusCode: 200,
    body: new Buffer(JSON.stringify(params.__ow_headers)).toString('base64')
  }
}

exports.main=main;
exports.test_web_action=test_web_action;
