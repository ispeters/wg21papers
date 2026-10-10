// The cache's storage, shared by every version of cache: a map guarded by a
// mutex, so concurrent lookups can share one cache.
#pragma once

#include <map>
#include <mutex>
#include <optional>
#include <string>
#include <utility>

class cache_entries {
 public:
  std::optional<std::string> find(std::string const& key) const {
    std::lock_guard lock(mutex_);
    if (auto it = entries_.find(key); it != entries_.end()) {
      return it->second;
    }
    return std::nullopt;
  }

  void insert(std::string key, std::string value) {
    std::lock_guard lock(mutex_);
    entries_.insert_or_assign(std::move(key), std::move(value));
  }

 private:
  mutable std::mutex mutex_;
  std::map<std::string, std::string> entries_;
};
