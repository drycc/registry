check-podman:
	@if [ -z $$(which podman) ]; then \
		echo "Missing \`podman\` client which is required for development"; \
		exit 2; \
	fi

check-kubectl:
	@if [ -z $$(which kubectl) ]; then \
		echo "Missing \`kubectl\` client which is required for development"; \
		exit 2; \
	fi
