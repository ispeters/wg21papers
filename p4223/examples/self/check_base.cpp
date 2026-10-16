// Checks self/base.hpp: every form connects and runs, on a base and on a
// derived object.
#include "base.hpp"

void run_each_form(derived& d) {
  ex::sync_wait(d.borrowed());
  ex::sync_wait(d.copied());
  ex::sync_wait(d.copied_as_self());
  ex::sync_wait(d.forwarded());
  ex::sync_wait(derived().forwarded());
  ex::sync_wait(base().copied_as_self());
}
