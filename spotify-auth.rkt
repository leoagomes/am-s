#lang racket

(require net/http-client
         net/base64
         net/uri-codec
         net/sendurl
         json)

(require "spotify-response-server.rkt")

(define client-id "")
(define client-secret "")
(define callback-url "YOUR CALLBACK_URL HERE")

(define spotify-auth-data null)
(define spotify-access-token null)
(define spotify-token-type null)

(define spotify-auth-url
  (string-append "https://accounts.spotify.com/authorize/?client_id="
                 client-id
                 "&response_type=code"
                 "&redirect_uri=" (uri-encode callback-url)
                 "&scope=" (uri-encode "playlist-modify-private user-library-modify user-read-private")
                 "&show_dialog=false"))

(define (open-spotify-auth-url)
  (send-url spotify-auth-url))

(define (exchange-code-for-token user-code)
  (define-values (status headers in)
    (http-sendrecv "accounts.spotify.com"
                   "/api/token"
                   #:ssl? #t
                   #:method "POST"
                   #:headers (list "Content-Type: application/x-www-form-urlencoded")
                   #:data (string-append "grant_type=authorization_code"
                                         "&code=" user-code
                                         "&redirect_uri=" (uri-encode callback-url)
                                         "&client_id=" client-id
                                         "&client_secret=" client-secret)))
  (define data (read-json in))
  (close-input-port in)
  data)

(define (spotify-do-auth)
  (define spotify-callback-server (run-spotify-cb-server))
  (open-spotify-auth-url)

  (semaphore-wait auth-code-semaphore)
  (kill-thread spotify-callback-server)

  (set! spotify-auth-data (exchange-code-for-token spotify-user-code))
  (set! spotify-access-token (dict-ref spotify-auth-data 'access_token null))
  (set! spotify-token-type (dict-ref spotify-auth-data 'token_type null))
  (void))


(define (spotify-refresh-token)
  (define-values (status headers in)
    (http-sendrecv "accounts.spotify.com"
                   "/api/token"
                   #:ssl? #t
                   #:method "POST"
                   #:headers (list "Content-Type: application/x-www-form-urlencoded")
                   #:data (string-append "grant_type=refresh_token"
                                         "&refresh_token=" (dict-ref spotify-auth-data 'refresh_token)
                                         "&client_id=" client-id
                                         "&client_secret" client-secret)))
  (define data (read-json in))
  (close-input-port in)

  (set! spotify-auth-data (exchange-code-for-token spotify-user-code))
  (set! spotify-access-token (dict-ref spotify-auth-data 'access_token null))
  (set! spotify-token-type (dict-ref spotify-auth-data 'token_type null))
  (void))

(provide (all-defined-out))