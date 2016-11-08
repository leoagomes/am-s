#lang racket

(require web-server/servlet
         web-server/servlet-env
         net/url-structs)

(define spotify-user-code "")

(define auth-code-semaphore (make-semaphore 0))

(define (my-app req)
  (define code (dict-ref (url-query (request-uri req)) 'code null))
  (define error (dict-ref (url-query (request-uri req)) 'error null))

  (cond
    [(not (null? error))
     (response/xexpr
      `(html (head (title "Spotify Callback Page"))
             (body (p ,(if (string=? error "access_denied")
                           "You have to authorize the app on Spotify to use it."
                           "There was an error authenticating with Spotify.")))))]
    [(null? code)
     (response/xexpr
      `(html (head (title "Spotify Callback Page"))
             (body (p "Nothing to see here, please close this window, by the way"))))]
    [else
     (semaphore-post auth-code-semaphore)
     
     (set! spotify-user-code code)
     (response/xexpr
      `(html (head (title "Spotify Callback Page"))
             (body (p "You can close this page now."))))]))

(define (run-spotify-cb-server)
  (thread (lambda ()
            (serve/servlet my-app
                           #:port 11235
                           #:servlet-path "/callback"
                           #:launch-browser? #f
                           #:connection-close? #t
                           #:command-line? #f
                           #:banner? #f))))

(provide (all-defined-out))