//===--- PolyhedralValueTransformer.cpp -- Polyhedral value transformer ---===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
//
//
//===----------------------------------------------------------------------===//

#include "llvm/Transforms/Scalar/PolyhedralValueTransformer.h"

#include "llvm/ADT/Statistic.h"
#include "llvm/Analysis/AliasSetTracker.h"
#include "llvm/Analysis/LoopInfo.h"
#include "llvm/Analysis/PolyhedralValueInfo.h"
#include "llvm/Analysis/PostDominators.h"
#include "llvm/Analysis/ValueTracking.h"
#include "llvm/IR/LegacyPassManager.h"
#include "llvm/IR/Dominators.h"
#include "llvm/Passes/PassBuilder.h"
#include "llvm/Support/Debug.h"
#include "llvm/Support/raw_ostream.h"
#include "llvm/Transforms/IPO/PassManagerBuilder.h"
#include "llvm/Transforms/Scalar.h"

#include <cassert>

using namespace llvm;

#define DEBUG_TYPE "polyhedral-value-transformer"

STATISTIC(NUM_PARTIALLY_VALID_CONDITIONS, "Number of partially valid conditions");
STATISTIC(NUM_ALWAYS_VALID_CONDITIONS, "Number of always valid conditions");
STATISTIC(NUM_PARTIALLY_VALID_CONDITION_DOMAINS, "Number of partially valid condition domains");
STATISTIC(NUM_CONDITIONS_IN_LOOP, "Number of conditions in loops");
STATISTIC(NUM_LATCH_CONDITIONS, "Number of latch conditions");
STATISTIC(NUM_EXIT_CONDITIONS, "Number of exit conditions");
STATISTIC(NUM_ALWAYS_VALID_CONDITION_DOMAINS, "Number of always valid condition domains");
STATISTIC(NUM_HOISTABLE_CONDITIONS, "Number of hoistable (always valid) conditions");
STATISTIC(NUM_HOISTABLE_LATCH_CONDITIONS, "Number of hoistable (always valid) latch conditions");
STATISTIC(NUM_HOISTABLE_EXIT_CONDITIONS, "Number of hoistable (always valid) exit conditions");
STATISTIC(NUM_ALWAYS_TAKEN_CONDITIONS, "Number of always taken (always valid) conditions");
STATISTIC(NUM_ALWAYS_TAKEN_LATCH_CONDITIONS, "Number of always taken (always valid) latch conditions");
STATISTIC(NUM_ALWAYS_TAKEN_EXIT_CONDITIONS, "Number of always taken (always valid) exit conditions");
STATISTIC(NUM_NEVER_TAKEN_CONDITIONS, "Number of never taken (always valid) conditions");
STATISTIC(NUM_NEVER_TAKEN_LATCH_CONDITIONS, "Number of never taken (always valid) latch conditions");
STATISTIC(NUM_NEVER_TAKEN_EXIT_CONDITIONS, "Number of never taken (always valid) exit conditions");
STATISTIC(NUM_PARTIALLY_HOISTABLE_CONDITIONS, "Number of hoistable (partially valid) conditions");
STATISTIC(NUM_PARTIALLY_HOISTABLE_LATCH_CONDITIONS, "Number of hoistable (partially valid) latch conditions");
STATISTIC(NUM_PARTIALLY_HOISTABLE_EXIT_CONDITIONS, "Number of hoistable (partially valid) exit conditions");
STATISTIC(NUM_PARTIALLY_ALWAYS_TAKEN_CONDITIONS, "Number of always taken (partially valid) conditions");
STATISTIC(NUM_PARTIALLY_ALWAYS_TAKEN_LATCH_CONDITIONS, "Number of always taken (partially valid) latch conditions");
STATISTIC(NUM_PARTIALLY_ALWAYS_TAKEN_EXIT_CONDITIONS, "Number of always taken (partially valid) exit conditions");
STATISTIC(NUM_PARTIALLY_NEVER_TAKEN_CONDITIONS, "Number of never taken (partially valid) conditions");
STATISTIC(NUM_PARTIALLY_NEVER_TAKEN_LATCH_CONDITIONS, "Number of never taken (partially valid) latch conditions");
STATISTIC(NUM_PARTIALLY_NEVER_TAKEN_EXIT_CONDITIONS, "Number of never taken (partially valid) exit conditions");

STATISTIC(NUM_INT_DIFF, "Number of integer differences");
STATISTIC(NUM_CST_DIFF, "Number of constant differences");
STATISTIC(NUM_ONE_LOOP_DIFF, "Number of differences involving one loop");
STATISTIC(NUM_ONE_LOOP_DIFF_ONE_PARAM, "Number of differences involving one loop and one param");

static cl::opt<bool> PVTEnabled("pvt", cl::desc("Enable pvt"), cl::init(false),
                                cl::ZeroOrMore);

// ------------------------------------------------------------------------- //

PolyhedralValueTransformer::PolyhedralValueTransformer(
    PolyhedralValueInfo &PVI, AliasAnalysis &AA, LoopInfo &LI)
    : PVI(PVI), AA(AA), LI(LI) {}

PolyhedralValueTransformer::~PolyhedralValueTransformer() { releaseMemory(); }

bool PolyhedralValueTransformer::hoistConditions(Loop &L) {
  errs() << "CHECK Loop: " << L.getName() << "\n";

  for (BasicBlock *BB : L.blocks()) {
    errs() << "  CHECK BB: " << BB->getName() << "\n";
    TerminatorInst *TI = BB->getTerminator();
    BranchInst *BI = dyn_cast<BranchInst>(TI);
    if (!BI || BI->getNumSuccessors() == 1)
      continue;
    NUM_CONDITIONS_IN_LOOP++;

    bool IsExit = false, IsLatch = false;
    if (LI.getLoopFor(BB) != LI.getLoopFor(BI->getSuccessor(0)) ||
        LI.getLoopFor(BB) != LI.getLoopFor(BI->getSuccessor(1)))
      IsExit = true;
    if ((LI.isLoopHeader(BI->getSuccessor(0)) &&
          LI.getLoopFor(BI->getSuccessor(0))->contains(BB)) ||
        (LI.isLoopHeader(BI->getSuccessor(1)) &&
          LI.getLoopFor(BI->getSuccessor(1))->contains(BB)))
      IsLatch = true;

    NUM_EXIT_CONDITIONS += IsExit;
    NUM_LATCH_CONDITIONS += IsLatch;

    Value *Condition = BI->getCondition();
    const PEXP *ConditionPEXP = PVI.getPEXP(Condition, L.getParentLoop());
    if (!ConditionPEXP || !PVI.isAffine(ConditionPEXP) || !PVI.hasScope(ConditionPEXP, L.getParentLoop(), false))
      continue;

    const PEXP *DomainPEXP = PVI.getDomainFor(BB, L.getParentLoop());
    if (!DomainPEXP || !PVI.isAffine(DomainPEXP) || !PVI.hasScope(DomainPEXP, L.getParentLoop(), false))
      continue;
    bool ValidCond = PVI.isAlwaysValid(ConditionPEXP);
    if (ValidCond) {
      NUM_ALWAYS_VALID_CONDITIONS++;
    } else {
      NUM_PARTIALLY_VALID_CONDITIONS++;
    }
    bool DomainCond = PVI.isAlwaysValid(DomainPEXP);
    if (DomainCond) {
      NUM_ALWAYS_VALID_CONDITION_DOMAINS++;
    } else {
      NUM_PARTIALLY_VALID_CONDITION_DOMAINS++;
    }


    PVAff ConditionPVAff = ConditionPEXP->getPWA();
    errs() << "VALID CONDITION PVAFF: " << ConditionPVAff << " for : " << *Condition << "\n";
    errs() << "VALID CONDITION DOMAIN: " << DomainPEXP << " for : " << BB->getName() << "\n";
    ConditionPVAff.intersectDomain(DomainPEXP->getDomain());
    errs() << "VALID CONDITION PVAFF: " << ConditionPVAff << " for : " << *Condition << "\n";

    unsigned DepthDiff = LI.getLoopFor(BB)->getLoopDepth() - L.getLoopDepth();
    ConditionPVAff.dropLastInputDims(DepthDiff + 1);
    errs() << "WITHOUT LAST " << DepthDiff + 1 << " DIMS: " << ConditionPVAff << "\n";

    PVSet NotTakenConditions = ConditionPVAff.zeroSet();
    errs() << "NOT TAKEN CONDITIONS " << NotTakenConditions << "\n";

    if (ValidCond && DomainCond) {
      if (NotTakenConditions.isEmpty()) {
        NUM_ALWAYS_TAKEN_CONDITIONS++;
        NUM_ALWAYS_TAKEN_EXIT_CONDITIONS += IsExit;
        NUM_ALWAYS_TAKEN_LATCH_CONDITIONS += IsLatch;
      } else if (NotTakenConditions.isUniverse()) {
        NUM_NEVER_TAKEN_CONDITIONS++;
        NUM_NEVER_TAKEN_EXIT_CONDITIONS += IsExit;
        NUM_NEVER_TAKEN_LATCH_CONDITIONS += IsLatch;
      } else {
        NUM_HOISTABLE_CONDITIONS++;
        NUM_HOISTABLE_EXIT_CONDITIONS += IsExit;
        NUM_HOISTABLE_LATCH_CONDITIONS += IsLatch;
        BI->getDebugLoc().print(errs());
      }
    } else {
      if (NotTakenConditions.isEmpty()) {
        NUM_PARTIALLY_ALWAYS_TAKEN_CONDITIONS++;
        NUM_PARTIALLY_ALWAYS_TAKEN_EXIT_CONDITIONS += IsExit;
        NUM_PARTIALLY_ALWAYS_TAKEN_LATCH_CONDITIONS += IsLatch;
      } else if (NotTakenConditions.isUniverse()) {
        NUM_PARTIALLY_NEVER_TAKEN_CONDITIONS++;
        NUM_PARTIALLY_NEVER_TAKEN_EXIT_CONDITIONS += IsExit;
        NUM_PARTIALLY_NEVER_TAKEN_LATCH_CONDITIONS += IsLatch;
      } else {
        NUM_PARTIALLY_HOISTABLE_CONDITIONS++;
        NUM_PARTIALLY_HOISTABLE_EXIT_CONDITIONS += IsExit;
        NUM_PARTIALLY_HOISTABLE_LATCH_CONDITIONS += IsLatch;
        BI->getDebugLoc().print(errs());
      }
    }
  }

  for (Loop *SubL : L)
    hoistConditions(*SubL);

  return false;
}

bool PolyhedralValueTransformer::hoistConditions() {
  bool Changed = false;

  for (Loop *L : LI)
    Changed |= hoistConditions(*L);

  //PVI.print(errs());

  return Changed;
}

static void collectUsers(Instruction *I, Loop &L, SmallPtrSetImpl<Instruction *> &Users) {
  if (!I || !L.contains(I))
    return;
  if (!Users.insert(I).second)
    return;
  for (auto *User : I->users())
    collectUsers(dyn_cast<Instruction>(User), L, Users);
}

bool PolyhedralValueTransformer::checkExpressions(Loop &L) {

  DenseMap<Type *, SmallVector<Instruction *, 16>> TypeInstMap;
  DenseMap<Instruction *, SmallPtrSet<Instruction *, 16>> UserMap;
  for (BasicBlock *BB : L.blocks()) {
    if (LI.getLoopFor(BB) != &L)
      continue;
    for (auto &Inst : *BB)
      if (Inst.getType()->isIntegerTy() || Inst.getType()->isPointerTy()) {
        TypeInstMap[Inst.getType()].push_back(&Inst);
        collectUsers(&Inst, L, UserMap[&Inst]);
      }
  }

  for (auto &It : TypeInstMap) {
    auto &Insts = It.second;
    unsigned NumEntries = Insts.size();
    errs() << "\nTYPE: " << *It.first << " [#" << NumEntries << "]\n";
    for (unsigned u0 = 0; u0 < NumEntries; u0++) {
      Instruction *I0 = Insts[u0];
      const PEXP *I0PEXP = nullptr;
      for (unsigned u1 = u0 + 1; u1 < NumEntries; u1++) {
        Instruction *I1 = Insts[u1];
        if (UserMap[I0].count(I1) || UserMap[I1].count(I0))
          continue;
        if (!I0PEXP) {
          I0PEXP = PVI.getPEXP(I0, L.getParentLoop());
          if (!(I0PEXP && PVI.isAffine(I0PEXP) &&// PVI.isAlwaysValid(I0PEXP) &&
              PVI.hasScope(I0PEXP, L.getParentLoop(), false)))
            break;
        }
        const PEXP *I1PEXP = PVI.getPEXP(I1, L.getParentLoop());
        if (!(I1PEXP && PVI.isAffine(I1PEXP) && //PVI.isAlwaysValid(I1PEXP) &&
            PVI.hasScope(I1PEXP, L.getParentLoop(), false)))
          continue;
        PVAff DiffAff = PVAff::createSub(I0PEXP->getPWA(), I1PEXP->getPWA());
        DiffAff.dropUnusedParameters();
        bool IsInt = DiffAff.isInteger();
        bool IsCst = DiffAff.isConstant();
        errs() << "\t Inst0: " << *I0 << "\n\t Inst1: " << *I1 << "\n";
        errs() << "\t PEXP0: " << I0PEXP << "\n\t PEXP1: " << I1PEXP << "\n";
        errs() << "\t Stats: [C: " << IsCst << "][I: " << IsInt << "][P: " << DiffAff.getNumParameters() << "]";
        unsigned InvolvedDims = 0;
        for (unsigned d = 0; d < DiffAff.getNumInputDimensions(); d++) {
          bool InvolvesDim = DiffAff.involvesInput(d);
          errs() << "[ID L" << d << ": " << InvolvesDim << "]";
          InvolvedDims += InvolvesDim;
        }
        if (IsInt || (InvolvedDims == 1 && DiffAff.getNumParameters() == 0))
          errs() << "\n\tGOOD DIFF: " << DiffAff << "!\n\n";
        else
          errs() << "\n\t Diff: " << DiffAff << "\n\n";

        NUM_INT_DIFF += IsInt;
        NUM_CST_DIFF += IsCst;
        NUM_ONE_LOOP_DIFF += (InvolvedDims == 1 && DiffAff.getNumParameters() == 0);
        NUM_ONE_LOOP_DIFF_ONE_PARAM += (InvolvedDims == 1 && DiffAff.getNumParameters() == 1);

      }
    }
  }

  for (Loop *SubL : L)
    checkExpressions(*SubL);

  return false;
}

bool PolyhedralValueTransformer::checkExpressions() {
  bool Changed = false;

  for (Loop *L : LI)
    Changed |= checkExpressions(*L);

  //PVI.print(errs());

  return Changed;
}

bool PolyhedralValueTransformer::checkLoopIdioms(Loop &L) {
  const DataLayout &DL = L.getHeader()->getModule()->getDataLayout();
  AliasSetTracker AST(AA);

  DenseMap<Value *, SmallPtrSet<StoreInst *, 8>> Obj2StoresMap;
  for (BasicBlock *BB : L.blocks()) {
    for (Instruction &I : *BB) {
      if (I.mayThrow()) {
        errs() << "may throw: " << I << "\n";
        return false;
      }
      if (!I.mayReadOrWriteMemory())
        continue;

      AST.add(&I);

      StoreInst *SI = dyn_cast<StoreInst>(&I);
      if (!SI || !SI->isUnordered() || SI->isVolatile())
        continue;
      if (SI->getMetadata(LLVMContext::MD_nontemporal))
        continue;

      Value *Ptr = SI->getPointerOperand();
      errs() << " Ptr: " << *Ptr << "\n";
      Value *Obj = GetUnderlyingObject(Ptr, DL, 10);
      errs() << " Obj: " << *Obj << "\n";
      Obj2StoresMap[Obj].insert(SI);
    }
  }

  errs() << " Objects:\n";
  for (auto &It : Obj2StoresMap) {
    errs() << " - " << *It.first << " #" << It.second.size() << " stores\n";
    AAMDNodes AATags;
    AliasSet *AS = AST.getAliasSetForPointerIfExists(
        It.first, MemoryLocation::UnknownSize, AATags);
    if (!AS)
      continue;
    errs() << "AliasSet: "; AS->dump();
    for (auto &ASIt : *AS) {
      errs() << "\n - " << *ASIt.getValue() << "";
    }
  }

  for (Loop *SubL : L)
    checkLoopIdioms(*SubL);
}

bool PolyhedralValueTransformer::checkLoopIdioms() {
  bool Changed = false;

  for (Loop *L : LI)
    Changed |= checkLoopIdioms(*L);

  return Changed;
}


void PolyhedralValueTransformer::releaseMemory() {}

void PolyhedralValueTransformer::print(raw_ostream &OS) const {
}

void PolyhedralValueTransformer::dump() const { return print(dbgs()); }

// ------------------------------------------------------------------------- //

char PolyhedralValueTransformerWrapperPass::ID = 0;

void PolyhedralValueTransformerWrapperPass::getAnalysisUsage(
    AnalysisUsage &AU) const {
  AU.addRequired<PolyhedralValueInfoWrapperPass>();
  AU.addRequired<AAResultsWrapperPass>();
  AU.addRequired<LoopInfoWrapperPass>();
  AU.setPreservesAll();
}

void PolyhedralValueTransformerWrapperPass::releaseMemory() {
  delete PVT;

  F = nullptr;
  PVT = nullptr;
}

bool PolyhedralValueTransformerWrapperPass::runOnFunction(Function &F) {
  F.dump();

  AliasAnalysis &AA = getAnalysis<AAResultsWrapperPass>().getAAResults();
  auto &LI = getAnalysis<LoopInfoWrapperPass>().getLoopInfo();
  auto &PVI = getAnalysis<PolyhedralValueInfoWrapperPass>()
                  .getPolyhedralValueInfo();
  PVT = new PolyhedralValueTransformer(PVI, AA, LI);
  //PVT->hoistConditions();
  //PVT->checkExpressions();
  PVT->checkLoopIdioms();

  this->F = &F;
  return false;
}

void PolyhedralValueTransformerWrapperPass::print(raw_ostream &OS,
                                                  const Module *M) const {
  PVT->print(OS);
}

FunctionPass *llvm::createPolyhedralValueTransformerWrapperPass() {
  initializePolyhedralValueTransformerWrapperPassPass(
      *PassRegistry::getPassRegistry());
  return new PolyhedralValueTransformerWrapperPass();
}

void PolyhedralValueTransformerWrapperPass::dump() const {
  return print(dbgs(), nullptr);
}

INITIALIZE_PASS_BEGIN(PolyhedralValueTransformerWrapperPass,
                      "polyhedral-value-transformer", "Polyhedral vt", false,
                      false);
INITIALIZE_PASS_DEPENDENCY(LoopInfoWrapperPass);
INITIALIZE_PASS_DEPENDENCY(PolyhedralValueInfoWrapperPass);
INITIALIZE_PASS_END(PolyhedralValueTransformerWrapperPass,
                    "polyhedral-value-transformer", "Polyhedral vt", false,
                    false)
