.PHONY: install
install:
	wsk package get cache --summary || wsk package create cache
	wsk action update cache/encrypt ./action/encrypt.js
	# create sequence
	wsk package get oauth --summary || wsk package create oauth
	wsk action update oauth/github_com --sequence oauth/github,cache/encrypt,cache/redis --web true

	# previously the oauth/github action has been created with:
	# wsk action update oauth/github ./openwhisk-passport-auth-0.0.1.js --param auth_provider github --param client_id XXXXXXX --param client_secret XXXXX --param callback_url https://runtime-preview.adobe.io/api/v1/web/guest/oauth/github_com.json

	# cache/redis has been created with:
	# wsk action create cache/redis ./openwhisk-cache-redis-0.0.1.js --param redis_host //10.0.2.159:6380

	#to login, open https://runtime-preview.adobe.io/api/v1/web/guest/oauth/github_com

	# after login check that the info is persisted in the cache:
	# wsk action invoke cache/redis --result --blocking --param key 541933
