all:
	ct -in-file container-linux.yaml -platform azure -pretty > ignition.json

.PHONY: all
