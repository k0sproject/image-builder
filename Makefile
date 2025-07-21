
IMG_PATH ?= images/$(subst :,/,$(IMG))

.PHONY: build-%

build-%: IMG ?= $(subst build-,,$@)
build-%:
	docker build -t $(IMG) -f $(IMG_PATH)/Dockerfile $(IMG_PATH)

.PHONY: scan-%

scan-%: IMG ?= $(subst scan-,,$@)
scan-%:
	trivy image --ignore-unfixed --exit-code 42 $(IMG)
