#include "remote_store.hpp"

#include <chrono>
#include <utility>

remote_store::remote_store(exec::timed_thread_scheduler latency,
                           std::map<std::string, std::string> data)
    : latency_(latency), data_(std::move(data)) {}

get_sender remote_store::get(std::string key) const {
  return get_sender(
      *this, std::move(key), [](remote_store const& self, std::string key) {
        return exec::schedule_after(self.latency_,
                                    std::chrono::milliseconds{5}) |
               ex::then([data = &self.data_, key = std::move(key)] {
                 std::optional<std::string> value;
                 if (auto it = data->find(key); it != data->end()) {
                   value = it->second;
                 }
                 return value;
               });
      });
}
