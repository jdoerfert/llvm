; RUN: opt %loadPolly -analyze < %s | FileCheck %s
;
; FIXME: Edit the run line and add checks!
;
; XFAIL: *
;
;    int indirect(int *A, int i) {
;      return A[A[i]];
;    }
;
;    void kernel(int lIdx, int *A, int *B, int ThreadIdx, int BlockIdx, int BlockDim) {
;      int gIdx = ThreadIdx + BlockIdx * BlockDim;
;      B[gIdx] = A[A[gIdx + lIdx]];
;    }
;
source_filename = "test/Analysis/PolyhedralInfo/AccessInfo/indirect_access.c"
target datalayout = "e-m:e-i64:64-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

define i32 @indirect(i32* %A, i32 %i) {
entry:
  %idxprom = sext i32 %i to i64
  %arrayidx = getelementptr inbounds i32, i32* %A, i64 %idxprom
  %tmp = load i32, i32* %arrayidx, align 4, !tbaa !2
  %idxprom1 = sext i32 %tmp to i64
  %arrayidx2 = getelementptr inbounds i32, i32* %A, i64 %idxprom1
  %tmp1 = load i32, i32* %arrayidx2, align 4, !tbaa !2
  ret i32 %tmp1
}

define void @kernel(i32 %lIdx, i32* %A, i32* %B, i32 %ThreadIdx, i32 %BlockIdx, i32 %BlockDim) {
entry:
  %mul = mul nsw i32 %BlockIdx, %BlockDim
  %add = add nsw i32 %mul, %ThreadIdx
  %add1 = add nsw i32 %add, %lIdx
  %idxprom = sext i32 %add1 to i64
  %arrayidx = getelementptr inbounds i32, i32* %A, i64 %idxprom
  %tmp = load i32, i32* %arrayidx, align 4, !tbaa !2
  %idxprom2 = sext i32 %tmp to i64
  %arrayidx3 = getelementptr inbounds i32, i32* %A, i64 %idxprom2
  %tmp1 = load i32, i32* %arrayidx3, align 4, !tbaa !2
  %idxprom4 = sext i32 %add to i64
  %arrayidx5 = getelementptr inbounds i32, i32* %B, i64 %idxprom4
  store i32 %tmp1, i32* %arrayidx5, align 4, !tbaa !2
  ret void
}

declare void @llvm.lifetime.start.p0i8(i64, i8* nocapture)

declare void @llvm.lifetime.end.p0i8(i64, i8* nocapture)


!llvm.module.flags = !{!0}
!llvm.ident = !{!1}

!0 = !{i32 1, !"wchar_size", i32 4}
!1 = !{!"clang version 6.0.0 (http://llvm.org/git/clang.git 13391081b0b149da4168377ceb1b4af083407d3b) (http://llvm.org/git/llvm.git 2fedc374b1431a7e9fbb46574f81a67291ef5642)"}
!2 = !{!3, !3, i64 0}
!3 = !{!"int", !4, i64 0}
!4 = !{!"omnipotent char", !5, i64 0}
!5 = !{!"Simple C/C++ TBAA"}
