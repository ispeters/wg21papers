# Shared entry point for every paper's Makefile, which should contain just:
#
#     include ../wg21.mk
#
# Before including mpark/wg21's Makefile, link the dev shell's Nix-provided
# pandoc and Python into mpark/wg21's deps/ directory (a no-op when the links
# are already current). Without the links, mpark/wg21 runs its own installers,
# which don't work inside the shell; doing it here means `make clean` (which
# deletes deps/) followed by `make` just works.

WG21_ROOT := $(patsubst %/,%,$(dir $(lastword $(MAKEFILE_LIST))))

ifeq ($(shell command -v wg21-link-deps),)
  $(error wg21-link-deps not found: enter the dev shell first with 'devshell .')
endif

$(shell wg21-link-deps --if-needed $(WG21_ROOT)/mpark.wg21 >&2)
ifneq ($(.SHELLSTATUS),0)
  $(error wg21-link-deps failed; see the message above)
endif

include $(WG21_ROOT)/mpark.wg21/Makefile
