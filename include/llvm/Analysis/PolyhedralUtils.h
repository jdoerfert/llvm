//===--- PolyhedralUtils.h --- Polyhedral Helper Classes --------*- C++ -*-===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
//
//===----------------------------------------------------------------------===//

#ifndef POLYHEDRAL_UTILS_H
#define POLYHEDRAL_UTILS_H

#include "llvm/Analysis/PValue.h"
#include "llvm/IR/IntrinsicInst.h"

namespace llvm {

template<typename PVType, bool UseGlobalIdx = true>
struct NVVMRewriter : public PVRewriter<PVType> {
  enum NVVMDim {
    NVVMDIM_NONE,
    NVVMDIM_X,
    NVVMDIM_Y,
    NVVMDIM_Z,
    NVVMDIM_W,
  };

  static constexpr unsigned NumNVVMDims = 4;
  NVVMDim NVVMDims[NumNVVMDims] = {NVVMDIM_X, NVVMDIM_Y, NVVMDIM_Z, NVVMDIM_W};

  bool isIntrinsic(Value *V, Intrinsic::ID IntrId) {
    auto *Intr = dyn_cast<IntrinsicInst>(V);
    return Intr && Intr->getIntrinsicID() == IntrId;
  }

  NVVMDim getBlockOffsetDim(Value *V) {
    auto *Inst = dyn_cast<Instruction>(V);
    if (!Inst)
      return NVVMDIM_NONE;

    if (Inst->getOpcode() != Instruction::Mul)
      return NVVMDIM_NONE;

    Value *Op0 = Inst->getOperand(0);
    Value *Op1 = Inst->getOperand(1);

    std::pair<Intrinsic::ID, Intrinsic::ID> IdPairs[] = {
        {Intrinsic::nvvm_read_ptx_sreg_ntid_x,
         Intrinsic::nvvm_read_ptx_sreg_ctaid_x},
        {Intrinsic::nvvm_read_ptx_sreg_ntid_y,
         Intrinsic::nvvm_read_ptx_sreg_ctaid_y},
        {Intrinsic::nvvm_read_ptx_sreg_ntid_z,
         Intrinsic::nvvm_read_ptx_sreg_ctaid_z},
        {Intrinsic::nvvm_read_ptx_sreg_ntid_w,
         Intrinsic::nvvm_read_ptx_sreg_ctaid_w}};

    for (unsigned d = 0; d < NumNVVMDims; d++) {
      auto IdPair = IdPairs[d];
      if ((isIntrinsic(Op0, IdPair.first) && isIntrinsic(Op1, IdPair.second)) ||
          (isIntrinsic(Op1, IdPair.first) && isIntrinsic(Op0, IdPair.second)))
        return NVVMDims[d];
    }

    return NVVMDIM_NONE;
  }

  virtual void rewrite(PVType &Obj) override {
    SmallVector<PVId, 4> ThreadIdCallsPerDim[NumNVVMDims];

    Intrinsic::ID ThreadIdIntrinsicIds[] = {
        Intrinsic::nvvm_read_ptx_sreg_tid_x,
        Intrinsic::nvvm_read_ptx_sreg_tid_y,
        Intrinsic::nvvm_read_ptx_sreg_tid_z,
        Intrinsic::nvvm_read_ptx_sreg_tid_w};

    for (unsigned d = 0, e = Obj.getNumParameters(); d < e; d++) {
      const PVId &Id = Obj.getParameter(d);
      auto *IdValue = Id.getPayloadAs<Value *>();
      for (unsigned u = 0; u < NumNVVMDims; u++) {
        Intrinsic::ID ThreadIdIntrinsicId = ThreadIdIntrinsicIds[u];
        if (!isIntrinsic(IdValue, ThreadIdIntrinsicId))
          continue;
        ThreadIdCallsPerDim[u].push_back(Id);
        break;
      }
    }

    for (const auto &ThreadIdCalls : ThreadIdCallsPerDim) {
      while (ThreadIdCalls.size() > 1) {
        Obj.equateParameters(ThreadIdCalls[0], ThreadIdCalls[1]);
        Obj.eliminateParameter(ThreadIdCalls[1]);
      }
    }

    PVId BlockOffset[NumNVVMDims];
    for (unsigned d = 0, e = Obj.getNumParameters(); d < e; d++) {
      const PVId &Id = Obj.getParameter(d);
      auto *IdValue = Id.getPayloadAs<Value *>();

      switch (getBlockOffsetDim(IdValue)) {
      case NVVMDIM_X:
        assert(!BlockOffset[0] && "TODO: Handle multiple block "
                                               "offsets in the same "
                                               "dimension!\n");
        BlockOffset[0] = PVId(Id, "nvvm_block_offset_x", IdValue);
        Obj.setParameter(d, BlockOffset[0]);
        continue;
      case NVVMDIM_Y:
        assert(!BlockOffset[1] && "TODO: Handle multiple block "
                                               "offsets in the same "
                                               "dimension!\n");
        BlockOffset[1] = PVId(Id, "nvvm_block_offset_y", IdValue);
        Obj.setParameter(d, BlockOffset[1]);
        continue;
      case NVVMDIM_Z:
        assert(!BlockOffset[2] && "TODO: Handle multiple block "
                                               "offsets in the same "
                                               "dimension!\n");
        BlockOffset[2] = PVId(Id, "nvvm_block_offset_z", IdValue);
        Obj.setParameter(d, BlockOffset[2]);
        continue;
      case NVVMDIM_W:
        assert(!BlockOffset[3] && "TODO: Handle multiple block "
                                               "offsets in the same "
                                               "dimension!\n");
        BlockOffset[3] = PVId(Id, "nvvm_block_offset_w", IdValue);
        Obj.setParameter(d, BlockOffset[3]);
        continue;
      case NVVMDIM_NONE:
        continue;
      }
    }

    if (!UseGlobalIdx)
      return;

    for (unsigned d = 0; d < NumNVVMDims; d++) {
      if (!BlockOffset[d] || ThreadIdCallsPerDim[d].empty())
        continue;

      const PVId &ThreadId = ThreadIdCallsPerDim[d][0];
      PVId GlobalIdx = PVId(ThreadId, "nvvm_global_id_x", nullptr);
      PVAff Translator(Obj, 0, 1, ThreadId);
      Translator.add(PVAff(Obj, 0, 1, BlockOffset[d]));
      Translator.equateInputDim(0, GlobalIdx);
      Translator.setInputId(Obj.getOutputId());
      Obj = Obj.preimage(Translator);
    }

  }

private:
};


} // namespace llvm
#endif
