#lang scribble/doc
@(require "mz.ss"
          (for-syntax scheme/base))

@(define-syntax speed
   (syntax-rules ()
     [(_ id what)
      @t{A @scheme[id] application can provide better performance for
         @elem[what]
         iteration when it appears directly in a @scheme[for] clause.}]))

@title[#:tag "sequences"]{Sequences}

@guideintro["sequences"]{sequences}

A @pidefterm{sequence} encapsulates an ordered stream of values. The
elements of a sequence can be extracted with one of the @scheme[for]
syntactic forms or with the procedures returned by
@scheme[sequence-generate].

The sequence datatype overlaps with many other datatypes. Among
built-in datatypes, the sequence datatype includes the following:

@itemize{

 @item{lists (see @secref["pairs"])}

 @item{vectors (see @secref["vectors"])}

 @item{hash tables (see @secref["hashtables"])}

 @item{strings (see @secref["strings"])}

 @item{byte strings (see @secref["bytestrings"])}

 @item{input ports (see @secref["ports"])}

}

In addition, @scheme[make-do-sequence] creates a sequence given a
thunk that returns procedures to implement a generator.

For most sequence types, extracting elements from a sequence has no
side-effect on the original sequence value; for example, extracting the
sequence of elements from a list does not change the list. For other
sequence types, each extraction implies a side effect; for example,
extracting the sequence of bytes from a port cause the bytes to be
read from the port.

Inidvidual elements of a sequence typically correspond to single
values, but an element may also correspond to multiple values. For
example, a hash table generates two values---a key and its value---for
each element in the sequence.

@section{Sequence Predicate and Constructors}

@defproc[(sequence? [v any/c]) boolean?]{ Return @scheme[#t] if
@scheme[v] can be used as a sequence, @scheme[#f] otherwise.}

@defproc*[([(in-range [end number?]) sequence?]
           [(in-range [start number?] [end number?] [step number? 1]) sequence?])]{
Returns a sequence whose elements are numbers. The single-argument
case @scheme[(in-range end)] is equivalent to @scheme[(in-range 0 end
1)].  The first number in the sequence is @scheme[start], and each
successive element is generated by adding @scheme[step] to the
previous element. The sequence starts before an element that would be
greater or equal to @scheme[end] if @scheme[step] is non-negative, or
less or equal to @scheme[end] if @scheme[step] is negative.
@speed[in-range "number"]}

@defproc[(in-naturals [start exact-nonnegative-integer? 0]) sequence?]{
Returns an infinite sequence of exact integers starting with
@scheme[start], where each element is one more than the preceeding
element. @speed[in-naturals "integer"]}

@defproc[(in-list [lst list?]) sequence?]{
Returns a sequence equivalent to @scheme[lst].
@speed[in-list "list"]}

@defproc[(in-vector [vec vector?]) sequence?]{
Returns a sequence equivalent to @scheme[vec].
@speed[in-vector "vector"]}

@defproc[(in-string [str string?]) sequence?]{
Returns a sequence equivalent to @scheme[str].
@speed[in-string "string"]}

@defproc[(in-bytes [bstr bytes?]) sequence?]{
Returns a sequence equivalent to @scheme[bstr].
@speed[in-bytes "byte string"]}

@defproc[(in-input-port-bytes [inp input-port?]) sequence?]{
Returns a sequence equivalent to @scheme[inp].}

@defproc[(in-input-port-chars [inp input-port?]) sequence?]{ Returns a
sequence whose elements are read as characters form @scheme[inp] (as
opposed to using @scheme[inp] directly as a sequence to get bytes).}

@defproc[(in-hash-table [ht hash-table?]) sequence?]{
Returns a sequence equivalent to @scheme[ht].}

@defproc[(in-hash-table-keys [ht hash-table?]) sequence?]{
Returns a sequence whose elements are the keys of @scheme[ht].}

@defproc[(in-hash-table-values [ht hash-table?]) sequence?]{
Returns a sequence whose elements are the values of @scheme[ht].}

@defproc[(in-hash-table-pairs [ht hash-table?]) sequence?]{
Returns a sequence whose elements are pairs, each containing a key and
its value from @scheme[ht] (as opposed to using @scheme[ht] directly
as a sequence to get the key and value as separate values for each
element).}

@defproc[(in-indexed [seq sequence?]) sequence?]{Returns a sequence
where each element has two values: the value produced by @scheme[seq],
and a non-negative exact integer starting with @scheme[0]. The
elements of @scheme[seq] must be single-valued.}

@defproc[(in-parallel [seq sequence?] ...) sequence?]{Returns a
sequence where each element has as many values as the number of
supplied @scheme[seq]s; the values, in order, are the values of each
@scheme[seq]. The elements of each @scheme[seq] must be single-valued.}

@defproc[(stop-before [seq sequence?] [pred (any/c . -> . any)])
sequence?]{ Returns a sequence that contains the elements of
@scheme[seq] (which must be single-valued), but only until the last
element for which applying @scheme[pred] to the element produces
@scheme[#t], after which the sequence ends.}

@defproc[(stop-after [seq sequence?] [pred (any/c . -> . any)])
sequence?]{ Returns a sequence that contains the elements of
@scheme[seq] (which must be single-valued), but only until the element
(inclusive) for which applying @scheme[pred] to the element produces
@scheme[#t], after which the sequence ends.}

@defproc[(make-do-sequence [thunk (->* ()
                                       ((any/c . -> . any/c)
                                        (any/c . -> . any)
                                        any/c
                                        (() list? . ->* . any/c)
                                        (() list? . ->* . any/c)
                                        ((any/c) any/c . ->* . any/c)))])
         sequence?]{

Returns a sequence whose elements are generated by the procedures and
initial value returned by the thunk. The generator is defined in terms
of a @defterm{position}, which is initialized to the third result of
the thunk, and the @defterm{element}, which may consist of multiple
values.

The @scheme[thunk] results define the generated elements as follows:

@itemize{

 @item{The first result is a @scheme[_next-pos] procedure that takes
       the current position and returns the next position.}

 @item{The second result is a @scheme[_pos->element] procedure that takes
       the current position and returns the value(s) for the current element.
       It is called only once per position.}

 @item{The third result is the initial position.}

 @item{The fourth result takes the current element value(s) and
       returns a true result if the sequence includes the value, and
       false if the sequence should end instead of
       including the value.}

 @item{The fifth result is like the fourth result, but it determines a
       sequence end @italic{after} the current element is already
       included in the sequence.}

 @item{The sixth result is like the fourth result, but it takes both
       the current position and the current element value(s).}

}

}

@section{Sequence Generators}

@defproc[(sequence-generate [seq sequence?]) (values (-> boolean?)
                                                     (-> any))]{
Returns two thunks to extract elements from the sequence. The first
returns @scheme[#t] if more values are available for the sequence. The
second returns the next element (which may be multiple values) from the
sequence; if no more elements are available, the
@exnraise[exn:fail:contract].}

