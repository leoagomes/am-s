# am->s

Originally intended as a Apple Music -> Spotify music exporter. Still unfinished.

## License

Unless stated otherwise, the code in this repository is released unde an MIT-like License.
Check out the complete license text at LICENSE.

## Running

### Quick note

The code here probably **doesn't work** the way I intend the final product to do.
You _can_ for now get data from Spotify, get the songs from iTunes and authenticate
correctly with spotify, but the song syncing mechanism is still under development.

### Back to business

To use this software (and since there is still no release version of it), you have to 
provide it with a Spotify application `client_id` and `client_secret`. In order to do
that, check [Spotify's documentation](https://developer.spotify.com/web-api/authorization-guide/)
and then change the contents at `spotify-auth.rkt`.

After everything is set, calling `(main)` from `main.rkt` should start the intended
application flow.

In order to read from iTunes, you have to provide the program with an `iTunes Media Library.xml`
file. Check out this guide from Apple on how to do that.

This _should_ run fine on Windows, Mac and Linux (though there is no point on running it
on the latter because there is no iTunes support for it... anyway) without having to change
much (I believe you shouldn't have to make _any_ changes, actually).

_On a side note, I am also sorry if line endings are a mess._

## Why Racket?

I have to change basically _no_ code to get it to work accross Windows and Mac. Also, I
wanted to learn something different and put what I learned about Scheme to practice.
Racket seemed to have a bunch of helpful libraries, so I tried that first and worked like
a charm.

## Important Notice

This code is not affiliated in any form to either Apple or Spotify, nor endorsed by any
one of the forementioned companies.

Apple Music and iTunes are both trademark of Apple Inc.
Spotify is a trademark of Spotify (idk what, sorry).