///////////////////////////////////////////////////////////////////////////////
//
// Module      :  purescript.hh
// Copyright   :  (c) Andy Arvanitis 2016
// License     :  MIT
//
// Maintainer  :  Andy Arvanitis <andy.arvanitis@gmail.com>
// Stability   :  experimental
// Portability :
//
// Includes and macros for garbage collection options
//
///////////////////////////////////////////////////////////////////////////////
//
#ifndef PureScript_GC_HH
#define PureScript_GC_HH

#if defined(USE_GC)
  #define GC_THREADS
  #include <gc/gc_cpp.h>
  #include <gc/gc_allocator.h>
  #define WITH_ALLOCATOR(T) , traceable_allocator<T>
  #define MANAGED_TYPE(T) T*
  #define MAKE_MANAGED(T) new (GC) T
  #define MAKE_MANAGED_FINALIZED(T) new (GC, [](void* p, void*){ static_cast<T*>(p)->~T(); }) T
  #define IS_POINTER_TYPE(T) std::is_pointer<T>
  #define POINTER_FROM_MEMBER(P) P
  #define INITIALIZE_GC(_) GC_INIT()
#else
  #include <memory>
  #define WITH_ALLOCATOR(_)
  #define MANAGED_TYPE(T) std::shared_ptr<T>
  #define MAKE_MANAGED(T) std::make_shared<T>
  #define MAKE_MANAGED_FINALIZED(T) MAKE_MANAGED(T)
  #define IS_POINTER_TYPE(T) std::is_assignable<managed<void>,T>
  #define POINTER_FROM_MEMBER(P) P.get()
  #define INITIALIZE_GC(_)
#endif

namespace PureScript {
  template <typename T>
  using managed = MANAGED_TYPE(T);

  template <typename T, typename... Args>
  inline static auto make_managed(Args&&... args) -> MANAGED_TYPE(T) {
    return MAKE_MANAGED(T)(std::forward<Args>(args)...);
  }

  template <typename T, typename... Args>
  inline static auto make_managed_and_finalized(Args&&... args) -> MANAGED_TYPE(T) {
    return MAKE_MANAGED_FINALIZED(T)(std::forward<Args>(args)...);
  }
}

#undef MANAGED_TYPE
#undef MAKE_MANAGED
#undef MAKE_MANAGED_FINALIZED

#endif // PureScript_GC_HH
