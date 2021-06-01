grep(h, n, ByRef v, s = 1, e=0, d ="") {
 v =
 StringReplace, h, h, %d%, , All
 Loop
  If s := RegExMatch(h, n, c, s)
   p .= d . s, s += StrLen(c), v .= d . (e ? c%e% : c)
  Else Return, SubStr(p, 2), v := SubStr(v, 2)
}