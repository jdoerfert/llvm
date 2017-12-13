//===----- PolyhedralExpressionBuilder.cpp  - TODO --------------*- C++ -*-===//
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

#include "llvm/Analysis/PolyhedralAccessInfo.h"

#include "llvm/ADT/Statistic.h"
#include "llvm/Analysis/LoopInfo.h"
#include "llvm/Analysis/Passes.h"
#include "llvm/Analysis/PolyhedralExpressionBuilder.h"
#include "llvm/Analysis/PolyhedralValueInfo.h"
#include "llvm/Analysis/PostDominators.h"
#include "llvm/IR/Dominators.h"
#include "llvm/IR/InstVisitor.h"
#include "llvm/IR/Instructions.h"
#include "llvm/Pass.h"
#include "llvm/Support/Debug.h"
#include "llvm/Support/raw_ostream.h"

#include <cassert>

using namespace llvm;

#define DEBUG_TYPE "polyhedral-access-info"

raw_ostream &llvm::operator<<(raw_ostream &OS, PACC::AccessKind Kind) {
  switch (Kind) {
  case PACC::AK_READ:
    return OS << "READ";
  case PACC::AK_WRITE:
    return OS << "WRITE";
  case PACC::AK_READ_WRITE:
    return OS << "READ & WRITE";
  default:
    llvm_unreachable("Unknown polyhedral access kind");
  }
}

PACC::PACC(Value &Pointer, PEXP &PE, PVId Id, AccessKind AccKind)
    : BasePointer(Id.getPayloadAs<Value *>()), Pointer(&Pointer), Id(Id),
      PE(PE), AccKind(AccKind) {
  PE.getPWA().dropUnusedParameters();
}

PACC::~PACC() { delete &PE; }

void PACC::print(raw_ostream &OS) const {
  OS << "PACC [" << *PE.getValue() << "] @ [" << Pointer << "]\n"
     << Id << "[" << PE << "] (" << AccKind << ")\n";
}

void PACC::dump() const { print(dbgs()); }

raw_ostream &llvm::operator<<(raw_ostream &OS, const PACC *PA) {
  if (PA)
    OS << *PA;
  else
    OS << "<null>";
  return OS;
}

raw_ostream &llvm::operator<<(raw_ostream &OS, const PACC &PA) {
  PA.print(OS);
  return OS;
}

// ------------------------------------------------------------------------- //

PACCSummary::PACCSummary(SummaryScopeKind Kind, const ContainsFuncTy &Contains,
                         Loop *Scope)
    : Kind(Kind), Contains(Contains), Scope(Scope) {}

PACCSummary::~PACCSummary() { DeleteContainerSeconds(ArrayInfoMap); }

static uint64_t getElementSize(Value *Pointer, const DataLayout &DL) {
  Type *PointerTy = Pointer->getType();
  assert(PointerTy->isPointerTy());

  return DL.getTypeStoreSize(PointerTy->getPointerElementType());
}

const PEXP *
PACCSummary::findMultidimensionalViewSize(PolyhedralValueInfo &PI,
                                          ArrayRef<const PEXP *> PEXPs,
                                          Instruction *&I, const PEXP *&Rem) {

  if (PEXPs.empty())
    return nullptr;

  DEBUG({
    dbgs() << "Find multi dim view sizes for:\n";
    for (const auto *PE : PEXPs)
      dbgs() << "\t - " << PE->getPWA() << " [" << *PE->getValue() << "]\n";
  });

  SmallPtrSet<Value *, 4> ExprParameterSet, DomainParameterSet;
  SmallVector<Value *, 4> ParameterVector;
  for (const PEXP *PE : PEXPs) {
    ParameterVector.clear();
    PE->getPWA().getParameters(ParameterVector);
    ExprParameterSet.insert(ParameterVector.begin(), ParameterVector.end());
    ParameterVector.clear();

    PE->getDomain().getParameters(ParameterVector);
    DomainParameterSet.insert(ParameterVector.begin(), ParameterVector.end());
  }

  DEBUG(dbgs() << "Found " << ExprParameterSet.size()
               << " expression parameters\nFound " << DomainParameterSet.size()
               << " domain parameters\n");

  for (Value *V : DomainParameterSet)
    ExprParameterSet.erase(V);

  DenseMap<Value *, SmallVector<std::pair<Instruction *, const PEXP *>, 4>>
      PotentialSizes;
  for (Value *V : ExprParameterSet) {
    auto *I = dyn_cast<Instruction>(V);
    if (!I) {
      DEBUG(dbgs() << "\tSkip non instruction: " << *V << "\n");
      continue;
    }

    if (I->getOpcode() != Instruction::Mul) {
      DEBUG(dbgs() << "\tSkip non multiplication: " << *I << " (TODO?)\n");
      continue;
    }

    DEBUG(dbgs() << "\tPossible multi dim view computation: " << *I << "\n");
    Value *Op0 = I->getOperand(0);
    Value *Op1 = I->getOperand(1);

    if (!isa<Instruction>(Op0))
      PotentialSizes[Op0].push_back(std::make_pair(I, PI.getPEXP(Op1, Scope)));
    if (!isa<Instruction>(Op1))
      PotentialSizes[Op1].push_back(std::make_pair(I, PI.getPEXP(Op0, Scope)));

    DEBUG(if (isa<Instruction>(Op0) && isa<Instruction>(Op1)) dbgs()
              << "No non instruction operand found\n";);
  }

  DEBUG(dbgs() << "Found " << PotentialSizes.size() << " potential sizes\n");
  if (PotentialSizes.empty()) {
    return nullptr;
  }

  if (PotentialSizes.size() != 1) {
    DEBUG(dbgs() << "TODO: choose potential size!\n");
    return nullptr;
  }
  if (PotentialSizes.begin()->second.size() != 1) {
    DEBUG(dbgs() << "TODO: this is a hack!\n");
    return nullptr;
  }

  I = PotentialSizes.begin()->second.front().first;
  Rem = PotentialSizes.begin()->second.front().second;
  return PI.getPEXP(PotentialSizes.begin()->first, Scope);
}

void PACCSummary::findMultidimensionalView(PolyhedralValueInfo &PI,
                                           MultiDimensionalViewInfo &MDVI,
                                           ArrayRef<const PACC *> PACCs) {
  if (PACCs.empty())
    return;

  SmallVector<const PEXP *, 8> PEXPs;
  PEXPs.reserve(PACCs.size());
  for (auto *PA : PACCs)
    PEXPs.push_back(PA->getPEXP());

  Instruction *I;
  const PEXP *Rem;
  while (1) {
    const PEXP *DimSize = findMultidimensionalViewSize(PI, PEXPs, I, Rem);
    DEBUG(dbgs() << "DimSize: " << DimSize << "\n");
    if (!DimSize)
      return;

    assert(I && Rem);
    MDVI.DimensionSizes.push_back(DimSize);
    unsigned CurDim = MDVI.DimensionSizes.size();
    auto &DimInfo = MDVI.DimensionInstsMap[I];
    if (!DimInfo.second)
      DimInfo = std::make_pair(CurDim, Rem);
    else {
      assert(DimInfo.second == Rem);
      DimInfo.first = std::max(DimInfo.first, CurDim);
    }

    PEXPs.clear();
    PEXPs.push_back(Rem);
  }
}

void PACCSummary::finalize(PolyhedralValueInfo &PI,
                           ArrayRef<const PACC *> PACCs, const DataLayout &DL) {
  assert(ArrayInfoMap.empty());

  for (const PACC *PA : PACCs) {
    Value *BasePointer = PA->getBasePointer();

    if (Kind == SSK_EXTERNAL && isa<AllocaInst>(BasePointer))
      continue;

    PACCMap[BasePointer].push_back(PA);
  }

  for (auto It : PACCMap) {
    Value *BasePointer = It.first;
    auto &PACCVector = It.second;

    DEBUG(dbgs() << "\n\nAI:\n");
    ArrayInfo *&AI = ArrayInfoMap[BasePointer];
    AI = new ArrayInfo();

    AI->ElementSize = getElementSize(PACCVector[0]->getPointer(), DL);
    for (const PACC *PA : PACCVector) {
      // TODO: Also take the constant PA offset into account!
      AI->ElementSize = GreatestCommonDivisor64(
          AI->ElementSize, getElementSize(PA->getPointer(), DL));
    }
    DEBUG(dbgs() << "ElementSize: " << AI->ElementSize << "\n");

    MultiDimensionalViewInfo MDVI(AI->DimensionSizes);
    findMultidimensionalView(PI, MDVI, PACCVector);

    DEBUG({
      dbgs() << "Dimension sizes:\n";
      for (const PEXP *PE : AI->DimensionSizes)
        dbgs() << "\t - " << PE->getPWA() << "\n";
    });

    for (const PACC *PA : PACCVector) {
      PVAff PWA = PA->getPEXP()->getPWA();
      PWA.floordiv(AI->ElementSize);

      SmallVector<PVAff, 4> DimPWAs;
      DEBUG(dbgs() << "\n\nPWA:" << PWA << "\n");

      SmallVector<std::pair<Instruction *, const PEXP *>, 4> Dimensions;
      Dimensions.resize(MDVI.DimensionSizes.size());
      for (const auto &It : MDVI.DimensionInstsMap) {
        assert(It.second.first > 0);
        unsigned Dim = It.second.first - 1;
        DEBUG(dbgs() << "Dim: " << Dim << "\nInst: " << *It.first << "\n");
        auto &DimInfo = Dimensions[Dim];
        assert(DimInfo.first == nullptr && DimInfo.second == nullptr);
        DimInfo.first = It.first;
        DimInfo.second = It.second.second;
      }

      DimPWAs.resize(Dimensions.size() + 1);

      DEBUG(dbgs() << "#DimPWAs: " << DimPWAs.size() << "\n");
      int LastDim = Dimensions.size();
      assert(!DimPWAs[LastDim]);
      DimPWAs[LastDim] = PWA;

      for (int Dim = 0; Dim < LastDim; Dim++) {
        DEBUG(dbgs() << "Dim: " << Dim << "\n");
        auto &DimInfo = Dimensions[Dim];
        assert(DimInfo.first && DimInfo.second);

        PVId PId = PI.getParameterId(*DimInfo.first);
        PVAff &LastPWA = DimPWAs[LastDim - Dim];
        DEBUG(dbgs() << "LastPWA: " << LastPWA << "\n");

        PVAff Coeff = LastPWA.getParameterCoeff(PId);
        DEBUG(dbgs() << "Coeff " << Coeff << "\n");
        assert(Coeff && "TODO: Handle missing coeff!");
        assert(Coeff.isConstant());

        PVAff &DimPWA = DimPWAs[LastDim - Dim - 1];
        assert(!DimPWA);

        DEBUG(dbgs() << "Rem: " << DimInfo.second->getPWA() << "\n";);
        DimPWA = DimInfo.second->getPWA();
        DimPWA.multiply(Coeff);

        const PVAff &Size = AI->DimensionSizes[Dim]->getPWA();
        DEBUG(dbgs() << "Size: " << Size << "\n");
        PVAff SizeFactor = LastPWA.extractFactor(Size);
        DEBUG(dbgs() << "SizeFactor: " << SizeFactor << "\n");
        if (SizeFactor) {
          DimPWA.add(SizeFactor);
          LastPWA.sub(SizeFactor.multiply(Size));
        }
        LastPWA.sub(Coeff.multiply(PVAff(PId)));

        DEBUG(dbgs() << "Dim: " << Dim << " => " << DimPWA << " [" << LastPWA
                     << "]\n");
      }

      PVMap Map(DimPWAs, PA->getId());
      Map.dropUnusedParameters();
      DEBUG(dbgs() << "MAP: " << Map << "\n");

      SmallVector<PVId, 4> Parameters;
      Map.getParameters(Parameters);

      bool IsMayAccess = false;
      for (const PVId &PId : Parameters) {
        auto *ParamValue = PId.getPayloadAs<Value *>();
        if (PI.hasScope(*ParamValue, /* Scope */ nullptr, false))
          continue;

        // TODO approximate.

        DEBUG(dbgs() << "Eliminate param " << PId << "\n");
        IsMayAccess = true;
        Map.eliminateParameter(PId);
      }
      DEBUG(dbgs() << "Final MAP: " << Map << "\n");

      if (PA->isWrite()) {
        if (IsMayAccess)
          AI->MayWriteMap.union_add(Map);
        else
          AI->MustWriteMap.union_add(Map);
      } else {
        if (IsMayAccess)
          AI->MayReadMap.union_add(Map);
        else
          AI->MustReadMap.union_add(Map);
      }
    }

    DEBUG(dbgs() << "AI Read: " << AI->MustReadMap << "\n";
          dbgs() << "AI Write: " << AI->MustWriteMap << "\n";);
  }
}

void PACCSummary::rewrite(PVRewriter<PVMap> &Rewriter) {
  for (auto AIt : *this) {
    ArrayInfo *AI = AIt.second;
    Rewriter.rewrite(AI->MayWriteMap);
    Rewriter.rewrite(AI->MustWriteMap);
    Rewriter.rewrite(AI->MayReadMap);
    Rewriter.rewrite(AI->MustReadMap);
  }
}

void PACCSummary::print(raw_ostream &OS, PolyhedralValueInfo *PVI) const {
  OS << "\nPACC summary\n";

  if (getNumUnknownReads())
    OS << "\tUnknown reads:\n";
  else
    OS << "\tUnknown reads: None\n";
  for (auto It = unknown_reads_begin(), End = unknown_reads_end(); It != End;
       It++)
    OS << "\t - " << *It << "\n";

  if (getNumUnknownWrites())
    OS << "\tUnknown writes:\n";
  else
    OS << "\tUnknown writes: None\n";
  for (auto It = unknown_writes_begin(), End = unknown_writes_end(); It != End;
       It++)
    OS << "\t - " << *It << "\n";

  std::set<PVId> ParameterSet;
  SmallVector<PVId, 8> ParameterVector;
  OS << "Array infos:\n";
  for (auto AIt : *this) {
    Value *BasePointer = AIt.first;
    ArrayInfo *AI = AIt.second;

    ParameterVector.clear();
    AI->MustWriteMap.getParameters(ParameterVector);
    ParameterSet.insert(ParameterVector.begin(), ParameterVector.end());
    ParameterVector.clear();
    AI->MustReadMap.getParameters(ParameterVector);
    ParameterSet.insert(ParameterVector.begin(), ParameterVector.end());
    ParameterVector.clear();
    AI->MayWriteMap.getParameters(ParameterVector);
    ParameterSet.insert(ParameterVector.begin(), ParameterVector.end());
    ParameterVector.clear();
    AI->MayReadMap.getParameters(ParameterVector);
    ParameterSet.insert(ParameterVector.begin(), ParameterVector.end());

    OS << "\tBase pointer: " << (BasePointer ? BasePointer->getName() : "<n/a>")
       << "\n";
    if (AI->MayReadMap)
      OS << "\t\t  MayRead: " << AI->MayReadMap << "\n";
    if (AI->MustReadMap)
      OS << "\t\t MustRead: " << AI->MustReadMap << "\n";
    if (AI->MayWriteMap)
      OS << "\t\t MayWrite: " << AI->MayWriteMap << "\n";
    if (AI->MustWriteMap)
      OS << "\t\tMustWrite: " << AI->MustWriteMap << "\n";
  }

  OS << "Referenced parameters:\n";
  if (PVI) {
    std::set<PVId> ParameterWorklist(ParameterSet);
    while (!ParameterWorklist.empty()) {
      const PVId &ParameterId = *ParameterWorklist.begin();
      ParameterWorklist.erase(ParameterId);
      if (!ParameterId.getPayload())
        continue;
      Value *Parameter = ParameterId.getPayloadAs<Value *>();
      auto *ParameterInst = dyn_cast<Instruction>(Parameter);
      if (!ParameterInst)
        continue;
      for (Value *ParameterOperand : ParameterInst->operands()) {
        const PEXP *ParameterPE = PVI->getPEXP(ParameterOperand, Scope);
        ParameterVector.clear();
        PVI->getParameters(ParameterPE, ParameterVector);
        for (const PVId NewParameterId : ParameterVector) {
          if (!ParameterSet.insert(NewParameterId).second)
            continue;
          ParameterWorklist.insert(NewParameterId);
        }
      }
    }
  }
  for (const PVId &ParameterId : ParameterSet) {
    if (!ParameterId.getPayload()) {
      OS << "\t\t - " << ParameterId.str() << " (P)\n";
      continue;
    }

    Value *Parameter = ParameterId.getPayloadAs<Value *>();
    if (auto *ArgumentParameter = dyn_cast<Argument>(Parameter)) {
      OS << "\t\t - " << ParameterId.str() << " (A)("
         << ArgumentParameter->getArgNo() << "):  " << *Parameter << "\n";
    } else if (isa<Instruction>(Parameter)) {
      OS << "\t\t - " << ParameterId.str() << " (I):" << *Parameter << "\n";
    } else if (isa<Function>(Parameter)) {
      OS << "\t\t - " << ParameterId.str() << " (F)\n";
    } else {
      OS << "\t\t - " << ParameterId.str() << " (U): " << *Parameter << "\n";
    }
  }
}

void PACCSummary::dump(PolyhedralValueInfo *PVI) const { return print(dbgs(), PVI); }

// ------------------------------------------------------------------------- //

PolyhedralAccessInfo::PolyhedralAccessInfo(PolyhedralValueInfo &PI)
    : PI(PI), PEBuilder(PI.getPolyhedralExpressionBuilder()) {}

PolyhedralAccessInfo::~PolyhedralAccessInfo() { releaseMemory(); }

void PolyhedralAccessInfo::releaseMemory() {
  DeleteContainerSeconds(AccessMap);
}

const PACC *PolyhedralAccessInfo::getAsAccess(Instruction &Inst, Value &Pointer,
                                              bool IsWrite, Loop *Scope) {
  PACC *&AccessPA = AccessMap[&Inst];
  if (AccessPA)
    return AccessPA;

  const PEXP *PointerPE = PI.getPEXP(&Pointer, Scope);

  SmallVector<Value *, 4> Parameters;
  PI.getParameters(PointerPE, Parameters);

  Value *PtrVal = nullptr;
  for (Value *Parameter : Parameters) {
    if (!Parameter->getType()->isPointerTy())
      continue;
    assert(!PtrVal && "Found multiple pointer values!");
    PtrVal = Parameter;
  }
  assert(PtrVal && "Did not find pointer value!");

  PVId PtrValId = PI.getParameterId(*PtrVal);

  const PEXP *PtrValPE = PI.getPEXP(PtrVal, Scope);
  PEXP *AccessPE = new PEXP(&Inst, nullptr);
  PEBuilder.assign(AccessPE, PointerPE, PtrValPE, PVAff::createSub);

  PACC::AccessKind AccKind = IsWrite ? PACC::AK_WRITE : PACC::AK_READ;

  const PEXP *Domain = PI.getDomainFor(Inst.getParent(), Scope);
  AccessPE->getPWA().intersectDomain(Domain->getDomain());

  AccessPA = new PACC(Pointer, *AccessPE, PtrValId, AccKind);
  return AccessPA;
}

const PACC *PolyhedralAccessInfo::getAsAccess(StoreInst *SI, Loop *Scope) {
  return getAsAccess(*SI, *SI->getPointerOperand(), true, Scope);
}

const PACC *PolyhedralAccessInfo::getAsAccess(LoadInst *LI, Loop *Scope) {
  return getAsAccess(*LI, *LI->getPointerOperand(), false, Scope);
}

const PACC *PolyhedralAccessInfo::getAsAccess(Instruction *Inst, Loop *Scope) {
  if (auto *LI = dyn_cast<LoadInst>(Inst))
    return getAsAccess(LI, Scope);
  if (auto *SI = dyn_cast<StoreInst>(Inst))
    return getAsAccess(SI, Scope);
  return nullptr;
}

PACCSummary *
PolyhedralAccessInfo::getAccessSummary(Function &F,
                                       PACCSummary::SummaryScopeKind Kind) {
  SmallVector<BasicBlock *, 32> Blocks;
  Blocks.reserve(F.size());
  for (BasicBlock &BB : F)
    Blocks.push_back(&BB);
  return getAccessSummary(Blocks, Kind);
}

PACCSummary *
PolyhedralAccessInfo::getAccessSummary(ArrayRef<BasicBlock *> Blocks,
                                       PACCSummary::SummaryScopeKind Kind,
                                       Loop *Scope) {

  PACCSummary::ContainsFuncTy ContainsFn = [=](Instruction *I) {
    return !Scope ||
           (Scope->contains(I) &&
            !(isa<PHINode>(I) && I->getParent() == Scope->getHeader()));
  };
  PACCSummary *PS = new PACCSummary(Kind, ContainsFn, Scope);
  SmallVector<const PACC *, 32> PACCs;

  for (auto &BB : Blocks) {
    for (auto &Inst : *BB) {

      if (const PACC *PA = getAsAccess(&Inst, Scope)) {
        PACCs.push_back(PA);
        continue;
      }

      if (Inst.mayReadFromMemory())
        PS->UnknownReads.push_back(&Inst);
      if (Inst.mayWriteToMemory())
        PS->UnknownWrites.push_back(&Inst);
    }
  }

  PS->finalize(PI, PACCs, Blocks.front()->getModule()->getDataLayout());
  return PS;
}

bool PolyhedralAccessInfo::hasFunctionScope(const PACC *PA) const {
  return PI.hasFunctionScope(PA->getPEXP(), false);
}

void PolyhedralAccessInfo::getParameters(const PACC *PA,
                                         SmallVectorImpl<PVId> &Values) const {
  PI.getParameters(PA->getPEXP(), Values);
}

void PolyhedralAccessInfo::getParameters(
    const PACC *PA, SmallVectorImpl<Value *> &Values) const {
  PI.getParameters(PA->getPEXP(), Values);
}

void PolyhedralAccessInfo::print(raw_ostream &OS) const {}

// ------------------------------------------------------------------------- //

char PolyhedralAccessInfoWrapperPass::ID = 0;

void PolyhedralAccessInfoWrapperPass::getAnalysisUsage(
    AnalysisUsage &AU) const {
  AU.addRequired<PolyhedralValueInfoWrapperPass>();
  AU.setPreservesAll();
}

void PolyhedralAccessInfoWrapperPass::releaseMemory() {
  delete PAI;

  F = nullptr;
  PAI = nullptr;
}

bool PolyhedralAccessInfoWrapperPass::runOnFunction(Function &F) {

  PAI = new PolyhedralAccessInfo(
      getAnalysis<PolyhedralValueInfoWrapperPass>().getPolyhedralValueInfo());

  this->F = &F;
  return false;
}

void PolyhedralAccessInfoWrapperPass::print(raw_ostream &OS,
                                            const Module *) const {
  PACCSummary *PS = PAI->getAccessSummary(*F, PACCSummary::SSK_COMPLETE);
  NVVMRewriter<PVMap, /* UseGlobalIdx */ true> CudaRewriter;
  PS->rewrite(CudaRewriter);
  PS->print(OS, &PAI->getPolyhedralValueInfo());
}

FunctionPass *llvm::createPolyhedralAccessInfoWrapperPass() {
  return new PolyhedralAccessInfoWrapperPass();
}

void PolyhedralAccessInfoWrapperPass::dump() const {
  return print(dbgs(), nullptr);
}

AnalysisKey PolyhedralAccessInfoAnalysis::Key;

PolyhedralAccessInfo
PolyhedralAccessInfoAnalysis::run(Function &F, FunctionAnalysisManager &AM) {
  auto &PI = AM.getResult<PolyhedralValueInfoAnalysis>(F);
  return PolyhedralAccessInfo(PI);
}

INITIALIZE_PASS_BEGIN(PolyhedralAccessInfoWrapperPass, "polyhedral-access-info",
                      "Polyhedral value analysis", false, true);
INITIALIZE_PASS_DEPENDENCY(PolyhedralValueInfoWrapperPass);
INITIALIZE_PASS_END(PolyhedralAccessInfoWrapperPass, "polyhedral-access-info",
                    "Polyhedral value analysis", false, true)
