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

(heredoc
  identifier: (heredoc_start) @_h_name
  (#lua-match? @_h_name "SQL")
  value:
  (heredoc_body) @sql
)


(heredoc
  (comment) @value (#lua-match? @value "SQL")
  value:
  (heredoc_body) @sql
)

(array_element_initializer
  (comment) @comment (#lua-match? @comment "SQL")
  (heredoc
    (heredoc_body) @sql
  )
)

(array_element_initializer
  (comment) @comment (#lua-match? @comment "SQL")
  (string
    (string_value) @sql
  )
)

(array_element_initializer
  (comment) @comment (#lua-match? @comment "SQL")
  (encapsed_string
    (string_value) @sql
  )
)
