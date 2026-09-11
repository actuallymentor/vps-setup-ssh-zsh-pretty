.PHONY: test verify

test:
	shellcheck *.sh tests/*.sh
	@for file in *.sh tests/*.sh; do bash -n "$$file" || exit; done
	bash tests/preflight.sh

# Run on the configured VPS; SSH_PORT/FIREWALL/NONROOT_USERNAME select assertions.
verify:
	bash tests/verify.sh
