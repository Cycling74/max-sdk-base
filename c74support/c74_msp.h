#pragma once

#include "c74_max.h"

namespace c74 {
namespace max {

#ifdef C74_NO_SDK_BASE_SUBMODULE
#include "MaxAudioAPI.h"
#include "ext_buffer.h"
#else
#include "msp-includes/MaxAudioAPI.h"
#include "msp-includes/ext_buffer.h"
#endif

}
}
