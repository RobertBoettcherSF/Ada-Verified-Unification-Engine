package body Unification_Engine is

   function Make_Variable (Name : Var_Name) return Term is
   begin
      return new Term_Node'(Kind => Is_Variable, Name => Name);
   end Make_Variable;

   function Make_Constant (Name : Character) return Term is
   begin
      return new Term_Node'(Kind => Is_Constant, Name => Name);
   end Make_Constant;

   function Make_Function (Name : Character; Left, Right : Term) return Term is
   begin
      return new Term_Node'(Kind => Is_Function, Name => Name, Left => Left, Right => Right);
   end Make_Function;

   function Occurs_Check (V : Var_Name; T : Term; Env : Substitution) return Boolean is
   begin
      if T = null then
         return False;
      end if;

      case T.Kind is
         when Is_Variable =>
            if T.Name = V then
               return True;
            elsif Env.Bindings (T.Name) /= null then
               -- Recursively check the bound term
               return Occurs_Check (V, Env.Bindings (T.Name), Env);
            else
               return False;
            end if;
         when Is_Constant =>
            return False;
         when Is_Function =>
            return Occurs_Check (V, T.Left, Env) or else Occurs_Check (V, T.Right, Env);
      end case;
   end Occurs_Check;

   procedure Unify (T1, T2 : Term; Env : in out Substitution; Success : out Boolean) is
   begin
      Success := False;

      -- Base case for missing arguments or null tree branches
      if T1 = null and T2 = null then
         Success := True;
         return;
      elsif T1 = null or T2 = null then
         return;
      end if;

      -- If T1 is a bound variable, dereference and unify
      if T1.Kind = Is_Variable and then Env.Bindings (T1.Name) /= null then
         Unify (Env.Bindings (T1.Name), T2, Env, Success);
         return;
      end if;

      -- If T2 is a bound variable, dereference and unify
      if T2.Kind = Is_Variable and then Env.Bindings (T2.Name) /= null then
         Unify (T1, Env.Bindings (T2.Name), Env, Success);
         return;
      end if;

      -- Both are fully dereferenced relative to current Env
      if T1.Kind = Is_Variable then
         if T2.Kind = Is_Variable and then T1.Name = T2.Name then
            Success := True; -- X = X is trivially true
            return;
         end if;
         if Occurs_Check (T1.Name, T2, Env) then
            return; -- Infinite loop detected (Occurs Check Failed)
         end if;
         Env.Bindings (T1.Name) := T2;
         Success := True;
         return;

      elsif T2.Kind = Is_Variable then
         if Occurs_Check (T2.Name, T1, Env) then
            return; -- Infinite loop detected
         end if;
         Env.Bindings (T2.Name) := T1;
         Success := True;
         return;

      elsif T1.Kind = Is_Constant and T2.Kind = Is_Constant then
         Success := (T1.Name = T2.Name);
         return;

      elsif T1.Kind = Is_Function and T2.Kind = Is_Function then
         if T1.Name /= T2.Name then
            return; -- Function signatures do not match
         end if;

         declare
            Left_Success  : Boolean := False;
            Right_Success : Boolean := False;
         begin
            Unify (T1.Left, T2.Left, Env, Left_Success);
            if Left_Success then
               Unify (T1.Right, T2.Right, Env, Right_Success);
               Success := Right_Success;
            end if;
         end;
         return;

      else
         -- Mismatched kinds (e.g. Constant vs Function) cannot unify
         return;
      end if;
   end Unify;

   function Apply_Substitution (T : Term; Env : Substitution) return Term is
   begin
      if T = null then
         return null;
      end if;

      case T.Kind is
         when Is_Variable =>
            if Env.Bindings (T.Name) /= null then
               -- Recursively resolve chained bindings
               return Apply_Substitution (Env.Bindings (T.Name), Env);
            else
               return T;
            end if;
         when Is_Constant =>
            return T;
         when Is_Function =>
            return Make_Function (Name  => T.Name,
                                  Left  => Apply_Substitution (T.Left, Env),
                                  Right => Apply_Substitution (T.Right, Env));
      end case;
   end Apply_Substitution;

   procedure Clear (Env : out Substitution) is
   begin
      Env.Bindings := [others => null];
   end Clear;

end Unification_Engine;
