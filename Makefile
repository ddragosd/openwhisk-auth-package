OAUTH_PACKAGE_NAME ?= oauth
CACHE_PACKAGE_NAME ?= cache
NAMESPACE ?= guest
CLIENT_ID ?= change-me
CLIENT_SECRET ?= change-me
SCOPES ?= ""
BASE_URL ?= https://runtime-preview.adobe.io
PROVIDER ?= change-me

.PHONY: create-oauth-package
create-oauth-package:
	wsk package get $(OAUTH_PACKAGE_NAME) --summary || wsk package create $(OAUTH_PACKAGE_NAME)
	wsk action update $(OAUTH_PACKAGE_NAME)/login ./node_modules/openwhisk-passport-auth/openwhisk-passport-auth-0.0.1.js

.PHONY: create-cache-package
create-cache-package:
	wsk package get $(CACHE_PACKAGE_NAME) --summary || wsk package create $(CACHE_PACKAGE_NAME)
	# TODO: redis should be auto-discovvered and updated when changes occur
	wsk action update $(CACHE_PACKAGE_NAME)/persist ./node_modules/openwhisk-cache-redis/openwhisk-cache-redis-0.0.1.js --param redis_host //10.0.2.159:6380
	wsk action update $(CACHE_PACKAGE_NAME)/encrypt ./action/encrypt.js

npm-install:
	npm install

.PHONY: install
install: npm-install create-oauth-package create-cache-package

uninstall:
	wsk action delete $(CACHE_PACKAGE_NAME)/persist
	wsk action delete $(CACHE_PACKAGE_NAME)/encrypt
	wsk package delete $(CACHE_PACKAGE_NAME)
	wsk action delete $(OAUTH_PACKAGE_NAME)/login
	wsk package delete $(OAUTH_PACKAGE_NAME)

.PHONY: adobe-oauth
adobe-oauth:
	(wsk package get adobe_oauth --summary && wsk package delete adobe_oauth) || echo "package is available"
	wsk package bind $(OAUTH_PACKAGE_NAME) adobe_oauth \
		--param auth_provider adobe-oauth2 --param auth_provider_name adobe \
		--param client_id $(CLIENT_ID) \
		--param client_secret $(CLIENT_SECRET) \
		--param scopes $(SCOPES) \
		--param callback_url $(BASE_URL)/api/v1/web/$(NAMESPACE)/adobe/authenticate.json
	wsk package get adobe --summary || wsk package create adobe
	wsk action update adobe/authenticate --sequence adobe_oauth/login,$(CACHE_PACKAGE_NAME)/encrypt,$(CACHE_PACKAGE_NAME)/persist	--web true
	echo "To Login Open: " $(BASE_URL)/api/v1/web/$(NAMESPACE)/adobe/authenticate
	echo "Make sure to configure the Redirect URL Pattern to " $(BASE_URL)/api/v1/web/$(NAMESPACE)/adobe/authenticate.json

.PHONY: oauth
oauth:
	(wsk package get $(PROVIDER)_oauth --summary && wsk package delete $(PROVIDER)_oauth) || echo "package is available"
	wsk package bind $(OAUTH_PACKAGE_NAME) $(PROVIDER)_oauth \
		--param auth_provider $(PROVIDER)  \
		--param client_id $(CLIENT_ID) \
		--param client_secret $(CLIENT_SECRET) \
		--param scopes $(SCOPES) \
		--param callback_url $(BASE_URL)/api/v1/web/$(NAMESPACE)/$(PROVIDER)/authenticate.json
	wsk package get $(PROVIDER) --summary || wsk package create $(PROVIDER)
	wsk action update $(PROVIDER)/authenticate --sequence $(PROVIDER)_oauth/login,$(CACHE_PACKAGE_NAME)/encrypt,$(CACHE_PACKAGE_NAME)/persist	--web true
	echo "To Login Open: " $(BASE_URL)/api/v1/web/$(NAMESPACE)/$(PROVIDER)/authenticate
	echo "Make sure to configure the Redirect URL Pattern to " $(BASE_URL)/api/v1/web/$(NAMESPACE)/$(PROVIDER)/authenticate.json

.PHONY: examples-fb
examples-fb: oauth
	wsk action update facebook/webhook ./examples/fb/generic_event_handler.js \
		--param verify_token openwhisk \
		--web true
	wsk action update facebook/photos_update_handler ./examples/fb/photos_update_handler.js
	wsk action update facebook/subscribe ./examples/fb/register_fb_webhook.js \
			--param client_id $(CLIENT_ID) \
			--param client_secret $(CLIENT_SECRET) \
			--param verify_token openwhisk \
			--param webhook_url $(BASE_URL)/api/v1/web/$(NAMESPACE)/$(PROVIDER)/webhook
	# subscribe to facebook webhooks
	wsk action invoke facebook/subscribe --blocking --result
	wsk trigger update facebook_photos_update
	wsk rule update facebook_photos_update_rule facebook_photos_update facebook/photos_update_handler
	wsk rule enable facebook_photos_update_rule


.PHONY: other
other:
	echo "TBD"

	#wsk action update oauth/github_com --sequence oauth/github,cache/encrypt,cache/redis --web true

	#wsk action update oauth/adobe_com --sequence oauth/adobe,cache/encrypt,cache/redis --web true

	# previously the oauth/github action has been created with:
	# wsk action update oauth/github ./openwhisk-passport-auth-0.0.1.js --param auth_provider github --param client_id XXXXXXX --param client_secret XXXXX --param callback_url https://runtime-preview.adobe.io/api/v1/web/guest/oauth/github_com.json

	# oauth/adobe action can be created with:
	# wsk action update oauth/adobe ./openwhisk-passport-auth-0.0.1.js --param auth_provider adobe-oauth2 --param auth_provider_name adobe --param client_id XXXXX --param client_secret XXXXXX --param scopes openid,AdobeID --param callback_url https://runtime-preview.adobe.io/api/v1/web/guest/oauth/adobe_com.json
	# wsk action update oauth/adobe_com --sequence oauth/adobe,cache/encrypt,cache/redis --web true

	# cache/redis has been created with:
	# wsk action create cache/redis ./openwhisk-cache-redis-0.0.1.js --param redis_host //10.0.2.159:6380

	#to login, open https://runtime-preview.adobe.io/api/v1/web/guest/oauth/github_com

	# after login check that the info is persisted in the cache:
	# wsk action invoke cache/redis --result --blocking --param key 541933
