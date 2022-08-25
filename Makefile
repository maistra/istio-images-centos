FINDFILES=find . \( -path ./.git -o -path ./.github -o -path ./tmp -o -path ./vendor \) -prune -o -type f
XARGS = xargs -0 -r

################################################################################
# linting
################################################################################
.PHONY: lint-scripts
lint-scripts:
	@${FINDFILES} -name '*.sh' -print0 | ${XARGS} shellcheck

.PHONY: lint
lint: lint-scripts