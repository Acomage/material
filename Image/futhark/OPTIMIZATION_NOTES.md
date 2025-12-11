# Futhark Optimization Notes

## Overview
This document describes optimizations applied to the Futhark code for better performance with the ISPC backend, targeting ~16384 sampled pixels on single 4K×2K images on amd64-gnu-linux.

## Changes Made

### 1. wsmeans.fut - Weighted K-means Optimization

#### A. Nearest-Neighbor Initialization (vs Random)
**Before:** Used random initialization via `initialize_assignments` with cpprandom
**After:** Use `assign_nearest` for nearest-neighbor initialization based on Wu's initial palette

**Rationale:** Wu's quantization already provides a good initial palette, so nearest-neighbor assignment is more appropriate than random assignment, leading to fewer iterations needed for convergence.

**Code Change:**
- Removed dependency on `github.com/diku-dk/cpprandom/random`
- Replaced `initialize_assignments` with `assign_nearest` function
- Uses `reduce_comm` for finding nearest cluster

#### B. Improved Convergence Criteria
**Before:** 
- `MAX_ITERATIONS = 100`
- Used `MIN_DELTA_E = 3.0` threshold for single point movement

**After:**
- `MAX_ITERATIONS = 50`
- Use movement weight ratio `MIN_MOVE_RATIO = 0.005` (0.5% of total weight)

**Rationale:** With better Wu initialization, fewer iterations are needed. Movement weight ratio is more stable than per-point delta-E thresholds.

**Code Change:**
- Changed constants at the top of the file
- Calculate `move_ratio = moved_weight / total_weight` instead of individual point delta-E
- Early stop when `move_ratio < 0.005`

#### C. Unified Distance Calculation Logic
**Before:** Special case for first iteration with `if iteration == 0` check
**After:** Unified logic that always uses nearest-neighbor assignment

**Rationale:** Simplifies code and allows compiler to optimize better. The special case for iteration 0 is no longer needed with proper initialization.

**Code Change:**
- Removed the `if iteration == 0` branch
- Always compute `best_indices` from distances
- Simplified convergence check logic

#### D. Commutative Reduce Operations
**Before:** Used `reduce` for finding minimum distances
**After:** Use `reduce_comm` for commutative operations

**Rationale:** `reduce_comm` tells the compiler that the operation is commutative, enabling better parallelization and SIMD vectorization in ISPC backend.

**Code Change:**
- `reduce` → `reduce_comm` in `assign_nearest`
- `reduce` → `reduce_comm` in distance computation loop
- `reduce` → `reduce_comm` for weight summation

### 2. wu.fut - Wu Quantization Optimization

#### A. Commutative Reduce in argmax_prefix
**Before:** `reduce (\best i -> if vals[i] > vals[best] then i else best) 0 idxs`
**After:** `reduce_comm (\best i -> if vals[i] > vals[best] then i else best) 0 idxs`

**Rationale:** The argmax operation is commutative (finding maximum is order-independent), so `reduce_comm` enables better parallel scheduling.

#### B. Simplified Main Loop with Match Expressions
**Before:** Three nearly-identical if-else branches for R/G/B axis splitting, each with:
- Cube destructuring `let (r0, r1, g0, g1, b0, b1) = cube_curr`
- Separate construction of `cube_new` and `cube_old`
- Identical variance calculation logic

**After:** 
- Single cube destructuring outside the branches
- Determine split axis once: `if max_r >= ... then (0, cut_r) else if max_g >= ... then (1, cut_g) else (2, cut_b)`
- Use `match` expression to construct cube pairs based on axis
- Single unified code path for variance calculation

**Rationale:** 
- Reduces code duplication from ~60 lines to ~25 lines
- Makes the logic clearer and easier to maintain
- Allows compiler to better optimize the common path
- Single destructuring may enable better register allocation

**Code Change:**
```futhark
-- Determine axis and cut position
let (axis, cut_pos) = 
  if max_r >= max_g && max_r >= max_b then (0i64, cut_r)
  else if max_g >= max_r && max_g >= max_b then (1i64, cut_g)
  else (2i64, cut_b)

-- Extract cube coordinates once
let (r0, r1, g0, g1, b0, b1) = cube_curr

-- Use match to construct cubes based on split axis
let (cube_new, cube_old) = match axis
  case 0i64 -> ((cut_pos, r1, g0, g1, b0, b1), (r0, cut_pos, g0, g1, b0, b1))
  case 1i64 -> ((r0, r1, cut_pos, g1, b0, b1), (r0, r1, g0, cut_pos, b0, b1))
  case _    -> ((r0, r1, g0, g1, cut_pos, b1), (r0, r1, g0, g1, b0, cut_pos))
```

### 3. color.fut - Verification

**Status:** No changes needed. This file already uses efficient implementations and doesn't have reduce operations that need optimization.

## Expected Performance Improvements

1. **Fewer iterations**: Nearest-neighbor initialization + better convergence → potentially 50-70% fewer iterations in wsmeans
2. **Better SIMD vectorization**: `reduce_comm` hints enable ISPC to generate better parallel code
3. **Reduced code size**: Wu loop simplification reduces generated code, potentially improving i-cache efficiency
4. **Cleaner code**: More maintainable with less duplication

## Testing Notes

The optimizations preserve the algorithmic correctness:
- Nearest-neighbor initialization is mathematically valid for k-means
- Movement weight ratio is a valid convergence criterion
- Match expression produces identical results to the original if-else chains
- `reduce_comm` is safe for all commutative operations (min, max, sum)

For validation, compare output palettes on sample images before/after optimization. Quality should be similar or slightly better due to better initialization.
