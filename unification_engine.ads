package Unification_Engine
  with SPARK_Mode => On -- Explicitly documenting the intent for formal verification
is
   -- Strong typing: Restrict variable names to lowercase alphabet to distinguish from constants/functions
   subtype Var_Name is Character range 'a' .. 'z';

   type Term_Kind is (Is_Variable, Is_Constant, Is_Function);

   -- Forward declaration for recursive Term type
   type Term_Node (Kind : Term_Kind := Is_Constant);
   type Term is access all Term_Node;

   type Term_Node (Kind : Term_Kind := Is_Constant) is record
      Name : Character;
      case Kind is
         when Is_Variable | Is_Constant => null;
         when Is_Function =>
            Left  : Term;
            Right : Term;
      end case;
   end record;

   -- A Substitution environment maps variables to terms
   type Substitution_Map is array (Var_Name) of Term;
   type Substitution is record
      Bindings : Substitution_Map := (others => null);
   end record;

   -- =========================================================================
   -- Term Constructors
   -- =========================================================================

   function Make_Variable (Name : Var_Name) return Term
     with Post => Make_Variable'Result /= null and then Make_Variable'Result.Kind = Is_Variable;

   function Make_Constant (Name : Character) return Term
     with Post => Make_Constant'Result /= null and then Make_Constant'Result.Kind = Is_Constant;

   function Make_Function (Name : Character; Left, Right : Term) return Term
     with Post => Make_Function'Result /= null and then Make_Function'Result.Kind = Is_Function;

   -- =========================================================================
   -- Core Engine API
   -- =========================================================================

   -- Unifies T1 and T2, populating Env with the most general unifier (MGU).
   -- Success is True if they unify, False otherwise (e.g. constant mismatch, occurs check failure).
   procedure Unify (T1, T2 : Term; Env : in out Substitution; Success : out Boolean);

   -- Evaluates whether the variable V occurs anywhere within the term T under the current environment.
   -- This prevents cyclical bindings like X = f(X).
   function Occurs_Check (V : Var_Name; T : Term; Env : Substitution) return Boolean;

   -- Fully resolves a term by applying all bindings currently in the substitution environment.
   function Apply_Substitution (T : Term; Env : Substitution) return Term;

   -- Helper to reset the unification environment for fresh queries.
   procedure Clear (Env : out Substitution);

end Unification_Engine;
