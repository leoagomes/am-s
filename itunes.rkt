#lang racket

(require racket/dict)
(require xml/plist)
(require racket/generic)

(define-struct it-track (id name genre album album-artist artist apple-music transfer
                            spotify-id)
  #:mutable)

(define (print-it-track itt)
  (printf "iTTrack: \"~a\", \"~a\", \"~a\"\n"
          (it-track-name itt)
          (it-track-artist itt)
          (it-track-album itt)))

(define (pl-track->it-track pl-track)
  (it-track (dict-ref pl-track "Track ID" 0)
            (dict-ref pl-track "Name" "")
            (dict-ref pl-track "Genre" "")
            (dict-ref pl-track "Album" "")
            (dict-ref pl-track "Album Artist" "")
            (dict-ref pl-track "Artist" "")
            (dict-ref pl-track "Apple Music" #f)
            #t ""))

(define-struct it-playlist (id name description tracks))

(define (pl-playlist->it-playlist pl-playlist)
  (define (extract-id track-id-entry)
    (dict-ref track-id-entry "Track ID" 0))
  (it-playlist (dict-ref pl-playlist "Playlist ID" 0)
               (dict-ref pl-playlist "Name" "")
               (dict-ref pl-playlist "Description" "")
               (map extract-id (dict-ref pl-playlist "Playlist Items" empty))))

(define (read-plist-file file-name)
  (define plist-file (open-input-file file-name))
  (define plist-data (read-plist plist-file))
  (close-input-port plist-file)
  plist-data)

(define pl-expr->value
  (match-lambda
    [(? string? s) s]
    [(list 'true) #t]
    [(list 'false) #f]
    [(list 'integer i) i]
    [(list 'real r) r]
    [(list 'date s) s] ; treat dates as strings
    [(list 'data s) s]
    [(list 'array pl-expr ...)
     (map pl-expr->value pl-expr)]
    [(list 'dict assoc-pair ...)
     (define (assoc-pair-add ap dict)
       (match-define (list 'assoc-pair string pl-expr) ap)
       (dict-set dict string (pl-expr->value pl-expr)))
     (foldl assoc-pair-add empty assoc-pair)]))

(define (get-track-dict itdata)
  (dict-ref itdata "Tracks" empty))

(define (get-playlist-dict itdata)
  (dict-ref itdata "Playlists" empty))

(define (make-ittrack-dict track-dict)
  (map (lambda (pl-track-entry)
         (define track (pl-track->it-track (cdr pl-track-entry)))
         (cons (it-track-id track) track))
       track-dict))

(define (make-itplaylist-list pl-playlist-list)
  (map pl-playlist->it-playlist pl-playlist-list))
  

(provide (all-defined-out))