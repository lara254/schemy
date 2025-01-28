{
module Parser where

import Data.Char (isSpace, isAlpha, isDigit, isAlphaNum)
}

%name toAst
%tokentype { Token }
%error { parseError }

%token
    let            { TokenLet }
    if             { TokenIf }
    quote          { TokenQuote }
    set            { TokenSet }
    lambda         { TokenLambda }
    letrec         { TokenLetrec }
    begin          { TokenBegin }
    macro          { TokenMacro }
    '('            { TokenLParen }
    ')'            { TokenRParen }
    '+'            { TokenPlus }
    '-'            { TokenMinus }
    '<'            { TokenLess }
    '>'            { TokenGreater }
    '='            { TokenEqual }
    true            { TokenTrue }
    false            { TokenFalse }
    and            { TokenAnd }
    or             { TokenOr }
    var            { TokenVar $$ }
    int            { TokenInt $$ }
    define         { TokenDefine }
    closure        { TokenClosure }
    tuple          { TokenTuple }
    tupleref       { TokenTupleRef }
    cond           { TokenCond }
    else           { TokenElse }
%%

Program : Exps { $1 }

Exp : true { Bool True }
    | false { Bool False }
    | Var { Varexp $1 }
    | int { Int $1 }
    | prim { $1 }
    | '(' let '(' bindings ')' Exp ')' { Let $4 $6 }
    | '(' if Exp Exp Exp ')' { If $3 $4 $5 }
    | '(' quote Exp ')' { Quote $3 }
    | '(' begin Exps ')' { Begin $3 }
    | '(' set Exp Exp ')' { Set $3 $4 }
    | '(' lambda '(' params ')' Exp ')' { Lambda $4 $6 }
    | '(' letrec '(' bindings ')' Exp ')' { Letrec $4 $6 }
    | '(' macro Exp Exp ')' { SchemeMacro $3 $4 }
    | '(' define '(' Var params ')' Exp ')' { DefineProc $4 $5 $7 }
    |  '(' closure Exp Exp params ')' { Closure $3 $4 $5 }
    | '(' tuple tupleparams ')'                { Tuple $3 }
    | '(' tupleref Exp Exp ')'            { TupleRef $3 $4 }
    | '(' cond cndexps ')'                { Cond $3 }
    | '(' Exp Exps ')'                    { Application $2 $3 }


Var : var { Var $1 }
Exps : Exp { [$1] }
     | Exp Exps { $1 : $2 }

prim : '(' '+' Exp Exp ')' { Prim Plus $3 $4 }
     | '(' '-' Exp Exp ')' { Prim Minus $3 $4 }
     | '(' '=' Exp Exp ')' { Prim Equal $3 $4 }
     | '(' and Exp Exp ')' { Prim And $3 $4 }
     | '(' or Exp Exp ')' { Prim Or $3 $4 }
     | '(' '<' Exp Exp ')' { Prim Less $3 $4 }
     | '(' '>' Exp Exp ')' { Prim Greater $3 $4 }

bindings : binding { [$1] }
         | bindings binding { $1 ++ [$2] }

binding : '(' Exp  Exp ')' {
    Binding $2 $3
}

cndexps : cndexp { [$1] }
       | cndexps cndexp { $1 ++ [$2] }

cndexp : '(' else Exp ')' { Else $3 }
       | '(' Exp Exp ')'  { Cnd $2 $3 }

tupleparams : Exp {[$1]}
            | tupleparams Exp { $1 ++ [$2]}

params : Var { [$1] }
       | params Var { $1 ++ [$2] }

{

parseError :: [Token] -> a
parseError _ = error "Parse error"
  
data Exp =
      Bool Bool
    | Varexp Var
    | Int Int
    | Prim Operator Exp Exp
    | Let [Binding] Exp
    | Letrec [Binding] Exp
    | If Exp Exp Exp
    | Set Exp Exp
    | Begin [Exp]
    | Quote Exp
    | Closure Exp Exp [Var]
    | DefineProc Var [Var] Exp
    | Lambda [Var] Exp
    | SchemeMacro Exp Exp
    | Tuple [Exp]
    | TupleRef Exp Exp
    | Cond [Cnd]
    | Application Exp [Exp]
  deriving (Show, Eq)

data Exps = Exps [Exp]
  
data Binding = Binding Exp Exp
  deriving (Show, Eq)

  
data Operator = Plus | Minus | And | Or | Less | Greater | Equal
  deriving (Show, Eq)

data Var = Var String
  deriving (Show, Eq, Ord)
  
data Cnd =
  Cnd Exp Exp
  | Else Exp
  deriving (Show, Eq)
  
data Token =
      TokenLet
    | TokenIf
    | TokenQuote
    | TokenSet
    | TokenLambda
    | TokenLetrec
    | TokenBegin
    | TokenMacro
    | TokenDefine
    | TokenLParen
    | TokenRParen
    | TokenPlus
    | TokenMinus
    | TokenLess
    | TokenGreater
    | TokenEqual
    | TokenTrue
    | TokenFalse
    | TokenAnd
    | TokenClosure
    | TokenTuple
    | TokenTupleRef
    | TokenOr
    | TokenCond
    | TokenInt Int
    | TokenElse
    | TokenVar String
    deriving (Show, Eq)

lexer :: String -> [Token]
lexer [] = []
lexer (c:cs)
  | isSpace c = lexer cs
  | isValidVarChar c = lexVar (c:cs)
  | isDigit c = lexNum (c:cs)
lexer ('=':cs) = TokenEqual : lexer cs
lexer ('+':cs) = TokenPlus : lexer cs
lexer ('-':cs) = TokenMinus : lexer cs
lexer ('(':cs) = TokenLParen : lexer cs
lexer (')':cs) = TokenRParen : lexer cs
lexer ('<':cs) = TokenLess : lexer cs
lexer ('>':cs) = TokenGreater : lexer cs
lexer _ = error "Unrecognized character"

isValidVarChar :: Char -> Bool
isValidVarChar c = c == '-' || c == '?' || isAlphaNum c || isAlpha c

lexNum :: String -> [Token]
lexNum cs =
  let (num, rest) = span isDigit cs
   in TokenInt (read num) : lexer rest

lexVar cs =
  case span isValidVarChar cs of
    ("let", rest)    -> TokenLet : lexer rest
    ("if", rest)     -> TokenIf : lexer rest
    ("quote", rest)  -> TokenQuote : lexer rest
    ("set", rest)    -> TokenSet : lexer rest
    ("lambda", rest) -> TokenLambda : lexer rest
    ("letrec", rest) -> TokenLetrec : lexer rest
    ("begin", rest)  -> TokenBegin : lexer rest
    ("macro", rest)  -> TokenMacro : lexer rest
    ("and", rest)    -> TokenAnd : lexer rest
    ("or", rest)     -> TokenOr : lexer rest
    ("true", rest)    -> TokenTrue : lexer rest
    ("false", rest)    -> TokenFalse : lexer rest
    ("define", rest)   -> TokenDefine : lexer rest
    ("closure", rest)   -> TokenClosure : lexer rest
    ("tuple", rest)    -> TokenTuple : lexer rest
    ("tupleref", rest) -> TokenTupleRef : lexer rest
    ("cond", rest)       -> TokenCond : lexer rest
    ("else", rest)        -> TokenElse : lexer rest
    (var, rest)      -> TokenVar var : lexer rest

main = getContents >>= print . toAst . lexer
}
