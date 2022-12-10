; extends
; vim: sw=2 ts=2

; howto
; open interesting file
; :TSPlayGround
; press "o" and hack

;; sql

(function_call_expression
  function: (name) @_f_name
  (#lua-match? @_f_name "use.*Blade")  ; racktables special, like "usePreparedExecuteBlade"
  arguments:
  (arguments
    (argument
      (string
        (string_value) @sql
      )
    )
  )
)
