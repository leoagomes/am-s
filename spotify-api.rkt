#lang racket

(require net/http-client
         net/base64
         net/uri-codec
         json)

(require "spotify-auth.rkt")

(define spotify-host "api.spotify.com")

(define (parse-retry headers)
  (for/first ([header headers]
              #:when (string-contains? (bytes->string/utf-8 header)
                                       "Retry-After"))
    (string->number (cadr (bytes->string/utf-8 header)))))

(define retry-after 0)

(define (handle-status status headers data)
  (let ([status-code (string->number (substring (bytes->string/utf-8 status) 9 12))])
    (cond
      [(= status-code 401)
       'unauthorized]
      [(= status-code 429)
       (set! retry-after (parse-retry headers))
       'too_many_requests]
      [(>= status-code 500)
       'server_error]
      [else
       data])))

(define (request-GET uri)
  (define-values (status headers in)
    (http-sendrecv spotify-host
                   uri
                   #:ssl? #t
                   #:version "1.1"
                   #:method "GET"
                   #:headers (list (string-append "Authorization: "
                                                  spotify-token-type
                                                  " " spotify-access-token)
                                   "Accept: application/json")))
  (define data (read-json in))
  (close-input-port in)
  (handle-status status headers data))

(define (request-POST uri arguments)
  (define-values (status headers in)
    (http-sendrecv spotify-host
                   uri
                   #:ssl? #t
                   #:method "POST"
                   #:data arguments
                   #:headers (list (string-append "Authorization: "
                                                  spotify-token-type
                                                  " " spotify-access-token)
                                   "Accept: application/json")))
  (define data (read-json in))
  (close-input-port in)
  (handle-status status headers data))

(define (request-DELETE uri)
  (define-values (status headers in)
    (http-sendrecv spotify-host
                   uri
                   #:ssl? #t
                   #:method "DELETE"
                   #:headers (list (string-append "Authorization: "
                                                  spotify-token-type
                                                  " " spotify-access-token)
                                   "Accept: application/json")))
  (define data (read-json in))
  (close-input-port in)
  (handle-status status headers data))

(define (request-PUT uri)
  (define-values (status headers in)
    (http-sendrecv spotify-host
                   uri
                   #:method "PUT"
                   #:ssl? #t
                   #:headers (list (string-append "Authorization: "
                                                  spotify-token-type
                                                  " " spotify-access-token)
                                   "Accept: application/json")))
  (define data (read-json in))
  (close-input-port in)
  (handle-status status headers data))

(define (id-list->string id-list)
  (if (= (length id-list) 1)
      (car id-list)
      (string-append* (cdr (map (lambda (x) (list "," x)) id-list)))))

(define (get-album id)
  (request-GET (string-append "/v1/albums/" id)))

(define (get-albums id-list)
  (request-GET (string-append "/v1/albums?ids=" (id-list->string id-list))))

(define (get-album-tracks album-id)
  (request-GET (string-append "/v1/albums/" album-id "/tracks")))

(define (get-artist id)
  (request-GET (string-append "/v1/artists/" id)))

(define (get-artists ids)
  (request-GET (string-append "/v1/artists?ids=" (id-list->string ids))))

(define (get-artist-albums artist-id)
  (request-GET (string-append "/v1/artists/" artist-id "/albums")))

; TODO: get-artist-top-tracks
; TODO: get-artist-related-artists
; TODO: audio-analysis
; TODO: audio-features(-ids)
; TODO: browse-featured-playlists/new-releases/categories(-playlist)
; TODO: me/following

(define (save-tracks-for-user id-list)
  (request-PUT (string-append "/v1/me/tracks" "?ids=" (id-list->string id-list))))

(define (check-user-saved-tracks id-list)
  (request-GET (string-append "/v1/me/tracks/contains?ids=" (id-list->string id-list))))

(define (save-albums-for-user id-list)
  (request-PUT (string-append "/v1/me/albums?ids=" (id-list->string id-list))))

(define (get-user-saved-albums)
  (request-GET "/v1/me/albums"))

(define (check-user-saved-albums id-list)
  (request-GET (string-append "/v1/me/albums/contains?ids=" (id-list->string id-list))))

(define (search-album name artist)
  (define query-string (string-append "album:" name " artist:" artist ""))
  (request-GET (string-append "/v1/search?market=from_token&type=album&q=" (uri-encode query-string))))

(define (search-track name album artist)
  (define query-string (string-append "album:" album
                                      " name:" name
                                      " artist:" artist))
  (request-GET (string-append "/v1/search?market=from_token&type=track&q=" (uri-encode query-string))))

(provide (all-defined-out))