// Checks net/read.hpp: an implementation may complete in any of the declared
// ways.
#include "read.hpp"

#include <exec/variant_sender.hpp>

#include <algorithm>
#include <utility>

// a stand-in connection that has a fixed number of bytes to give, then fails
struct connection {
  std::size_t available = 0;
};

pending_read read_from(connection& c, std::span<std::byte> buffer) {
  return pending_read(c, buffer, [](connection& c, std::span<std::byte> buffer) {
    using result = exec::variant_sender<
        decltype(ex::just(buffer)),
        decltype(ex::just(std::error_code(), buffer)),
        decltype(ex::just_error(std::error_code()))>;
    auto n = std::min(c.available, buffer.size());
    c.available -= n;
    if (n == buffer.size()) {
      return result(ex::just(buffer));
    }
    auto eof = std::make_error_code(std::errc::connection_reset);
    if (n == 0) {
      return result(ex::just_error(eof));
    }
    return result(ex::just(eof, buffer.first(n)));
  });
}
