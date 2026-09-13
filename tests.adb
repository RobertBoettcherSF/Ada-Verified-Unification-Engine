with Ada.Text_IO; use Ada.Text_IO;
with Unification_Engine; use Unification_Engine;

procedure Tests is
   Pass_Count : Natural := 0;
   Fail_Count : Natural := 0;

   procedure Check (Label : String; OK : Boolean) is
   begin
      if OK then
         Put_Line ("  PASS -- " & Label);
         Pass_Count := Pass_Count + 1;
      else
         Put_Line ("  FAIL -- " & Label);
         Fail_Count := Fail_Count + 1;
      end if;
   end Check;

   Env : Substitution;
   Success_Flag : Boolean;
   T1, T2, T3 : Term;

begin
   -- TEST 1 -- Make Term Properties
   Put_Line ("TEST 1 -- Term Constructors");
   T1 := Make_Variable ('x');
   Check ("1.1 Variable construction", T1 /= null and then T1.Kind = Is_Variable);
   T2 := Make_Constant ('C');
   Check ("1.2 Constant construction", T2 /= null and then T2.Kind = Is_Constant);
   T3 := Make_Function ('f', T1, T2);
   Check ("1.3 Function construction", T3 /= null and then T3.Kind = Is_Function);

   -- TEST 2 -- Clear Environment
   Put_Line ("TEST 2 -- Environment Management");
   Clear (Env);
   Check ("2.1 Clear ensures null bindings", Env.Bindings ('a') = null and Env.Bindings ('z') = null);
   Env.Bindings ('x') := T2;
   Clear (Env);
   Check ("2.2 Environment strictly cleared", Env.Bindings ('x') = null);

   -- TEST 3 -- Unify Identical Constants
   Put_Line ("TEST 3 -- Identical Constants");
   Clear (Env);
   Unify (Make_Constant ('A'), Make_Constant ('A'), Env, Success_Flag);
   Check ("3.1 Mismatch check passes", Success_Flag);
   Check ("3.2 Environment unchanged", Env.Bindings ('x') = null);
   
   -- TEST 4 -- Unify Different Constants
   Put_Line ("TEST 4 -- Different Constants");
   Clear (Env);
   Unify (Make_Constant ('A'), Make_Constant ('B'), Env, Success_Flag);
   Check ("4.1 Constants reject", not Success_Flag);

   -- TEST 5 -- Unify Variable and Constant
   Put_Line ("TEST 5 -- Variable & Constant Unification");
   Clear (Env);
   T1 := Make_Variable ('x');
   T2 := Make_Constant ('K');
   Unify (T1, T2, Env, Success_Flag);
   Check ("5.1 Var unifies with Const", Success_Flag);
   Check ("5.2 Environment recorded x = K", Env.Bindings ('x') = T2);

   -- TEST 6 -- Unify Bound Variable to conflicting Constant
   Put_Line ("TEST 6 -- Conflicting Bindings");
   Unify (T1, Make_Constant ('Z'), Env, Success_Flag);
   Check ("6.1 Bound x rejects new constant", not Success_Flag);

   -- TEST 7 -- Unify Identical Functions
   Put_Line ("TEST 7 -- Identical Functions");
   Clear (Env);
   T1 := Make_Function ('f', Make_Constant ('A'), Make_Constant ('B'));
   T2 := Make_Function ('f', Make_Constant ('A'), Make_Constant ('B'));
   Unify (T1, T2, Env, Success_Flag);
   Check ("7.1 Exact function match", Success_Flag);

   -- TEST 8 -- Unify Different Functions (Arity/Constant Mismatch)
   Put_Line ("TEST 8 -- Function Signature Mismatch");
   Clear (Env);
   T1 := Make_Function ('f', Make_Constant ('A'), Make_Constant ('B'));
   T2 := Make_Function ('g', Make_Constant ('A'), Make_Constant ('B'));
   Unify (T1, T2, Env, Success_Flag);
   Check ("8.1 Name mismatch fails", not Success_Flag);

   T2 := Make_Function ('f', Make_Constant ('A'), Make_Constant ('C'));
   Unify (T1, T2, Env, Success_Flag);
   Check ("8.2 Argument mismatch fails", not Success_Flag);

   -- TEST 9 -- Recursive Unification (MGU generation)
   Put_Line ("TEST 9 -- Recursive MGU Generation");
   Clear (Env);
   -- f(x, A) unifies with f(B, y) -> x=B, y=A
   T1 := Make_Function ('f', Make_Variable ('x'), Make_Constant ('A'));
   T2 := Make_Function ('f', Make_Constant ('B'), Make_Variable ('y'));
   Unify (T1, T2, Env, Success_Flag);
   Check ("9.1 Trees unified", Success_Flag);
   Check ("9.2 x bound to B", Env.Bindings ('x').Name = 'B');
   Check ("9.3 y bound to A", Env.Bindings ('y').Name = 'A');

   -- TEST 10 -- Occurs Check (Infinite Loop Prevention)
   Put_Line ("TEST 10 -- Occurs Check");
   Clear (Env);
   -- Unify x with f(x, A). Should fail occurs check.
   T1 := Make_Variable ('x');
   T2 := Make_Function ('f', T1, Make_Constant ('A'));
   Unify (T1, T2, Env, Success_Flag);
   Check ("10.1 Circular reference blocked", not Success_Flag);
   Check ("10.2 Environment remains clean", Env.Bindings ('x') = null);

   -- TEST 11 -- Apply Substitution
   Put_Line ("TEST 11 -- Substitution Application");
   Clear (Env);
   Env.Bindings ('x') := Make_Constant ('K');
   T1 := Make_Function ('h', Make_Variable ('x'), Make_Constant ('C'));
   T2 := Apply_Substitution (T1, Env);
   Check ("11.1 Tree resolved", T2 /= null and then T2.Kind = Is_Function);
   Check ("11.2 Variable substituted", T2.Left.Kind = Is_Constant and then T2.Left.Name = 'K');
   Check ("11.3 Constant preserved", T2.Right.Name = 'C');

   -- TEST 12 -- Apply Substitution (Chaining)
   Put_Line ("TEST 12 -- Substitution Application (Chained)");
   Clear (Env);
   Env.Bindings ('x') := Make_Variable ('y');
   Env.Bindings ('y') := Make_Constant ('M');
   T1 := Make_Variable ('x');
   T2 := Apply_Substitution (T1, Env);
   Check ("12.1 Chain resolved down to M", T2.Kind = Is_Constant and then T2.Name = 'M');

   -- TEST 13 -- Edge Cases
   Put_Line ("TEST 13 -- Edge Cases (Null Handling)");
   Clear (Env);
   Unify (null, null, Env, Success_Flag);
   Check ("13.1 Null unifies with Null", Success_Flag);
   Unify (Make_Constant ('A'), null, Env, Success_Flag);
   Check ("13.2 Const rejects Null", not Success_Flag);

   -- TEST 14 -- Constraint Verification
   Put_Line ("TEST 14 -- Strong Typing Exeptions");
   begin
      -- Attempting to cast an invalid char to Var_Name
      declare
         Invalid_Var : Var_Name := 'A'; -- 'A' is not in 'a' .. 'z'
         pragma Unreferenced (Invalid_Var);
      begin
         Check ("14.1 Constraint Error expected", False); -- Should not reach
      end;
   exception
      when Constraint_Error =>
         Check ("14.1 Out-of-bounds variable constrained", True);
   end;

   Put_Line ("");
   Put_Line ("=== " & Natural'Image (Pass_Count) & " passed," & Natural'Image (Fail_Count) & " failed ===");
   pragma Assert (Fail_Count = 0, "Some tests failed");
end Tests;
