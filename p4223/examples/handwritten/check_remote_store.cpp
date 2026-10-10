// Checks handwritten/remote_store.hpp, which no example includes, including
// that get_sender connects to a receiver.
#include "remote_store.hpp"

namespace {
struct receiver {
  using receiver_concept = STDEXEC::receiver_t;
  void set_value(std::optional<std::string>) && noexcept {}
  void set_error(std::exception_ptr) && noexcept {}
  void set_stopped() && noexcept {}
};
}  // namespace

static_assert(STDEXEC::sender_to<get_sender, receiver>);
static_assert(
    STDEXEC::operation_state<STDEXEC::connect_result_t<get_sender, receiver>>);
