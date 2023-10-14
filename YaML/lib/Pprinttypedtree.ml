(** Copyright 2023-2024, Ilya Pankratov, Maxim Drumov *)

(** SPDX-License-Identifier: LGPL-2.1-or-later *)

open Typedtree
open Base

let get_texpr_subst =
  let rec helper subs index = function
    | TVar (_, typ) -> Pprinttypetree.get_ty_subs subs index typ
    | TLetIn (_, e1, e2, typ)
    | TBinop (_, e1, e2, typ)
    | TApp (e1, e2, typ)
    | TLetRecIn (_, e1, e2, typ) ->
      let subs, index = Pprinttypetree.get_ty_subs subs index typ in
      let subs, index = helper subs index e1 in
      helper subs index e2
    | TLet (_, e, typ) | TLetRec (_, e, typ) | TFun (_, e, typ) ->
      let subs, index = Pprinttypetree.get_ty_subs subs index typ in
      helper subs index e
    | TIfThenElse (e1, e2, e3) ->
      let subs, index = helper subs index e1 in
      let subs, index = helper subs index e2 in
      helper subs index e3
    | TConst _ -> subs, index
  in
  helper (Base.Map.empty (module Base.Int)) 0
;;

let space ppf depth = Stdlib.Format.fprintf ppf "\n%*s" (4 * depth) ""

let pp_arg subs ppf =
  let pp_ty = Pprinttypetree.pp_ty_with_subs subs in
  function
  | Arg (name, typ) -> Stdlib.Format.fprintf ppf "(%s: %a)" name pp_ty typ
;;

(* A monster that needs refactoring *)
let pp_texpr ppf texpr =
  let open Stdlib.Format in
  let subs, _ = get_texpr_subst texpr in
  let pp_ty = Pprinttypetree.pp_ty_with_subs (Some subs) in
  let pp_arg = pp_arg (Some subs) in
  let rec helper depth ppf =
    let pp = helper (depth + 1) in
    function
    | TVar (name, typ) -> fprintf ppf "(%s: %a)" name pp_ty typ
    | TBinop (op, e1, e2, typ) ->
      fprintf
        ppf
        "(%s: %a (%a%a, %a%a%a))"
        (Ast.show_bin_op op)
        pp_ty
        typ
        space
        depth
        pp
        e1
        space
        depth
        pp
        e2
        space
        (depth - 1)
    | TApp (e1, e2, typ) ->
      fprintf
        ppf
        "(TApp: %a (%a%a, %a%a%a))"
        pp_ty
        typ
        space
        depth
        pp
        e1
        space
        depth
        pp
        e2
        space
        (depth - 1)
    | TLet (name, e, typ) ->
      fprintf
        ppf
        "(TLet(%a%s: %a, %a%a%a))"
        space
        depth
        name
        pp_ty
        typ
        space
        depth
        pp
        e
        space
        (depth - 1)
    | TLetIn (name, e1, e2, typ) ->
      fprintf
        ppf
        "(TLetIn(%a%s: %a,%a%a,%a%a%a))"
        space
        depth
        name
        pp_ty
        typ
        space
        depth
        pp
        e1
        space
        depth
        pp
        e2
        space
        (depth - 1)
    | TLetRec (name, e, typ) ->
      fprintf
        ppf
        "(TLetRec(%a%s: %a, %a%a%a))"
        space
        depth
        name
        pp_ty
        typ
        space
        depth
        pp
        e
        space
        (depth - 1)
    | TLetRecIn (name, e1, e2, typ) ->
      fprintf
        ppf
        "(TLetRecIn(%a%s: %a,%a%a,%a%a%a))"
        space
        depth
        name
        pp_ty
        typ
        space
        depth
        pp
        e1
        space
        depth
        pp
        e2
        space
        (depth - 1)
    | TFun (arg, e, typ) ->
      fprintf
        ppf
        "(TFun: %a (%a%a, %a%a%a))"
        pp_ty
        typ
        space
        depth
        pp_arg
        arg
        space
        depth
        pp
        e
        space
        (depth - 1)
    | TIfThenElse (i, t, e) ->
      fprintf
        ppf
        "(TIfThenElse(%a%a, %a%a, %a%a%a))"
        space
        depth
        pp
        i
        space
        depth
        pp
        t
        space
        depth
        pp
        e
        space
        (depth - 1)
    | TConst (c, typ) -> fprintf ppf "(TConst(%s: %a))" (Ast.show_const c) pp_ty typ
  in
  helper 1 ppf texpr
;;