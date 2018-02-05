//===--- PolyhedralValueTransformer.h -- Polyhedral access analysis ---*- C++ -*-===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
//
//===----------------------------------------------------------------------===//

#ifndef POLYHEDRAL_VALUE_TRANSFORMER_H
#define POLYHEDRAL_VALUE_TRANSFORMER_H

#include "llvm/Analysis/AliasAnalysis.h"
#include "llvm/IR/Instructions.h"
#include "llvm/IR/PassManager.h"
#include "llvm/Pass.h"

namespace llvm {

class Loop;
class LoopInfo;
class PEXP;
class PolyhedralValueInfo;

class PolyhedralValueTransformer {

  /// The PolyhedralValueInfo used to get value information.
  PolyhedralValueInfo &PVI;

  AliasAnalysis &AA;

  LoopInfo &LI;

public:
  /// Constructor
  PolyhedralValueTransformer(PolyhedralValueInfo &PVI, AliasAnalysis &AA,
                             LoopInfo &LI);

  ~PolyhedralValueTransformer();

  bool hoistConditions(Loop &L);
  bool hoistConditions();

  bool checkExpressions(Loop &L);
  bool checkExpressions();

  bool checkLoopIdioms(Loop &L);
  bool checkLoopIdioms();

  /// Clear all cached information.
  void releaseMemory();

  PolyhedralValueInfo &getPolyhedralValueInfo() { return PVI; }

  /// Print some statistics to @p OS.
  void print(raw_ostream &OS) const;

  void dump() const;
};

/// Wrapper pass for PolyhedralValueTransformer on a per-function basis.
class PolyhedralValueTransformerWrapperPass : public FunctionPass {
  PolyhedralValueTransformer *PVT;
  Function *F;

public:
  static char ID;
  PolyhedralValueTransformerWrapperPass() : FunctionPass(ID) {}

  /// Return the PolyhedralValueTransformer object for the current function.
  PolyhedralValueTransformer &getPolyhedralValueTransformer() {
    assert(PVT);
    return *PVT;
  }

  /// @name Pass interface
  //@{
  virtual void getAnalysisUsage(AnalysisUsage &AU) const override;
  virtual void releaseMemory() override;
  virtual bool runOnFunction(Function &F) override;
  //@}

  virtual void print(raw_ostream &OS, const Module *) const override;
  void dump() const;
};

} // namespace llvm
#endif
