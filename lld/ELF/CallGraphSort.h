//===- CallGraphSort.h ------------------------------------------*- C++ -*-===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//

#ifndef LLD_ELF_CALL_GRAPH_SORT_H
#define LLD_ELF_CALL_GRAPH_SORT_H

#include "llvm/ADT/DenseMap.h"

namespace lld::elf {
struct Ctx;
class InputSectionBase;

llvm::DenseMap<const InputSectionBase *, int>
computeCallGraphProfileOrder(Ctx &);
} // namespace lld::elf

#endif
