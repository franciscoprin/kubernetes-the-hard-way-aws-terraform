run:
	docker build \
		--build-arg HOST_GROUP_ID=$$(id -g) \
		--build-arg HOST_USER_ID=$$(id -u) \
		--build-arg HOST_USER_NAME=dockeruser \
		-t infra-prin .
	docker run \
		--rm -it \
		-v "$$HOME:/home/dockeruser" \
		-w="/home/dockeruser$${PWD#"$$HOME"}" \
		infra-prin
