// cache as in the paper's A Third Way, with get returning get_sender
#pragma once

#include "cache_entries.hpp"
#include "kv_store.hpp"

class cache final : public kv_store {
 public:
  explicit cache(kv_store const& backing);

  get_sender get(std::string key) const override;

 private:
  kv_store const* backing_;
  mutable cache_entries entries_;
};
