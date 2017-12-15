//===-- PolyhedralValueInfo.cpp  - Polyhedral value analysis ----*- C++ -*-===//
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

#include "llvm/Analysis/PolyhedralValueInfo.h"

#include "llvm/ADT/Statistic.h"
#include "llvm/Analysis/Passes.h"
#include "llvm/Analysis/PolyhedralExpressionBuilder.h"
#include "llvm/IR/Operator.h"
#include "llvm/Pass.h"
#include "llvm/Support/Debug.h"
#include "llvm/Support/raw_ostream.h"

#include <cassert>

using namespace llvm;

#define DEBUG_TYPE "polyhedral-value-info"

static cl::opt<bool> PVIDisable("pvi-disable", cl::init(false), cl::Hidden,
                                cl::desc("Disable PVI."));

raw_ostream &llvm::operator<<(raw_ostream &OS, PEXP::ExpressionKind Kind) {
  switch (Kind) {
  case PEXP::EK_NONE:
    return OS << "NONE";
  case PEXP::EK_INTEGER:
    return OS << "INTEGER";
  case PEXP::EK_DOMAIN:
    return OS << "DOMAIN";
  case PEXP::EK_UNKNOWN_VALUE:
    return OS << "UNKNOWN";
  case PEXP::EK_NON_AFFINE:
    return OS << "NON AFFINE";
  default:
    llvm_unreachable("Unknown polyhedral expression kind");
  }
}

PEXP *PEXP::setDomain(const PVSet &Domain, bool Overwrite) {
  assert((!PWA || Overwrite) && "PWA already initialized");
  DEBUG(dbgs() << "SetDomain: " << Domain << " for " << Val->getName() << "\n");
  if (Domain.isComplex()) {
    DEBUG(dbgs() << "Domain too complex!\n");
    return invalidate();
  }

  setKind(PEXP::EK_DOMAIN);
  PWA = PVAff(Domain, 1);
  PWA.dropUnusedParameters();
  if (!InvalidDomain)
    InvalidDomain = PVSet::empty(PWA);

  if (!KnownDomain)
    KnownDomain = PVSet::universe(PWA);
  else
    PWA.simplify(KnownDomain);

  // Sanity check
  assert(KnownDomain.getNumInputDimensions() == PWA.getNumInputDimensions());
  assert(InvalidDomain.getNumInputDimensions() == PWA.getNumInputDimensions());

  return this;
}

void PEXP::print(raw_ostream &OS) const {
  OS << PWA << " [" << (getValue() ? getValue()->getName() : "<none>") << "] ["
     << getKind()
     << "] [Scope: " << (getScope() ? getScope()->getName() : "<max>") << "]";
  if (!InvalidDomain.isEmpty())
    OS << " [ID: " << InvalidDomain << "]";
  if (!KnownDomain.isUniverse())
    OS << " [KD: " << KnownDomain << "]";
}
void PEXP::dump() const { print(dbgs()); }

raw_ostream &llvm::operator<<(raw_ostream &OS, const PEXP *PE) {
  if (PE)
    OS << *PE;
  else
    OS << "<null>";
  return OS;
}

raw_ostream &llvm::operator<<(raw_ostream &OS, const PEXP &PE) {
  PE.print(OS);
  return OS;
}

PEXP &PEXP::operator=(const PEXP &PE) {
  Kind = PE.Kind;
  PWA = PE.getPWA();
  InvalidDomain = PE.getInvalidDomain();
  KnownDomain = PE.getKnownDomain();

  // Sanity check
  assert(!KnownDomain || KnownDomain.getNumInputDimensions() == PWA.getNumInputDimensions());
  assert(!InvalidDomain || InvalidDomain.getNumInputDimensions() == PWA.getNumInputDimensions());

  return *this;
}

PEXP &PEXP::operator=(PEXP &&PE) {
  std::swap(Kind, PE.Kind);
  std::swap(PWA, PE.PWA);
  std::swap(InvalidDomain, PE.InvalidDomain);
  std::swap(KnownDomain, PE.KnownDomain);

  // Sanity check
  assert(!KnownDomain ||
         KnownDomain.getNumInputDimensions() == PWA.getNumInputDimensions());
  assert(!InvalidDomain ||
         InvalidDomain.getNumInputDimensions() == PWA.getNumInputDimensions());

  return *this;
}

void PEXP::addInvalidDomain(const PVSet &ID) {
  DEBUG(dbgs() << " ID increase: " << ID << " for " << getValue()->getName()
               << "\n");
  InvalidDomain.unify(ID);
  if (InvalidDomain.isUniverse()) {
    DEBUG(errs() << " => invalid domain is the universe domain. Invalidate!\n");
    invalidate();
  }
  if (InvalidDomain.isComplex()) {
    DEBUG(errs() << " => invalid domain is too complex. Invalidate!\n");
    invalidate();
  }

  // Sanity check
  assert(!KnownDomain || !PWA ||
         KnownDomain.getNumInputDimensions() == PWA.getNumInputDimensions());
  assert(!InvalidDomain || !PWA ||
         InvalidDomain.getNumInputDimensions() == PWA.getNumInputDimensions());
  assert(!KnownDomain || !InvalidDomain ||
         KnownDomain.getNumInputDimensions() ==
             InvalidDomain.getNumInputDimensions());
}

void PEXP::addKnownDomain(const PVSet &KD) {
  DEBUG(dbgs() << " KD increase: " << KD << " for " << getValue()->getName()
               << "\n");
  KnownDomain.intersect(KD);
  if (KnownDomain.isComplex()) {
    DEBUG(errs() << " => known domain is too complex. Drop it!\n");
    KnownDomain = PVSet::universe(KnownDomain);
  }
  PWA.simplify(KnownDomain);
  InvalidDomain.simplify(KD);

  // Sanity check
  assert(!KnownDomain || !PWA ||
         KnownDomain.getNumInputDimensions() == PWA.getNumInputDimensions());
  assert(!InvalidDomain || !PWA ||
         InvalidDomain.getNumInputDimensions() == PWA.getNumInputDimensions());
  assert(!KnownDomain || !InvalidDomain ||
         KnownDomain.getNumInputDimensions() ==
             InvalidDomain.getNumInputDimensions());
}

PEXP *PEXP::invalidate() {
  Kind = PEXP::EK_NON_AFFINE;
  PWA = PVAff();
  return this;
}

void PEXP::adjustInvalidAndKnownDomain() {
  auto *ITy = cast<IntegerType>(getValue()->getType());
  unsigned BitWidth = ITy->getBitWidth();
  assert(BitWidth > 0 && BitWidth <= 64);
  int64_t LowerBound = -1 * (1 << (BitWidth - 1));
  int64_t UpperBound = (1 << (BitWidth - 1)) - 1;

  PVAff LowerPWA(getDomain(), LowerBound);
  PVAff UpperPWA(getDomain(), UpperBound);

  auto *OVBinOp = cast<OverflowingBinaryOperator>(getValue());
  bool HasNSW = OVBinOp->hasNoSignedWrap();

  const PVAff &PWA = getPWA();
  if (HasNSW) {
    PVSet BoundedDomain = PWA.getGreaterEqualDomain(LowerPWA).intersect(
        PWA.getLessEqualDomain(UpperPWA));

    KnownDomain.intersect(BoundedDomain);
  } else {
    PVSet BoundedDomain = LowerPWA.getGreaterEqualDomain(PWA).unify(
        UpperPWA.getLessEqualDomain(PWA));

    InvalidDomain.unify(BoundedDomain);
  }

  // Sanity check
  assert(!KnownDomain || KnownDomain.getNumInputDimensions() == PWA.getNumInputDimensions());
  assert(!InvalidDomain || InvalidDomain.getNumInputDimensions() == PWA.getNumInputDimensions());
}

// ------------------------------------------------------------------------- //

PolyhedralValueInfoCache::~PolyhedralValueInfoCache() {
  DeleteContainerSeconds(LoopMap);
  DeleteContainerSeconds(ValueMap);
  DeleteContainerSeconds(DomainMap);
  ParameterMap.clear();
}

std::string PolyhedralValueInfoCache::getParameterNameForValue(Value &V) {
  if (IntrinsicInst *Intr = dyn_cast<IntrinsicInst>(&V)) {
    switch (Intr->getIntrinsicID()) {
    case Intrinsic::nvvm_read_ptx_sreg_tid_x:
      return "nvvm_tid_x";
    case Intrinsic::nvvm_read_ptx_sreg_tid_y:
      return "nvvm_tid_y";
    case Intrinsic::nvvm_read_ptx_sreg_tid_z:
      return "nvvm_tid_z";
    case Intrinsic::nvvm_read_ptx_sreg_tid_w:
      return "nvvm_tid_w";
    default:
      break;
    }
  }

  if (V.hasName())
    return V.getName().str();
  return "p" + std::to_string(ParameterMap.size());
}

PVId PolyhedralValueInfoCache::getParameterId(Value &V, const PVCtx &Ctx) {
  PVId &Id = ParameterMap[&V];
  if (Id)
    return Id;

  std::string ParameterName = getParameterNameForValue(V);
  ParameterName = PVBase::getIslCompatibleName("", ParameterName, "");
  DEBUG(dbgs() << "NEW PARAM: " << V << " ::: " << ParameterName << "\n";);
  Id = PVId(Ctx, ParameterName, &V);

  return Id;
}

// ------------------------------------------------------------------------- //

// ------------------------------------------------------------------------- //

PolyhedralValueInfo::PolyhedralValueInfo(PVCtx Ctx, LoopInfo &LI)
    : Ctx(Ctx), LI(LI), PEBuilder(new PolyhedralExpressionBuilder(*this)) {
}

PolyhedralValueInfo::~PolyhedralValueInfo() { delete PEBuilder; }

const PEXP *PolyhedralValueInfo::getPEXP(Value *V, Loop *Scope) const {
  PEBuilder->setScope(Scope);
  return PEBuilder->visit(*V);
}

const PEXP *PolyhedralValueInfo::getDomainFor(BasicBlock *BB,
                                              Loop *Scope) const {
  PEBuilder->setScope(Scope);
  return PEBuilder->getDomain(*BB);
}

const PEXP *PolyhedralValueInfo::getBackedgeTakenCount(const Loop &L,
                                                       Loop *Scope) const {
  if (PVIDisable)
    return nullptr;
  PEBuilder->setScope(Scope);
  return PEBuilder->getBackedgeTakenCount(L);
}

PVId PolyhedralValueInfo::getParameterId(Value &V) const {
  return PEBuilder->getParameterId(V);
}

bool PolyhedralValueInfo::isUnknown(const PEXP *PE) const {
  return PE->Kind == PEXP::EK_UNKNOWN_VALUE;
}

bool PolyhedralValueInfo::isInteger(const PEXP *PE) const {
  return PE->Kind == PEXP::EK_INTEGER;
}

bool PolyhedralValueInfo::isConstant(const PEXP *PE) const {
  return isInteger(PE) && PE->PWA.getNumPieces() == 1;
}

bool PolyhedralValueInfo::isAffine(const PEXP *PE) const {
  return PE->Kind != PEXP::EK_NON_AFFINE && PE->isInitialized();
}

bool PolyhedralValueInfo::isNonAffine(const PEXP *PE) const {
  return PE->Kind == PEXP::EK_NON_AFFINE;
}

bool PolyhedralValueInfo::isVaryingInScope(Instruction &I, Loop *Scope,
                                           bool Strict) const {
  if (Scope && !Scope->contains(&I))
    return false;
  if (Strict)
    return true;
  if (I.mayReadFromMemory())
    return true;

  Loop *L = nullptr;
  if (auto *PHI = dyn_cast<PHINode>(&I)) {
    if (Scope && PHI->getParent() == Scope->getHeader())
      return false;
    L = LI.isLoopHeader(PHI->getParent()) ? LI.getLoopFor(PHI->getParent()) : L;
    if (L && (!Scope || Scope->contains(L)))
      return true;
  }

  for (Value *Op : I.operands())
    if (auto *OpI = dyn_cast<Instruction>(Op)) {
      if (L && L->contains(OpI))
        continue;
      if (isVaryingInScope(*OpI, Scope, Strict))
        return true;
    }
  return false;
}

bool PolyhedralValueInfo::hasScope(Value &V, Loop *Scope,
                                   bool Strict) const {
  auto *I = dyn_cast<Instruction>(&V);
  if (!I || !isVaryingInScope(*I, Scope, Strict))
    return true;

  DEBUG(dbgs() << "Value " << V << " does not have scope "
               << (Scope ? Scope->getName() : "<max>") << "\n");
  return false;
}

bool PolyhedralValueInfo::hasScope(const PEXP *PE, Loop *Scope,
                                   bool Strict) const {

  SmallVector<Value *, 4> Values;
  getParameters(PE, Values);
  for (Value *V : Values)
    if (!hasScope(*V, Scope, Strict))
      return false;
  return true;
}

unsigned PolyhedralValueInfo::getNumPieces(const PEXP *PE) const {
  return PE->getPWA().getNumPieces();
}

bool PolyhedralValueInfo::isAlwaysValid(const PEXP *PE) const {
  return PE->getInvalidDomain().isEmpty();
}

bool PolyhedralValueInfo::mayBeInfinite(Loop &L) const {
  if (PVIDisable)
    return true;
  const PEXP *HeaderBBPE = getDomainFor(L.getHeader());
  if (!isAffine(HeaderBBPE))
    return true;

  assert(HeaderBBPE->getDomain().isBounded());

  const PVSet &InvDom = HeaderBBPE->getInvalidDomain();
  return !InvDom.isBounded();
}

void PolyhedralValueInfo::getParameters(const PEXP *PE,
                                        SmallVectorImpl<PVId> &Values) const {
  const PVAff &PWA = PE->getPWA();
  PWA.getParameters(Values);
}

void PolyhedralValueInfo::getParameters(
    const PEXP *PE, SmallVectorImpl<Value *> &Values) const {
  const PVAff &PWA = PE->getPWA();
  PWA.getParameters(Values);
}

bool PolyhedralValueInfo::isKnownToHold(Value *LHS, Value *RHS,
                                        ICmpInst::Predicate Pred,
                                        Instruction *IP, Loop *Scope) {
  const PEXP *LHSPE = getPEXP(LHS, Scope);
  if (isNonAffine(LHSPE))
    return false;

  const PEXP *RHSPE = getPEXP(RHS, Scope);
  if (isNonAffine(RHSPE))
    return false;

  const PEXP *IPDomPE = IP ? getDomainFor(IP->getParent(), Scope) : nullptr;
  if (IP && (isNonAffine(IPDomPE) || !IPDomPE->getInvalidDomain().isEmpty()))
    return false;

  PVSet LHSInvDom = LHSPE->getInvalidDomain();
  PVSet RHSInvDom = RHSPE->getInvalidDomain();
  if (IPDomPE) {
    LHSInvDom.intersect(IPDomPE->getDomain());
    RHSInvDom.intersect(IPDomPE->getDomain());
  }

  if (!LHSInvDom.isEmpty() || !RHSInvDom.isEmpty())
    return false;

  PVAff LHSAff = LHSPE->getPWA();
  PVAff RHSAff = RHSPE->getPWA();

  if (IPDomPE) {
    LHSAff.intersectDomain(IPDomPE->getDomain());
    RHSAff.intersectDomain(IPDomPE->getDomain());
  }

  auto FalseDomain = PVAff::buildConditionSet(
      ICmpInst::getInversePredicate(Pred), LHSAff, RHSAff);
  return FalseDomain.isEmpty();
}

void PolyhedralValueInfo::print(raw_ostream &OS) const {}

// ------------------------------------------------------------------------- //

char PolyhedralValueInfoWrapperPass::ID = 0;

void PolyhedralValueInfoWrapperPass::getAnalysisUsage(AnalysisUsage &AU) const {
  AU.setPreservesAll();
  AU.addRequiredTransitive<LoopInfoWrapperPass>();
}

void PolyhedralValueInfoWrapperPass::releaseMemory() {
  //F = nullptr;
  //delete PI;
  //PI = nullptr;
}

bool PolyhedralValueInfoWrapperPass::runOnFunction(Function &F) {

  auto &LI = getAnalysis<LoopInfoWrapperPass>().getLoopInfo();

  delete PI;
  PI = new PolyhedralValueInfo(Ctx, LI);

  this->F = &F;

  return false;
}

void PolyhedralValueInfoWrapperPass::print(raw_ostream &OS,
                                           const Module *) const {
  PI->print(OS);

  if (!F)
    return;

  PolyhedralValueInfoWrapperPass &PIWP =
      *const_cast<PolyhedralValueInfoWrapperPass *>(this);
  LoopInfo &LI = getAnalysis<LoopInfoWrapperPass>().getLoopInfo();

  SmallVector<Loop *, 8> LastLoops;
  for (auto &BB : *PIWP.F) {
    LastLoops.clear();
    Loop *Scope = LI.getLoopFor(&BB);
    do {
      PIWP.PI->getDomainFor(&BB, Scope);
      for (auto &Inst : BB)
        if (!Inst.getType()->isVoidTy())
          PIWP.PI->getPEXP(&Inst, Scope);
      if (!Scope)
        break;
      LastLoops.push_back(Scope);
      Scope = Scope->getParentLoop();
      for (Loop *L : LastLoops)
        PIWP.PI->getBackedgeTakenCount(*L, Scope);
    } while (true);
  }

  for (Loop *L : LI.getLoopsInPreorder()) {
    Loop *Scope = L->getParentLoop();
    do {
      OS << "Scope: " << (Scope ? Scope->getName() : "<none>") << "\n";
      const PEXP *PE = PIWP.PI->getBackedgeTakenCount(*L, Scope);
      OS << "back edge taken count of " << L->getName() << "\n";
      OS << "\t => " << PE << "\n";
      if (!Scope)
        break;
      Scope = Scope->getParentLoop();
    } while (true);
  }

  for (auto &BB : *PIWP.F) {
    Loop *Scope, *L;
    Scope = L = LI.getLoopFor(&BB);

    do {
      const PEXP *PE = PIWP.PI->getDomainFor(&BB, Scope);
      OS << "Domain of " << BB.getName() << ":\n";
      OS << "\t => " << PE << "\n";
      for (auto &Inst : BB) {
        if (Inst.getType()->isVoidTy()) {
          OS << "\tValue of " << Inst << ":\n";
          OS << "\t\t => void type!\n";
          continue;
        }
        const PEXP *PE = PIWP.PI->getPEXP(&Inst, Scope);
        OS << "\tValue of " << Inst << ":\n";
        OS << "\t\t => " << PE << "\n";
        SmallVector<Value *, 4> Values;
        PIWP.PI->getParameters(PE, Values);
        if (Values.empty())
          continue;
        OS << "\t\t\tParams:\n";
        for (Value *Val : Values)
          OS << "\t\t\t - " << *Val << "\n";
      }

      if (!Scope)
        break;
      Scope = Scope->getParentLoop();
    } while (true);
  }
}

FunctionPass *llvm::createPolyhedralValueInfoWrapperPass() {
  return new PolyhedralValueInfoWrapperPass();
}

void PolyhedralValueInfoWrapperPass::dump() const {
  return print(dbgs(), nullptr);
}

AnalysisKey PolyhedralValueInfoAnalysis::Key;

PolyhedralValueInfo
PolyhedralValueInfoAnalysis::run(Function &F, FunctionAnalysisManager &AM) {
  auto &LI = AM.getResult<LoopAnalysis>(F);
  return PolyhedralValueInfo(Ctx, LI);
}

INITIALIZE_PASS_BEGIN(PolyhedralValueInfoWrapperPass, "polyhedral-value-info",
                      "Polyhedral value analysis", false, true);
INITIALIZE_PASS_DEPENDENCY(LoopInfoWrapperPass);
INITIALIZE_PASS_END(PolyhedralValueInfoWrapperPass, "polyhedral-value-info",
                    "Polyhedral value analysis", false, true)
