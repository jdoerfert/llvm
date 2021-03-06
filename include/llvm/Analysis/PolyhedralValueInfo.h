//===--- PolyhedralValueInfo.h -- Polyhedral value analysis -----*- C++ -*-===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
//
// Analysis to create polyhedral abstractions for values, instructions and
// iteration domains. These abstractions are symbolic, piece-wise affine
// functions with loop-iteration granularity. See the PEXP class comment for
// more information and examples.
//
//
//
// Parts of the code and ideas have been ported from the Polly [0] project.
//
// [0] http://polly.llvm.org/
//
//===----------------------------------------------------------------------===//

#ifndef POLYHEDRAL_VALUE_INFO_H
#define POLYHEDRAL_VALUE_INFO_H

#include "llvm/ADT/DenseMap.h"
#include "llvm/Analysis/LoopInfo.h"
#include "llvm/Analysis/PValue.h"
#include "llvm/IR/PassManager.h"

namespace llvm {

class Region;
class PolyhedralValueInfo;
class PolyhedralExpressionBuilder;

/// Polyhedral representation of a value (incl. basic block) defined in a scope
/// and evaluated at a certain program point. The values are expressed with
/// regards to loop iterations and symbolic in any expression outside the scope
/// as well as non-affine or dynamic expression inside of it. Thus, the scope
/// defines which loop iterations are represented explicitly and which are
/// treated as unknown but fixed.
///
/// For the value of j in following two dimensional loop nest there are three
/// different PEXP values depending on the scope.
///
/// for (i = 0; i < N; i++)
///   for (j = i; j < 2*i; j++)
///     S(i, j);
///
/// Scope    | Polyhedral representation of j   | Description
/// ----------------------------------------------------------------------------
/// j-loop   | [j] -> { []      -> [(j)] }      | Unconstrained parametric value
///          |                                  | in one iteration of the j-loop
/// i-loop   | [i] -> { [l1]    -> [(i + l1)] } | Parametric value of i plus the
///          |                                  | current loop iteration (j) of
///          |                                  | the innermost loop (here l1)
/// max/none | [] -> { [l0, l1] -> [(l0 + l1)]} | Sum of the current iterations
///          |                                  | in the i-loop and j-loop
///            /\       /\           /\
///            ||       ||           ||
///      parameters     ||          value
///                 loop iterations
///
///
/// The domain of S in the above example also depends on the scope and can be
/// one of the following:
///
/// Scope    | Polyhedral representation of the domain of S
/// ----------------------------------------------------------------------------
/// j-loop   | []  -> { []       -> [(1)] }
///          | In one fixed iteration of the j-loop S is always executed (no
///          | containts).
///          |
/// i-loop   | [i] -> { [l1]     -> [(1)] : 0 <= l1 < i }
///          | In one fixed iteration of the i-loop S is executed i times, thus
///          | l0 varies between 0 and i - 1.
///          |
/// max/none | [N] -> { [l0, l1] -> [(1)] : 0 <= l1 < l0 and l0 < N }
///          | In one execution of the whole loop nest S is executed for all
///          | iterations of the inner loop (l1) between 0 and the current
///          | iteration instance of the outer loop (l0) minus 1. The outer loop
///          | is executed N times, thus for l0 between 0 and N - 1.
///
///            /\       /\           /\         /\
///            ||       ||           ||         ||
///       parameters    ||   (fixed) value (1)  ||
///                 loop iterations   /\     constraints
///                                   ||
///                        implementation artifact
///
/// Note that loop iterations are always "normalized", thus they are expressed
/// as a range from 0 to the maximal number of iterations with a step of one.
/// The value part of the polyhedral representation will compensate for non-zero
/// initial values or non-unit strides.
///
/// If a scope loop is given, the PEXP will not contain information about any
/// expressions outside that loop. Otherwise, the PEXP will represent all
/// expressions that influence the value in question until the representation
/// would become non-affine. Instead of a non-affine (thus invalid) result the
/// non-affine part is represented as a parameter.
///
/// The user loop ... TODO
///
/// TODO: Describe invalid and known domain.
///
class PEXP {
public:
  /// The possible kinds for a polyhedral expression.
  enum ExpressionKind {
    EK_NONE,          ///<= An unspecified, not yet initialized, value.
    EK_INTEGER,       ///<= A (piece-wise defined) integer value.
    EK_UNKNOWN_VALUE, ///<= An unknown (parametric) or changing (loop iv) value.
    EK_DOMAIN,        ///<= A domain value that evaluates to one if the basic
                      ///   block is executed.
    EK_NON_AFFINE,    ///<= A non-affine, thus invalid, value.
  };

  /// Create a new, uninitialized polyhedral expression for @p Val.
  PEXP(Value *Val, Loop *Scope)
      : Kind(EK_NONE), Val(Val), Scope(Scope), UseScope(nullptr) {}

  /// Return the value this PEXP represents.
  Value *getValue() const { return Val; }

  /// Return the scope in which this PEXP is expressed.
  Loop *getScope() const { return Scope; }

  /// Return the polyhedral piece-wise affine function.
  const PVAff &getPWA() const { return PWA; }
  PVAff &getPWA() { return PWA; }

  /// Return the domain for which this PEXP is defined.
  PVSet getDomain() const { return getPWA().getDomain(); }

  /// Return the invalid domain which this PEXP is undefined.
  const PVSet &getInvalidDomain() const { return InvalidDomain; }

  /// Return the known constraints about this PEXP.
  const PVSet &getKnownDomain() const { return KnownDomain; }

  /// Return the expression kind of this PEXP.
  ExpressionKind getKind() const { return this->Kind; }

  /// Return true if this polyhedral representation has been initialized.
  bool isInitialized() const { return Kind != EK_NONE; }

  /// Print this polyhedral representation to @p OS.
  void print(raw_ostream &OS) const;

  /// Dump this polyhedral representation to the dbgs() stream.
  void dump() const;

private:
  /// Assignment and move-assignment operator.
  PEXP &operator=(PEXP &&PE);
  PEXP &operator=(const PEXP &PE);

  /// The kind of this polyhedral expression.
  ExpressionKind Kind;

  /// The llvm value that is represented by this polyhedral expression.
  Value *const Val;

  /// The scope of this polyhedral expression.
  Loop *const Scope;

  /// The use program point expressed in terms of a loop.
  Loop *const UseScope;

  /// The value represented as (p)iece-(w)ise (a)ffine function.
  PVAff PWA;

  /// The domain under which the representation is invalid.
  PVSet InvalidDomain;

  /// The domain containing known constraints.
  PVSet KnownDomain;

  /// Include the constraints in @p ID in the invalid domain.
  void addInvalidDomain(const PVSet &ID);

  /// Include the constraints in @p KD in the known domain.
  void addKnownDomain(const PVSet &KD);

  /// Assign @p Domain as the domain of this PEXP and change the kind to
  /// EK_DOMAIN.
  PEXP *setDomain(const PVSet &Domain, bool Overwrite = false);

  /// Set the expression kind to @p Kind.
  void setKind(ExpressionKind Kind) { this->Kind = Kind; }

  /// Add the overflow behaviour to the invalid (or known) domain depending on
  /// the nsw tag of the underlying computation.
  void adjustInvalidAndKnownDomain();

  /// Invalidate this PEXP.
  PEXP *invalidate();

  friend class PolyhedralValueInfo;
  friend class PolyhedralExpressionBuilder;
};


/// Analysis to create polyhedral abstractions for values, instructions and
/// iteration domains.
class PolyhedralValueInfo {
  /// The (shared) context in which the polyhedral values are build.
  PVCtx Ctx;

  /// The loop information for the function we are currently analyzing.
  LoopInfo &LI;

  /// The polyhedral expression builder.
  PolyhedralExpressionBuilder *PEBuilder;

  friend class PolyhedralExpressionBuilder;

public:
  /// Constructor
  PolyhedralValueInfo(PVCtx Ctx, LoopInfo &LI);
  PolyhedralValueInfo(PolyhedralValueInfo &&PVI)
      : Ctx(PVI.Ctx), LI(PVI.LI), PEBuilder(PVI.PEBuilder) {
    PVI.PEBuilder = nullptr;
  };

  ~PolyhedralValueInfo();

  /// Return the polyhedral expression builder used for this value info.
  PolyhedralExpressionBuilder &getPolyhedralExpressionBuilder() const {
    return *PEBuilder;
  }

  /// Return the polyhedral expression of @p V in @p Scope.
  const PEXP *getPEXP(Value *V, Loop *Scope = nullptr,
                      bool Strict = false, bool NoAlias = false) const;

  /// Return the domain of @p BB as polyhedral expression in @p Scope.
  const PEXP *getDomainFor(BasicBlock *BB, Loop *Scope = nullptr,
                           bool Strict = false, bool NoAlias = false) const;

  /// Return the backedge taken count for @p L in @p Scope.
  const PEXP *getBackedgeTakenCount(const Loop &L, Loop *Scope = nullptr,
                                    bool Strict = false, bool NoAlias = false) const;

  /// Return the internal context used.
  const PVCtx &getCtx() const { return Ctx; }

  /// Return the unique parameter id for @p V.
  PVId getParameterId(Value &V) const;

  /// Return true if @p PE represents an unknown (parametric) value.
  bool isUnknown(const PEXP *PE) const;

  /// Return true if @p PE represents an integer value.
  ///
  /// As PEXP allow for piecewise representation, integer does not necessarily
  /// mean constant. An example would be
  ///   %int = phi i32 [5, %b0], [7, %b1]
  /// which is an integer value but not a constant one.
  bool isInteger(const PEXP *PE) const;

  /// Return true if @p PE represents a constant value.
  bool isConstant(const PEXP *PE) const;

  /// Return true if @p PE represents an affine value.
  bool isAffine(const PEXP *PE) const;

  /// Return true if @p PE represents a non-affine value.
  bool isNonAffine(const PEXP *PE) const;

  /// Return true if @p I is (potentialy) varying in @p Scope.
  ///
  /// @param I      The instruction to be checked.
  /// @param Scope  The scope to be checked.
  /// @param Strict Flag to indicate that parameters cannot be in the @p Scope
  ///               even if they do not vary for one iteration of the @p Scope.
  bool isVaryingInScope(Instruction &I, const Region &RegionScope, bool Strict,
                        bool NoAlias = false) const;

  /// Return true if @p I is (potentialy) varying in @p Scope.
  ///
  /// @param I      The instruction to be checked.
  /// @param Scope  The scope to be checked.
  /// @param Strict Flag to indicate that parameters cannot be in the @p Scope
  ///               even if they do not vary for one iteration of the @p Scope.
  bool isVaryingInScope(Instruction &I, Loop *Scope, bool Strict,
                        bool NoAlias = false) const;

  /// Return true if @p V is fixed for one iteration of @p Scope. If @p Strict
  /// is set, @p V does not depend on any instructions in @p Scope, otherwise it
  /// can if the instructions have a fixed, thus unchanging, value in one
  /// iteration of @p Scope.
  bool hasScope(Value &V, const Region &RegionScope, bool Strict,
                bool NoAlias = false) const;

  /// Return true if @p V is fixed for one iteration of @p Scope. If @p Strict
  /// is set, @p V does not depend on any instructions in @p Scope, otherwise it
  /// can if the instructions have a fixed, thus unchanging, value in one
  /// iteration of @p Scope.
  bool hasScope(const PEXP *PE, const Region &RegionScope, bool Strict,
                bool NoAlias = false) const;


  /// Return true if @p V is fixed for one iteration of @p Scope. If @p Strict
  /// is set, @p V does not depend on any instructions in @p Scope, otherwise it
  /// can if the instructions have a fixed, thus unchanging, value in one
  /// iteration of @p Scope.
  bool hasScope(Value &V, Loop *Scope, bool Strict, bool NoAlias = false) const;

  /// Return true if @p PE represents a value that is fixed for one iteration of
  /// @p Scope. If @p Strict is set, @p PE is not parametric in an
  /// instruction in @p Scope, otherwise it can be if the instructions have a
  /// fixed, thus unchanging, value in one iteration of @p Scope.
  bool hasScope(const PEXP *PE, Loop *Scope, bool Strict, bool NoAlias = false) const;

  /// Return true if @p PE represents a value that is fixed for one function
  /// invocation. If @p Strict is set, @p PE is not parametric in any
  /// instruction, otherwise it can be if the instructions have a fixed,
  /// thus unchanging, value in one function invocation.
  bool hasFunctionScope(const PEXP *PE, bool Strict, bool NoAlias = false) const {
    return hasScope(PE, nullptr, Strict, NoAlias);
  }

  unsigned getNumPieces(const PEXP *PE) const;

  bool isAlwaysValid(const PEXP *PE) const;

  ///
  bool mayBeInfinite(Loop &L) const;

  /// Return the unknown ids referenced by @p PE  in @p Values.
  void getParameters(const PEXP *PE, SmallVectorImpl<PVId> &Values,
                     bool Recursive = true) const;

  /// Return the unknown values referenced by @p PE  in @p Values.
  void getParameters(const PEXP *PE, SmallVectorImpl<Value *> &Values,
                     bool Recursive = true) const;

  /// Return true if the @p Pred relation between @p LHS and @p RHS is known to
  /// hold at @p IP with regards to @p Scope.
  ///
  /// TODO: Specify constrains on @p IP wrt. @p LHS and @p RHS.
  bool isKnownToHold(Value *LHS, Value *RHS, ICmpInst::Predicate Pred,
                     Instruction *IP = nullptr, Loop *Scope = nullptr);

  /// Print some statistics to @p OS.
  void print(raw_ostream &OS) const;
};

/// Wrapper pass for PolyhedralValueInfo on a per-function basis.
class PolyhedralValueInfoWrapperPass : public FunctionPass {
  /// The (shared) context in which the polyhedral values are build.
  PVCtx Ctx;

  PolyhedralValueInfo *PI;
  Function *F;

public:
  static char ID;
  PolyhedralValueInfoWrapperPass()
      : FunctionPass(ID), PI(nullptr), F(nullptr) {}

  /// Return the PolyhedralValueInfo object for the current function.
  PolyhedralValueInfo &getPolyhedralValueInfo() {
    assert(PI);
    return *PI;
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

/// Analysis wrapper for the PolyhedralValueInfo in the new pass manager.
class PolyhedralValueInfoAnalysis
    : public AnalysisInfoMixin<PolyhedralValueInfoAnalysis> {
  friend AnalysisInfoMixin<PolyhedralValueInfoAnalysis>;
  static AnalysisKey Key;

  /// The (shared) context in which the polyhedral values are build.
  PVCtx Ctx;

public:
  /// \brief Provide the result typedef for this analysis pass.
  typedef PolyhedralValueInfo Result;

  /// \brief Run the analysis pass over a function and produce BFI.
  Result run(Function &F, FunctionAnalysisManager &AM);
};

/// Stream operators to pretty print polyhedral expressions (PEXP)
///
///{
raw_ostream &operator<<(raw_ostream &OS, PEXP::ExpressionKind Kind);
raw_ostream &operator<<(raw_ostream &OS, const PEXP *PE);
raw_ostream &operator<<(raw_ostream &OS, const PEXP &PE);
///}

} // namespace llvm
#endif
