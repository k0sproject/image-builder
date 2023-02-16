IMAGE_REPO = quay.io/k0sproject
build:
	docker build --no-cache -t $(IMAGE_NAME) .

scan:
	docker run --rm -v /var/run/docker.sock:/var/run/docker.sock aquasec/trivy image --ignore-unfixed $(IMAGE_NAME)