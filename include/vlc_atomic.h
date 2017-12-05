/*****************************************************************************
 * vlc_atomic.h:
 *****************************************************************************
 * Copyright (C) 2010 R�mi Denis-Courmont
 *
 * This program is free software; you can redistribute it and/or modify it
 * under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation; either version 2.1 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with this program; if not, write to the Free Software Foundation,
 * Inc., 51 Franklin Street, Fifth Floor, Boston MA 02110-1301, USA.
 *****************************************************************************/

#ifndef VLC_ATOMIC_H
# define VLC_ATOMIC_H
/**
 * \file
 * Atomic operations do not require locking, but they are not very powerful.
 */

/* Clang older versions support atomics but lacks the stdatomic.h header */
#if defined(__clang__)
# if !defined(__has_include) || !__has_include(<stdatomic.h>)
#  define __STDC_NO_ATOMICS__ 1
# endif
#endif

 
# ifndef __cplusplus

#  if !defined (__STDC_NO_ATOMICS__) && !defined(COMPILE_VS2013)
/*** Native C11 atomics ***/
#   include <stdatomic.h>

#  else

#ifdef COMPILE_VS2013
#define WIN32_LEAN_AND_MEAN
#include <stddef.h>
#include <stdint.h>
#include <windows.h>
#endif



#ifdef COMPILE_VS2013
#define __sync_synchronize _mm_sfence  //vz!!!
#endif


#  define ATOMIC_FLAG_INIT false

#  define ATOMIC_VAR_INIT(value) (value)

#  define atomic_init(obj, value) \
    do { *(obj) = (value); } while(0)

#  define kill_dependency(y) \
    ((void)0)

#  define atomic_thread_fence(order) \
    __sync_synchronize()


#  define atomic_signal_fence(order) \
    ((void)0)

#  define atomic_is_lock_free(obj) \
    false

#ifdef COMPILE_VS2013
typedef intptr_t atomic_flag;
typedef intptr_t atomic_bool;
typedef intptr_t atomic_char;
typedef intptr_t atomic_schar;
typedef intptr_t atomic_uchar;
typedef intptr_t atomic_short;
typedef intptr_t atomic_ushort;
typedef intptr_t atomic_int;
typedef intptr_t atomic_uint;
typedef intptr_t atomic_long;
typedef intptr_t atomic_ulong;
typedef intptr_t atomic_llong;
typedef intptr_t atomic_ullong;
typedef intptr_t atomic_wchar_t;
typedef intptr_t atomic_int_least8_t;
typedef intptr_t atomic_uint_least8_t;
typedef intptr_t atomic_int_least16_t;
typedef intptr_t atomic_uint_least16_t;
typedef intptr_t atomic_int_least32_t;
typedef intptr_t atomic_uint_least32_t;
typedef intptr_t atomic_int_least64_t;
typedef intptr_t atomic_uint_least64_t;
typedef intptr_t atomic_int_fast8_t;
typedef intptr_t atomic_uint_fast8_t;
typedef intptr_t atomic_int_fast16_t;
typedef intptr_t atomic_uint_fast16_t;
typedef intptr_t atomic_int_fast32_t;
typedef intptr_t atomic_uint_fast32_t;
typedef intptr_t atomic_int_fast64_t;
typedef intptr_t atomic_uint_fast64_t;
typedef intptr_t atomic_intptr_t;
typedef uintptr_t atomic_uintptr_t;
typedef intptr_t atomic_size_t;
typedef intptr_t atomic_ptrdiff_t;
typedef intptr_t atomic_intmax_t;
typedef intptr_t atomic_uintmax_t;
#else
typedef          bool      atomic_flag;
typedef          bool      atomic_bool;
typedef          char      atomic_char;
typedef   signed char      atomic_schar;
typedef unsigned char      atomic_uchar;
typedef          short     atomic_short;
typedef unsigned short     atomic_ushort;
typedef          int       atomic_int;
typedef unsigned int       atomic_uint;
typedef          long      atomic_long;
typedef unsigned long      atomic_ulong;
typedef          long long atomic_llong;
typedef unsigned long long atomic_ullong;
//typedef          char16_t  atomic_char16_t;
//typedef          char32_t  atomic_char32_t;
typedef          wchar_t   atomic_wchar_t;
typedef       int_least8_t atomic_int_least8_t;
typedef      uint_least8_t atomic_uint_least8_t;
typedef      int_least16_t atomic_int_least16_t;
typedef     uint_least16_t atomic_uint_least16_t;
typedef      int_least32_t atomic_int_least32_t;
typedef     uint_least32_t atomic_uint_least32_t;
typedef      int_least64_t atomic_int_least64_t;
typedef     uint_least64_t atomic_uint_least64_t;
typedef       int_fast8_t atomic_int_fast8_t;
typedef      uint_fast8_t atomic_uint_fast8_t;
typedef      int_fast16_t atomic_int_fast16_t;
typedef     uint_fast16_t atomic_uint_fast16_t;
typedef      int_fast32_t atomic_int_fast32_t;
typedef     uint_fast32_t atomic_uint_fast32_t;
typedef      int_fast64_t atomic_int_fast64_t;
typedef     uint_fast64_t atomic_uint_fast64_t;
typedef          intptr_t atomic_intptr_t;
typedef         uintptr_t atomic_uintptr_t;
typedef            size_t atomic_size_t;
typedef         ptrdiff_t atomic_ptrdiff_t;
typedef          intmax_t atomic_intmax_t;
typedef         uintmax_t atomic_uintmax_t;
#endif
#  define atomic_store(object,desired) \
    do { \
        *(object) = (desired); \
        __sync_synchronize(); \
    } while (0)

#  define atomic_store_explicit(object,desired,order) \
    atomic_store(object,desired)

#  define atomic_load(object) \
    (__sync_synchronize(), *(object))

#  define atomic_load_explicit(object,order) \
    atomic_load(object)

#ifdef COMPILE_VS2013
static inline int atomic_exchange(intptr_t *object, intptr_t desired)
{
	intptr_t old = (intptr_t)InterlockedExchangePointer(
		(PVOID *)object, (PVOID)desired);
	return old;
}
#else

#  define atomic_exchange(object,desired) \
({  \
    typeof (object) _obj = (object); \
    typeof (*object) _old; \
    do \
        _old = atomic_load(_obj); \
    while (!__sync_bool_compare_and_swap(_obj, _old, (desired))); \
    _old; \
})
#endif

#  define atomic_exchange_explicit(object,desired,order) \
    atomic_exchange(object,desired)

#ifdef COMPILE_VS2013
static inline int atomic_compare_exchange(intptr_t *object, intptr_t *expected,
                                                 intptr_t desired)
{
    intptr_t old = *expected;
    *expected = (intptr_t)InterlockedCompareExchangePointer(
        (PVOID *)object, (PVOID)desired, (PVOID)old);
    return *expected == old;
}
#else
#  define atomic_compare_exchange(object,expected,desired) \
({  \
    typeof (object) _exp = (expected); \
    typeof (*object) _old = *_exp; \
    *_exp = __sync_val_compare_and_swap((object), _old, (desired)); \
    *_exp == _old; \
})
#endif

#  define atomic_compare_exchange_strong(object,expected,desired) \
    atomic_compare_exchange(object, expected, desired)
	
#  define atomic_compare_exchange_strong_explicit(object,expected,desired,order,order_different) \
    atomic_compare_exchange_strong(object, expected, desired)

#  define atomic_compare_exchange_weak(object,expected,desired) \
    atomic_compare_exchange(object, expected, desired)

#  define atomic_compare_exchange_weak_explicit(object,expected,desired,order_equal,order_different) \
    atomic_compare_exchange_weak(object, expected, desired)

#ifdef COMPILE_VS2013
#ifdef _WIN64
#define  __sync_fetch_and_add(object, operand) InterlockedExchangeAdd64(object, operand)
#define __sync_fetch_and_sub(object, operand) InterlockedExchangeAdd64(object, -(operand))
#define __sync_fetch_and_or(object, operand) InterlockedOr64(object, operand)
#define __sync_fetch_and_xor(object, operand) InterlockedOr64(object, operand)
#define __sync_fetch_and_and(object, operand) InterlockedOr64(object, operand)
#else
#define  __sync_fetch_and_add(object, operand) InterlockedExchangeAdd(object, operand)
#define __sync_fetch_and_sub(object, operand) InterlockedExchangeAdd(object, -(operand))
#define __sync_fetch_and_or(object, operand) InterlockedOr(object, operand)
#define __sync_fetch_and_xor(object, operand) InterlockedOr(object, operand)
#define __sync_fetch_and_and(object, operand) InterlockedOr(object, operand)
#endif /* _WIN64 */
#endif /* COMPILE_VS2013 */

#  define atomic_fetch_add(object,operand) \
    __sync_fetch_and_add(object, operand)

#  define atomic_fetch_add_explicit(object,operand,order) \
    atomic_fetch_add(object,operand)

#  define atomic_fetch_sub(object,operand) \
    __sync_fetch_and_sub(object, operand)
#  define atomic_fetch_sub_explicit(object,operand,order) \
    atomic_fetch_sub(object,operand)

#  define atomic_fetch_or(object,operand) \
    __sync_fetch_and_or(object, operand)
#  define atomic_fetch_or_explicit(object,operand,order) \
    atomic_fetch_or(object,operand)

#  define atomic_fetch_xor(object,operand) \
    __sync_fetch_and_xor(object, operand)
# define atomic_fetch_xor_explicit(object, operand, order) \
    atomic_fetch_xor(object, operand)
#  define atomic_fetch_and(object,operand) \
    __sync_fetch_and_and(object, operand)

#  define atomic_fetch_and_explicit(object,operand,order) \
    atomic_fetch_and(object,operand)

#  define atomic_flag_test_and_set(object) \
    atomic_exchange(object, true)

#  define atomic_flag_test_and_set_explicit(object,order) \
    atomic_flag_test_and_set(object)

#  define atomic_flag_clear(object) \
    atomic_store(object, false)

#  define atomic_flag_clear_explicit(object,order) \
    atomic_flag_clear(object)

# endif /* !C11 */

typedef atomic_uint_least32_t vlc_atomic_float;

static inline void vlc_atomic_init_float(vlc_atomic_float *var, float f)
{
	union { float f; uint32_t i; } u;
	u.f = f;
	atomic_init(var, u.i);
}

/** Helper to retrieve a single precision from an atom. */
static inline float vlc_atomic_load_float(vlc_atomic_float *atom)
{
	union { float f; uint32_t i; } u;
	u.i = atomic_load(atom);
	return u.f;
}

/** Helper to store a single precision into an atom. */
static inline void vlc_atomic_store_float(vlc_atomic_float *atom, float f)
{
	union { float f; uint32_t i; } u;
	u.f = f;
	atomic_store(atom, u.i);
}

# else /* C++ */
/*** Native C++11 atomics ***/
#   include <atomic>
# endif /* C++ */

#endif
