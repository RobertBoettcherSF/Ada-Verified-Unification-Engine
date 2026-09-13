# Ada Verified Unification Engine

## Project Overview
This repository provides an Ada 2023 implementation of a symbolic Unification Engine designed for high-assurance reasoning architectures. Syntactic Unification serves as the shared algorithmic core between deductive database query planners and automated SMT theorem provers, computing the Most General Unifier (MGU) across first-order symbolic terms comprising Variables, Constants, and Functions. This implementation explicitly incorporates the strict Occurs-Check safeguard to prevent infinite recursive cycles and invalid cyclic substitutions (such as attempting to unify X with f(X)).

## Features
* Strongly Typed Domain: Isolates logical variable types from constants and function symbols, enforcing structural invariants at compile-time.
* Most General Unifier (MGU): Recursively traverses abstract syntax trees to determine consistent variable substitution maps.
* Strict Occurs-Check: Inspects recursive variable presence to actively prevent circular bindings and infinite loops.
* Substitution Application: Fully resolves terms by chaining and flattening multi-step variable bindings.
* Subprogram Contracts: Includes Pre and Post aspects on public subprograms to establish a verified baseline for formal SPARK analysis.

## Usage
Build and execute the standalone test executable using the provided Makefile:

```
make test
```

Expected output:
```
Running tests...
TEST 1 -- Term Constructors
  PASS -- 1.1 Variable construction
  PASS -- 1.2 Constant construction
  PASS -- 1.3 Function construction
TEST 2 -- Environment Management
  PASS -- 2.1 Clear ensures null bindings
  PASS -- 2.2 Environment strictly cleared
...
=== 32 passed, 0 failed ===
```

## Testing
The test suite in `tests.adb` validates four distinct categories:
* Functional Correctness: Validates term construction, basic constant unification, and nested function tree unifications.
* Recursive Resolution: Verifies chaining behavior across multiple dependent variable substitutions.
* Invariant Protection (Occurs-Check): Exercises cyclical terms to guarantee that infinite recursion is detected and rejected.
* Edge Cases and Errors: Verifies behavior on empty inputs, null pointers, and type-bound constraint checks.

## Building
* Prerequisites: GNAT (GNU Ada Translator) compiler and Make build tool.
* Ada Version: Ada 2023 (ISO/IEC 8652:2023). Build scripts configure `-gnat2022` and `-gnatwa` flags to enforce clean compilation with zero warnings.
