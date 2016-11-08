#lang racket

(require "itunes.rkt"
         "spotify-api.rkt")

(define-struct sp-album (id name artist tracks)
  #:mutable)

(define (get-album-ids track-list)
  (define-struct album-data (name artist)
    #:mutable)
  
  (define album-data-dict '())
  (define album-id-dict '())

  (for ([entry track-list])
    (let ([track (cdr entry)])
      (cond
        [(null? (dict-ref album-dict (it-track-album track) null))
         (set! album-data-dict
               (cons (cons (it-track-album track)
                           (album-data (it-track-album track)
                                       (it-track-album-artist track))))
               album-data-dict)])))

  (displayln album-data-dict))

(provide (all-defined-out))