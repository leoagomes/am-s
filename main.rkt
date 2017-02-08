#lang racket/gui

(require "itunes.rkt"
         "spotify-auth.rkt"
         "spotify-api.rkt"
         "song-proc.rkt")

; deletable frame class
(define deletable-frame%
  (class frame%
    (define/override (on-subwindow-char receiver event)
      (if (and (eq? receiver song-list-box) (eq? (send event get-key-code) #\rubout))
          (song-list-box-delete)
          (or (send this on-menu-char event)
              (send this on-system-menu-char event)
              (send this on-traverse-char event))))
    (super-new)))

; main frame instantiation: this is the main window
(define main-frame (new deletable-frame%
                        [label "iTunes (apple music) -> Spotify"]
                        [width 500]
                        [height 600]))

; the label shown in the main frame
(define msg1 (new message%
                  [label "The following songs will be added to your Spotify library."]
                  [parent main-frame]))

; the list-box with all the songs to be sent to spotify
(define song-list-box (new list-box%
                           [label #f]
                           [choices empty]
                           [parent main-frame]
                           [style (list 'clickable-headers 'column-headers 'multiple)]
                           [columns '("Song Name" "Artist" "Album" "iTunes ID" "Spotify ID")]
                           [callback (lambda (list-box event)
                                       (void))]))

; the function to be run when the user presses "delete"
(define (song-list-box-delete)
  (for ([selection (reverse (send song-list-box get-selections))])
    (set-it-track-transfer! (send song-list-box get-data selection) #f)
    (send song-list-box delete selection)))

; the "Add to Spotify Library" button
; the callback
(define (atl-button-callback button event) (void))
 ; (add-to-spotify track-list))

(define atl-button (new button%
                        [label "Add to Library"]
                        [parent main-frame]
                        [callback atl-button-callback]))

; the timer that will refresh spotify tokens
(define refresh-timer (new timer%
                           [notify-callback (lambda ()
                                              (spotify-refresh-token)
                                              (send refresh-timer
                                                    start
                                                    (* (dict-ref spotify-auth-data 'expires_in 3600) 1000)))]
                           [interval #f]))

; the itunes track list
(define track-list empty)

; the main function
(define (main)
  ; load itunes xml
  (define itunes-xml (get-file "Select 'iTunes Media Library.xml'."
                               #f
                               (find-system-path 'home-dir)
                               #f "xml"))

  ; fill song-list-box with song data
  (define plist-data (pl-expr->value (read-plist-file itunes-xml)))
  (define tracks (make-ittrack-dict (get-track-dict plist-data)))
  (set! track-list tracks)
  
  (send song-list-box set
        (map (lambda (track-entry) (it-track-name (cdr track-entry))) tracks)
        (map (lambda (track-entry) (it-track-artist (cdr track-entry))) tracks)
        (map (lambda (track-entry) (it-track-album (cdr track-entry))) tracks)
        (map (lambda (track-entry) (number->string (it-track-id (cdr track-entry)))) tracks)
        (map (lambda (track-entry) "n/a") tracks))
  (for ([i (length tracks)])
    (send song-list-box set-data i (cdr (list-ref tracks i))))
  
  ; do spotify authentication
  (message-box "Spotify Authentication"
               "Pressing OK will take you to Spotify's authentication page on your default browser."
               #f (list 'ok 'no-icon))

  (spotify-do-auth)

  ; setup the timer
  (send refresh-timer start (* (dict-ref spotify-auth-data 'expires_in) 1000))
  
  ; show the window
  (send main-frame show #t))