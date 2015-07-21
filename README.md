# HTMLdiff

This gem generates nice diff outputs (in HTML) from two supplied bits of HTML
which are (presumably) partially different. It is aimed at the limited HTML
that one would expect to be outputted from a WYSIWYG editor.

It is not foolproof and only gives good results with a limited (and not fully 
documented) range of HTML tags. See the specs for stuff that is known to work.
Beyond that you're on your own!

## Usage

```
doc_a = 'a word is here'
doc_b = 'a nother word is there'

HTMLDiff.diff(doc_a, doc_b)

# => 'a<ins class=\"diffins\"> nother</ins> word is <del class=\"diffmod\">here</del><ins class=\"diffmod\">there</ins>'
```

