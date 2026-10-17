// Checks future/kv_store.hpp, which no example includes, and that its get
// returns the same type as the one declared through async_fn.
#include "kv_store.hpp"

#include "fn/async_fn.hpp"

#include <type_traits>

static_assert(
    std::is_same_v<decltype(std::declval<kv_store const&>().get({})),
                   async_fn<std::optional<std::string>(std::string) const &>>);
