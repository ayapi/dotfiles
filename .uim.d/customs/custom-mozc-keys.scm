(define mozc-on-key '(generic-on-key))
(define mozc-on-key? (make-key-predicate '(generic-on-key?)))
(define mozc-off-key '("zenkaku-hankaku" "F10" "Muhenkan"))
(define mozc-off-key? (make-key-predicate '("zenkaku-hankaku" "F10" "Muhenkan")))
(define mozc-kana-toggle-key '("Henkan_Mode"))
(define mozc-kana-toggle-key? (make-key-predicate '("Henkan_Mode")))
(define mozc-vi-escape-key '("escape" "<IgnoreShift><Control>[" "Muhenkan"))
(define mozc-vi-escape-key? (make-key-predicate '("escape" "<IgnoreShift><Control>[" "Muhenkan")))
