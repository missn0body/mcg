# mcg

A barebones assembly psuedorandom number generator.  
Made by anson.

This small(er) assembly program uses the [Lehmer/Park-Miller random number generator](https://en.wikipedia.org/wiki/Lehmer_random_number_generator)
to generate psuedorandom numbers in the range of 0 to 255.
This program is seeded with the current time for a different
number every invocation, and can report its internal variables
using the `-r` flag at the command line.

At the moment (as of v.1.0.0), the internal variables can not be
altered by the user, nor the bounds that the generator outputs
numbers in. This can be subject to change in the future.

Usage and options can be read by invoking `mcg --help` at the
command line. This project refuses a standard license, See UNLICENSE for
related details. Issues, bugs, and other things can be discussed
at my E-Mail, <thesearethethingswesaw@gmail.com>

### v.1.0.0

(May 2024)  
A multiplicative congruential generator in Assembly.
