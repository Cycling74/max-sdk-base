#pragma once

#include "c74_max.h"

namespace c74 {
namespace max {

#ifdef C74_NO_SDK_BASE_SUBMODULE
#include "jit.common.h"
#include "max.jit.mop.h"
#else
#include "jit-includes/jit.common.h"
#include "jit-includes/max.jit.mop.h"
#endif

}
}
