// Checks self/message.hpp: a derived message sends its own type, and the
// sent copy runs.
#include "message.hpp"

#include <concepts>

struct urgent_message : message {
  int priority = 0;
};

static_assert(std::same_as<decltype(urgent_message{}.send()),
                           exec::function<ex::sender_tag(urgent_message), sent>>);

void send_urgently(urgent_message const& m) { ex::sync_wait(m.send()); }
