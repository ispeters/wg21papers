// cache as in the paper's A Third Way, with get returning lookup
#pragma once

#include "cache_entries.hpp"
#include "kv_store.hpp"

class cache final : public kv_store {
 public:
  explicit cache(kv_store const& backing);

  lookup get(std::string key) const noexcept override;

 private:
  kv_store const* backing_;
  mutable cache_entries entries_;
};
