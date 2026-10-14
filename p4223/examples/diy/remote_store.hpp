// remote_store as in the paper's A Third Way, with get returning get_sender
#pragma once

#include "kv_store.hpp"

#include <exec/timed_thread_scheduler.hpp>

#include <map>

class remote_store final : public kv_store {
 public:
  remote_store(exec::timed_thread_scheduler latency,
               std::map<std::string, std::string> data);

  get_sender get(std::string key) const override;

 private:
  exec::timed_thread_scheduler latency_;
  std::map<std::string, std::string> data_;
};
