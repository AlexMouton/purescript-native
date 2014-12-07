-----------------------------------------------------------------------------
--
-- Module      :  Language.PureScript.CodeGen.Common
-- Copyright   :  (c) Phil Freeman 2013
-- License     :  MIT
--
-- Maintainer  :  Phil Freeman <paf31@cantab.net>
-- Stability   :  experimental
-- Portability :
--
-- |
-- Common code generation utility functions
--
-----------------------------------------------------------------------------

module Language.PureScript.CodeGen.Common where

import Data.Char
import Data.List (intercalate)
import Data.Maybe (fromMaybe)
import Data.Function (on)

import qualified Data.Map as M

import Language.PureScript.Names
import Language.PureScript.Environment
import Language.PureScript.Types

-- |
-- Convert an Ident into a valid Javascript identifier:
--
--  * Alphanumeric characters are kept unmodified.
--
--  * Reserved javascript identifiers are prefixed with '$$'.
--
--  * Symbols are given a "__" suffix following their name or ordinal value.
--
identToJs :: Ident -> String
identToJs (Ident name) | nameIsJsReserved name = name ++ "__"
identToJs (Ident name) = concatMap identCharToString name
identToJs (Op op) = concatMap identCharToString op

-- |
-- Test if a string is a valid JS identifier without escaping.
--
identNeedsEscaping :: String -> Bool
identNeedsEscaping s = s /= identToJs (Ident s)

-- |"_
-- Attempts to find a human-readable name for a symbol, if none has been specified returns the
-- ordinal value.
--
identCharToString :: Char -> String
identCharToString c | isAlphaNum c = [c]
identCharToString '_' = "_symbol_"
identCharToString '.' = "dot_symbol_"
identCharToString '$' = "dollar_symbol_"
identCharToString '~' = "tilde_symbol_"
identCharToString '=' = "eq_symbol_"
identCharToString '<' = "less_symbol_"
identCharToString '>' = "greater_symbol_"
identCharToString '!' = "bang_symbol_"
identCharToString '#' = "hash_symbol_"
identCharToString '%' = "percent_symbol_"
identCharToString '^' = "up_symbol_"
identCharToString '&' = "amp_symbol_"
identCharToString '|' = "bar_symbol_"
identCharToString '*' = "times_symbol_"
identCharToString '/' = "div_symbol_"
identCharToString '+' = "plus_symbol_"
identCharToString '-' = "minus_symbol_"
identCharToString ':' = "colon_symbol_"
identCharToString '\\' = "bslash_symbol_"
identCharToString '?' = "qmark_symbol_"
identCharToString '@' = "at_symbol_"
identCharToString '\'' = "_"
identCharToString c = show (ord c) ++ "__"

-- |
-- Checks whether an identifier name is reserved in Javascript.
--
nameIsJsReserved :: String -> Bool
nameIsJsReserved name =
  name `elem` [ "abstract"
              , "arguments"
              , "boolean"
              , "break"
              , "byte"
              , "case"
              , "catch"
              , "char"
              , "class"
              , "const"
              , "continue"
              , "debugger"
              , "default"
              , "delete"
              , "do"
              , "double"
              , "else"
              , "enum"
              , "eval"
              , "export"
              , "extends"
              , "final"
              , "finally"
              , "float"
              , "for"
              , "function"
              , "goto"
              , "if"
              , "implements"
              , "import"
              , "in"
              , "instanceof"
              , "int"
              , "interface"
              , "let"
              , "long"
              , "native"
              , "new"
              , "null"
              , "package"
              , "private"
              , "protected"
              , "public"
              , "return"
              , "short"
              , "static"
              , "super"
              , "switch"
              , "synchronized"
              , "this"
              , "throw"
              , "throws"
              , "transient"
              , "try"
              , "typeof"
              , "var"
              , "void"
              , "volatile"
              , "while"
              , "with"
              , "yield" ]

moduleNameToJs :: ModuleName -> String
moduleNameToJs (ModuleName pns) = intercalate "_" (runProperName `map` pns)

-- |
-- Finds the value stored for a data constructor in the current environment.
-- This is a partial function, but if an invalid type has reached this far then
-- something has gone wrong in typechecking.
--
lookupConstructor :: Environment -> Qualified ProperName -> (DataDeclType, ProperName, Type)
lookupConstructor e ctor = fromMaybe (error "Data constructor not found") $ ctor `M.lookup` dataConstructors e

-- |
-- Checks whether a data constructor is the only constructor for that type, used
-- to simplify the check when generating code for binders.
--
isOnlyConstructor :: Environment -> Qualified ProperName -> Bool
isOnlyConstructor e ctor = numConstructors (ctor, lookupConstructor e ctor) == 1
  where
  numConstructors :: (Qualified ProperName, (DataDeclType, ProperName, Type)) -> Int
  numConstructors ty = length $ filter (((==) `on` typeConstructor) ty) $ M.toList $ dataConstructors e
  typeConstructor :: (Qualified ProperName, (DataDeclType, ProperName, Type)) -> (ModuleName, ProperName)
  typeConstructor (Qualified (Just moduleName) _, (_, tyCtor, _)) = (moduleName, tyCtor)
  typeConstructor _ = error "Invalid argument to isOnlyConstructor"

-- |
-- Checks whether a data constructor is for a newtype.
--
isNewtypeConstructor :: Environment -> Qualified ProperName -> Bool
isNewtypeConstructor e ctor = case lookupConstructor e ctor of
  (Newtype, _, _) -> True
  (Data, _, _) -> False

-- |
-- Checks the number of arguments a data constructor accepts.
--
getConstructorArity :: Environment -> Qualified ProperName -> Int
getConstructorArity e = go . (\(_, _, ctors) -> ctors) . lookupConstructor e
  where
  go :: Type -> Int
  go (TypeApp (TypeApp f _) t) | f == tyFunction = go t + 1
  go (ForAll _ ty _) = go ty
  go _ = 0

-- |
-- Checks whether a data constructor has no arguments, for example, `Nothing`.
--
isNullaryConstructor :: Environment -> Qualified ProperName -> Bool
isNullaryConstructor e = (== 0) . getConstructorArity e
