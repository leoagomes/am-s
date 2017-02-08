#lang racket

(require "itunes.rkt"
         "spotify-api.rkt")

(define throttle-time 0.500)
(define throttle-count 5)

(define (throttle)
  (sleep throttle-time))

(define-struct sp-album (id name artist tracks)
  #:mutable)

(define (extract-album-id sp-response)
  (define albums (dict-ref sp-response 'albums null))
  (if (null? albums) ""
      (let ([total (dict-ref albums 'total 0)]
            [items (dict-ref albums 'items null)])
        (if (= total 0) ""
            (dict-ref (car items) 'id ""))))) ; get the id of the first element
  

(define (get-album-ids track-list)
  (define-struct album-data (name artist it-tracks)
    #:mutable)
  
  (define album-data-dict '())

  (for ([entry track-list])
    (let ([track (cdr entry)])
      (define current-album-data (dict-ref album-data-dict (it-track-album track) null))
      (cond
        [(null? current-album-data)
         (set! album-data-dict
               (cons (cons (it-track-album track)
                           (album-data (it-track-album track)
                                       (it-track-album-artist track)
                                       (cons track '())))
                     album-data-dict))]
        [else
         (set-album-data-it-tracks! current-album-data
                                    (cons track
                                          (album-data-it-tracks current-album-data)))])))

  (define throttled-album-get
    (let ([count 0])
      (lambda (ad)
        (set! count (+ count 1))
        (when (= (modulo count throttle-count) 0)
          (display count)
          (display "throttling")
          (throttle))
        (display "getting album")
        (display (album-data-name ad))
        (define sp-response (search-album (album-data-name ad)
                                          (album-data-artist ad)))
        (cond
          [(eq? 'too_many_requests sp-response)
           (sleep retry-after)
           (throttled-album-get ad)]
          [(dict? sp-response)
           (extract-album-id sp-response)]
          [else ""]))))
  
  (define album-id-dict (map (lambda (ad)
                               (cons (album-data-name (cdr ad))
                                     (throttled-album-get (cdr ad))))
                             album-data-dict))

    album-id-dict)

(define (get-spotify-id sp-response)
  (define )


(define (get-song-by-song track-dict)
  (for ([track-entry track-dict])
    (define track (cdr track-entry))
    (set-it-track-spotify-id! (get-spotify-id (search-track (it-track-name track)
                                                            (it-track-album track)
                                                            (it-track-artist track))))))

(provide (all-defined-out))