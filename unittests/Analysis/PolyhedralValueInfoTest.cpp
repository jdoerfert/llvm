//===- PolyhedrealValueInfoTest.cpp - PolyhedralValueInfo unit tests ------===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//

#include "llvm/ADT/SmallVector.h"
#include "llvm/Analysis/LoopInfo.h"
#include "llvm/Analysis/TargetLibraryInfo.h"
#include "llvm/Analysis/PolyhedralValueInfo.h"
#include "llvm/AsmParser/Parser.h"
#include "llvm/IR/Constants.h"
#include "llvm/IR/Dominators.h"
#include "llvm/IR/GlobalVariable.h"
#include "llvm/IR/IRBuilder.h"
#include "llvm/IR/InstIterator.h"
#include "llvm/IR/LLVMContext.h"
#include "llvm/IR/LegacyPassManager.h"
#include "llvm/IR/Module.h"
#include "llvm/IR/Verifier.h"
#include "llvm/Support/SourceMgr.h"
#include "gtest/gtest.h"

namespace llvm {
namespace {

// We use this fixture to ensure that we clean up PolyhedralValueInfo before
// deleting the PassManager.
class PolyhedrealValueInfoTest : public testing::Test {
protected:
  LLVMContext Context;
  PVCtx Ctx;
  Module M;

  std::unique_ptr<LoopInfo> LI;
  std::unique_ptr<DominatorTree> DT;

  PolyhedrealValueInfoTest() : M("", Context) {}

  PolyhedralValueInfo buildSE(Function &F) {
    DT.reset(new DominatorTree(F));
    LI.reset(new LoopInfo(*DT));
    return PolyhedralValueInfo(Ctx, *LI.get());
  }
};

TEST_F(PolyhedrealValueInfoTest, PEXPConstants) {

  FunctionType *FTy = FunctionType::get(Type::getVoidTy(Context),
                                              std::vector<Type *>(), false);
  Function *F = cast<Function>(M.getOrInsertFunction("f", FTy));
  BasicBlock *BB = BasicBlock::Create(Context, "entry", F);
  ReturnInst::Create(Context, nullptr, BB);

  PolyhedralValueInfo SE = buildSE(*F);

  IntegerType *Int32Ty = IntegerType::get(Context, 32);
  const PEXP *OneI32a = SE.getPEXP(ConstantInt::get(Int32Ty, 1));
  const PEXP *OneI32b = SE.getPEXP(ConstantInt::get(Int32Ty, 1));
  const PEXP *MinusOneI32 = SE.getPEXP(ConstantInt::get(Int32Ty, -1));

  EXPECT_EQ(OneI32a, OneI32b);
  EXPECT_EQ(OneI32a, MinusOneI32);

}

TEST_F(PolyhedrealValueInfoTest, PEXPUnknownRAUW) {
  FunctionType *FTy = FunctionType::get(Type::getVoidTy(Context),
                                              std::vector<Type *>(), false);
  Function *F = cast<Function>(M.getOrInsertFunction("f", FTy));
  BasicBlock *BB = BasicBlock::Create(Context, "entry", F);
  ReturnInst::Create(Context, nullptr, BB);

  Type *Ty = Type::getInt1Ty(Context);
  Constant *Init = Constant::getNullValue(Ty);
  Value *V0 = new GlobalVariable(M, Ty, false, GlobalValue::ExternalLinkage, Init, "V0");
  Value *V1 = new GlobalVariable(M, Ty, false, GlobalValue::ExternalLinkage, Init, "V1");
  Value *V2 = new GlobalVariable(M, Ty, false, GlobalValue::ExternalLinkage, Init, "V2");

  PolyhedralValueInfo SE = buildSE(*F);

  const PEXP *S0 = SE.getPEXP(V0);
  const PEXP *S1 = SE.getPEXP(V1);
  const PEXP *S2 = SE.getPEXP(V2);

  EXPECT_EQ(S0, S1);
  EXPECT_EQ(S0, S2);
  EXPECT_EQ(S1, S2);

#if 0
  const PEXP *P0 = SE.getAddExpr(S0, S0);
  const PEXP *P1 = SE.getAddExpr(S1, S1);
  const PEXP *P2 = SE.getAddExpr(S2, S2);

  const PEXPMulExpr *M0 = cast<PEXPMulExpr>(P0);
  const PEXPMulExpr *M1 = cast<PEXPMulExpr>(P1);
  const PEXPMulExpr *M2 = cast<PEXPMulExpr>(P2);

  EXPECT_EQ(cast<PEXPConstant>(M0->getOperand(0))->getValue()->getZExtValue(),
            2u);
  EXPECT_EQ(cast<PEXPConstant>(M1->getOperand(0))->getValue()->getZExtValue(),
            2u);
  EXPECT_EQ(cast<PEXPConstant>(M2->getOperand(0))->getValue()->getZExtValue(),
            2u);

  // Before the RAUWs, these are all pointing to separate values.
  EXPECT_EQ(cast<PEXPUnknown>(M0->getOperand(1))->getValue(), V0);
  EXPECT_EQ(cast<PEXPUnknown>(M1->getOperand(1))->getValue(), V1);
  EXPECT_EQ(cast<PEXPUnknown>(M2->getOperand(1))->getValue(), V2);

  // Do some RAUWs.
  V2->replaceAllUsesWith(V1);
  V1->replaceAllUsesWith(V0);

  // After the RAUWs, these should all be pointing to V0.
  EXPECT_EQ(cast<PEXPUnknown>(M0->getOperand(1))->getValue(), V0);
  EXPECT_EQ(cast<PEXPUnknown>(M1->getOperand(1))->getValue(), V0);
  EXPECT_EQ(cast<PEXPUnknown>(M2->getOperand(1))->getValue(), V0);
#endif
}

}  // end anonymous namespace
}  // end namespace llvm
