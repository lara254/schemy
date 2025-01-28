module Desugar where

-- I ported dr. might's desugarer from his Scheme compiler :)

import Parser (
  Exps(Exps),
  Exp(Varexp, Lambda, Let, Application, Letrec, Set, Begin, If, DefineProc, Cond),
  Binding(Binding),
  Var(Var),
  Cnd(Cnd, Else),
  lexer,
  toAst
  )

desugar :: [Exp] -> [Exp]
desugar [] = []
desugar (x:xs) =
  desugar' x : rest
  where
    rest = desugar xs
    
desugar' :: Exp -> Exp
desugar' (Let bindings body) =
  let vars = map getVar  bindings in
    let args = map getExp bindings in
      let op = head args in
        let args' = tail args in
          desugar' (Application (Lambda vars body) args)

desugar' (Letrec bindings body) =
  let namings = map (\x -> (Binding (Varexp (getVar x)) (Varexp (Var "#f")))) bindings in
    let sets = map (\x -> (Set (Varexp (getVar x))  (getExp x))) bindings in
      desugar' (Let namings (Begin (sets ++ [body])))

desugar' (Begin exps) =
  desugar' (makeLets exps)
  where
    makeLets :: [Exp] -> Exp
    makeLets [x] = x
    makeLets (x:xs) =
      Let [(Binding (Varexp (Var "#f")) x)] e
      where
        e = makeLets xs
     
desugar' (Application exp exps) =
  Application exp' exps'
  where
    exp' = desugar' exp
    exps' = map desugar' exps

desugar' (Lambda vars body) =
  Lambda vars (desugar' body)

desugar' (Set var exp) =
  Set var (desugar' exp)

desugar' (If cnd thn els) =
  If (desugar' cnd) (desugar' thn) (desugar' els)

desugar' (DefineProc var prms exp) =
  DefineProc var prms (desugar' exp)

desugar' (Cond exps) =
  cndToIfs exps 
  
desugar' e = e

getVar :: Binding -> Var
getVar (Binding (Varexp v) e) = v

getExp :: Binding -> Exp
getExp (Binding v e) = e

cndToIfs :: [Cnd] -> Exp
cndToIfs (x:xs)   =
  case x of
    Else e ->
      e
    _ -> (If (getcnd x) (getthn x) (cndToIfs xs))

getcnd :: Cnd -> Exp
getcnd (Cnd cnd e) = cnd

getthn :: Cnd -> Exp
getthn (Cnd cnd e) = e

