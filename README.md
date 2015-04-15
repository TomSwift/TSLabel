# TSLabel
A lightweight UILabel subclass with support for tappable hyperlinks

I've always found it a bit painful that `UILabel` added support in 6.0 for `attributedText` but didn't support one of the obvious uses cases - tappable hyperlinks.  If the label was rendering ONLY a hyperlink you could get by, but not if there was text formatted around the link or multiple links encoded in the string.  

Typically I've had to either render my own text, use a more heavyweight solution like `UITextView`, or use a 3rd party library like `TTTAttributedLabel`.  `TTTAttributedLabel` generally works well - until it doesn't.  Most recently I discovered that it doesn't render NSTextAttachments - which `UILabel` does.

The primary blocker for using a `UILabel` to render hyperlinks is that it is difficult to calculate the bounds of the hyperlink as rendered by the `UILabel` (and hence, be able to detect which hyperlink the user tapped on).  This is because `UILabel` doesn't expose any mechanism for this, such as a `NSLayoutManager`.  A secondary blocker might be that `UILabel` offers no control over how hyperlinks are rendered - they're always blue and underlined.

I did some spelunking and figured out a few things, which ultimately led to being able to intercept the `NSLayoutManager` employed by a `UILabel` to perform its layout and rendering:

1. `UILabel` instances share a `NSLayoutManager`.  They appear to queue up rendering tasks to this manager.  Because of this it isn't really feasible to cache the NSLayoutManager for a given UILabel - by the time you want to use it, it has likely been reconfigured for a different UILabel.

2. The `NSTextStorage` instance used by the shared `NSLayoutManager` is the delegate of the `NSLayoutManager`.

Because of #2, I realized that the `NSLayoutManager` would attempt to call any `NSLayoutManagerDelegate` methods implemented on the `NSTextStorage` (which is itself a subclass of `NSMutableAttributedString` and represents the string being rendered.)  Indeed, by adding a category method matching a `NSLayoutManagerDelegate` method signature to  `NSTextStorage` I found I could inject myself into the layout pipeline.  (Note: if the `NSTextStorage` subclass employed by the `UILabel` already implemented my chosen delegate protocol method then I wouldn't have much luck.  I'd have to instead swizzle the class or something more heinous.')  Now the problem became how to get back to the `UILabel` from here.

`NSTextStorage` is a `NSMutableAttributedString`, which is representing the `attributedText` set on the `UILabel`.  It encodes all of the attributes that describe the format of the string.  Attributed strings are permitted to encode custom attributes - and so I used this as a mechanism to encode a back pointer to my `UILabel`.  I did this by inserting a zero-width space character at the front of the attributed string and setting a custom attribute with a value of the `UILabel` itself.  Now, when the layout manager delegate method `layoutManager:didCompleteLayoutForTextContainer: atEnd:` is invoked I can discover the bounding rects for any encoded hyperlink and pass those off to the `UILabel`.

`TSLabel` uses this technique to enable tappable hyperlinks.  I also made it capable of using custom styles for hyperlink rendering - for normal, highlighted and disabled (unfollowable links) states.  

I'm fairly certain this is App-Store safe, however the technique is fragile and could break if Apple changed their implementation.  Use at your own risk!