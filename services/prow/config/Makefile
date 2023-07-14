PROW_NAMESPACE ?= prow
JOB_NAMESPACE ?= test-pods

update-config:
	kubectl -n ${PROW_NAMESPACE} create configmap config --from-file=config.yaml=config.yml --dry-run=client -o yaml | kubectl replace configmap config -f -

update-plugins:
	kubectl -n ${PROW_NAMESPACE} create configmap plugins --from-file=plugins.yaml=plugins.yml --dry-run=client -o yaml | kubectl replace configmap plugins -f -

.PHONY: update-config update-plugins
