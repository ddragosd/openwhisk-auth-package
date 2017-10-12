OAUTH_PACKAGE_NAME ?= oauth
CACHE_PACKAGE_NAME ?= cache
NAMESPACE ?= $(shell wsk -i namespace list | grep -v namespaces)
CLIENT_ID ?= change-me
CLIENT_SECRET ?= change-me
SCOPES ?= ""
BASE_URL ?= https://localhost
PROVIDER ?= change-me

.PHONY: create-oauth-package
create-oauth-package:
	wsk -i package get $(OAUTH_PACKAGE_NAME) --summary || wsk -i package create $(OAUTH_PACKAGE_NAME)
	wsk -i action update $(OAUTH_PACKAGE_NAME)/login ./node_modules/openwhisk-passport-auth/openwhisk-passport-auth-0.0.1.js
	wsk -i action update $(OAUTH_PACKAGE_NAME)/success ./node_modules/openwhisk-passport-auth/src/action/redirect.js --main redirect

.PHONY: create-cache-package
create-cache-package:
	wsk -i package get $(CACHE_PACKAGE_NAME) --summary || wsk -i package create $(CACHE_PACKAGE_NAME)
	# TODO: redis should be auto-discovvered and updated when changes occur
	wsk -i action update $(CACHE_PACKAGE_NAME)/persist ./node_modules/openwhisk-cache-redis/openwhisk-cache-redis-0.0.6.js --param redis_host //10.32.73.111:6379
	wsk -i action update $(CACHE_PACKAGE_NAME)/encrypt ./action/encrypt.js

npm-install:
	npm install

.PHONY: install
install: npm-install create-oauth-package create-cache-package

uninstall:
	wsk -i action delete $(CACHE_PACKAGE_NAME)/persist
	wsk -i action delete $(CACHE_PACKAGE_NAME)/encrypt
	wsk -i package delete $(CACHE_PACKAGE_NAME)
	wsk -i action delete $(OAUTH_PACKAGE_NAME)/login
	wsk -i action delete $(OAUTH_PACKAGE_NAME)/success
	wsk -i package delete $(OAUTH_PACKAGE_NAME)

.PHONY: adobe-oauth
adobe-oauth:
	(wsk -i package get adobe_oauth --summary && wsk -i package delete adobe_oauth) || echo "package is available"
	wsk -i package bind $(OAUTH_PACKAGE_NAME) adobe_oauth \
		--param auth_provider adobe-oauth2 --param auth_provider_name adobe \
		--param client_id $(CLIENT_ID) \
		--param client_secret $(CLIENT_SECRET) \
		--param scopes $(SCOPES) \
		--param callback_url $(BASE_URL)/api/v1/web/$(NAMESPACE)/adobe/authenticate \
		--param redirect_url https://adobe.com
	wsk -i package get adobe --summary || wsk -i package create adobe
	wsk -i action update adobe/authenticate --sequence adobe_oauth/login,$(CACHE_PACKAGE_NAME)/encrypt,$(CACHE_PACKAGE_NAME)/persist,$(OAUTH_PACKAGE_NAME)/success	--web true
	echo "To Login Open: " $(BASE_URL)/api/v1/web/$(NAMESPACE)/adobe/authenticate
	echo "Make sure to configure the Redirect URL Pattern to " $(BASE_URL)/api/v1/web/$(NAMESPACE)/adobe/authenticate

.PHONY: oauth
oauth:
	(wsk -i package get $(PROVIDER)_oauth --summary && wsk -i package delete $(PROVIDER)_oauth) || echo "package is available"
	wsk -i package bind $(OAUTH_PACKAGE_NAME) $(PROVIDER)_oauth \
		--param auth_provider $(PROVIDER)  \
		--param client_id $(CLIENT_ID) \
		--param client_secret $(CLIENT_SECRET) \
		--param scopes $(SCOPES) \
		--param callback_url $(BASE_URL)/api/v1/web/$(NAMESPACE)/$(PROVIDER)/authenticate \
		--param redirect_url https://facebook.com
	wsk -i package get $(PROVIDER) --summary || wsk -i package create $(PROVIDER)
	wsk -i action update $(PROVIDER)/authenticate --sequence $(PROVIDER)_oauth/login,$(CACHE_PACKAGE_NAME)/encrypt,$(CACHE_PACKAGE_NAME)/persist,$(OAUTH_PACKAGE_NAME)/success	--web true
	echo "To Login Open: " $(BASE_URL)/api/v1/web/$(NAMESPACE)/$(PROVIDER)/authenticate
	echo "Make sure to configure the Redirect URL Pattern to " $(BASE_URL)/api/v1/web/$(NAMESPACE)/$(PROVIDER)/authenticate.json

.PHONY: examples-fb
examples-fb: oauth
	wsk -i action update facebook/webhook ./examples/fb/generic_event_handler.js \
		--param verify_token openwhisk \
		--web true
	wsk -i action update facebook/photos_update_handler ./examples/fb/photos_update_handler.js
	wsk -i action update facebook/subscribe ./examples/fb/register_fb_webhook.js \
			--param client_id $(CLIENT_ID) \
			--param client_secret $(CLIENT_SECRET) \
			--param verify_token openwhisk \
			--param webhook_url $(BASE_URL)/api/v1/web/$(NAMESPACE)/$(PROVIDER)/webhook
	# subscribe to facebook webhooks
	wsk -i action invoke facebook/subscribe --blocking --result
	wsk -i trigger update facebook_photos_update
	wsk -i rule update facebook_photos_update_rule facebook_photos_update facebook/photos_update_handler
	wsk -i rule enable facebook_photos_update_rule

.PHONY: other
other:
	echo "TBD"
