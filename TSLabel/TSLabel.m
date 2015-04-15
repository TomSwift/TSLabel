//
//  TSLabel.m
//
//  Created by Nicholas Hodapp on 4/14/15.
//  Copyright (c) 2015 CoDeveloper LLC. All rights reserved.
//

#import "TSLabel.h"
#import <objc/runtime.h>

NSString* const TSLinkAttributeName		= @"ts_linkAttributeName";
NSString* const TSLabelAttributeName	= @"ts_labelAttributeName";
NSString* const TSMarker				= @"\u2060"; // word-joiner, a zero-width non-breaking space

@interface TSLinkInfo : NSObject
@property (strong, nonatomic) NSURL* url;
@property (assign, nonatomic) NSRange range;
@property (assign, nonatomic) CGRect bounds;
@end
@implementation TSLinkInfo
@end

@interface TSLabel ()
@property (strong, nonatomic, readonly) NSLayoutManager* ts_layoutManager;
@property (strong, nonatomic) NSSet* links;
@end

@interface NSTextStorage (TS) <NSLayoutManagerDelegate>
@end

@implementation NSTextStorage (TS)

//$ this method will be called by the UILabel's shared NSLayoutManager,
//$ which assigns its NSTextStorage (itself a NSMutableAttributedString) as its delegate
//$ this is the magic we use to identify the NSLayoutManager in use by the UILabel
- (void) layoutManager: (NSLayoutManager *) layoutManager didCompleteLayoutForTextContainer: (NSTextContainer *) textContainer atEnd: (BOOL)layoutFinishedFlag
{
	// search for our custom label attribute - if we have it we'll tell it about link bounds!
	TSLabel* label = [self attribute: TSLabelAttributeName
							 atIndex: 0
					  effectiveRange: nil];
	
	if ( label != nil && [label isKindOfClass: [TSLabel class]] )
	{
		CGRect containerGlyphBounds = [layoutManager boundingRectForGlyphRange: [layoutManager glyphRangeForTextContainer: textContainer] inTextContainer: textContainer];
		
		// determine the bounds of each link and record that information with the TSLabel
		NSMutableSet* links = [NSMutableSet new];
		[self enumerateAttribute: TSLinkAttributeName
						 inRange: NSMakeRange(0, self.length)
						 options: 0
					  usingBlock: ^(NSURL* url, NSRange range, BOOL *stop) {
						  
						  if ( url != nil )
						  {
							  TSLinkInfo* link = [TSLinkInfo new];
							  link.url = url;
							  link.range = range;

							  NSRange glyphRange = [layoutManager glyphRangeForCharacterRange: range actualCharacterRange: nil];
							  CGRect bounds = [layoutManager boundingRectForGlyphRange: glyphRange inTextContainer: textContainer];
							  link.bounds = CGRectOffset(bounds, 0, (label.bounds.size.height-containerGlyphBounds.size.height)/2);
							  
							  [links addObject: link];
						  }
					  }];
		
		label.links = links;
	}
}

@end

@implementation TSLabel
{
	TSLinkInfo*				_interactingLink;

	NSMutableDictionary*	_linkAttributes;
}

- (id) initWithCoder: (NSCoder *) aDecoder
{
	self = [super initWithCoder: aDecoder];
	if ( self != nil )
	{
		[self ts_commonInit];
	}
	return self;
}

- (id) initWithFrame: (CGRect) frame
{
	self = [super initWithFrame: frame];
	if ( self != nil )
	{
		[self ts_commonInit];
	}
	return self;
}

- (void) ts_commonInit
{
	// default styles for links
	_linkAttributes = [@{ @(UIControlStateNormal)		: @{ NSForegroundColorAttributeName : [UIColor blueColor],
															 NSUnderlineStyleAttributeName : @(1) },
						 
						  @(UIControlStateHighlighted)	: @{ NSForegroundColorAttributeName : [[UIColor blueColor] colorWithAlphaComponent: 0.5],
															 NSUnderlineStyleAttributeName : @(1) },
						 
						  @(UIControlStateDisabled)		: @{ } } mutableCopy];
	
	// such that we can get touches:
	self.userInteractionEnabled = YES;
}

- (NSLayoutManager*) ts_layoutManager
{
	return objc_getAssociatedObject(self, @selector(ts_layoutManager));
}

- (NSAttributedString*) ts_configureAttributedText: (NSAttributedString*) attributedText
{
	NSMutableAttributedString* mutableText = [attributedText mutableCopy];
	
	// pass 1 - convert any NSLinkAttributeName attrs to TSLinkAttrributeName
	[mutableText enumerateAttribute: NSLinkAttributeName
							inRange: NSMakeRange(0, attributedText.length)
							options: 0
						 usingBlock: ^(NSURL* linkURL, NSRange range, BOOL *stop) {
							 
							 if ( linkURL != nil && ![linkURL isEqual: TSMarker])
							 {
								 [mutableText setAttributes: @{ TSLinkAttributeName : linkURL }
													  range: range ];
								 
							 }
						 }];
	
	// pass 2 - apply link attrs
	[mutableText enumerateAttribute: TSLinkAttributeName
							inRange: NSMakeRange(0, attributedText.length)
							options: 0
						 usingBlock: ^(NSURL* linkURL, NSRange range, BOOL *stop) {
							 
							 if ( linkURL != nil )
							 {
								 // determine if the link is followable; default then ask delegate:
								 BOOL disabled = ![[UIApplication sharedApplication] canOpenURL: linkURL];
								 if ( [self.delegate respondsToSelector: @selector(label:canInteractWithURL:inRange:)] )
								 {
									 disabled = ![self.delegate label: self canInteractWithURL: linkURL inRange: range];
								 }
								 
								 // highlighted, disabled, or normal?:
								 UIControlState state = disabled ? UIControlStateDisabled : NSEqualRanges( range, _interactingLink.range) ? UIControlStateHighlighted : UIControlStateNormal;
								 
								 NSMutableDictionary* mutableLinkAttributes = [[self linkAttributesForState: state] mutableCopy];
								 mutableLinkAttributes[TSLinkAttributeName] = linkURL;
								 [mutableText setAttributes: mutableLinkAttributes
													  range: range ];
							 }
						 }];
	
	// add our marker if needed:
	if ( nil == [mutableText attribute: TSLabelAttributeName atIndex: 0 effectiveRange: nil] )
	{
		// include a NSLinkAttributeName at location 0, otherwise UILabel apparently won't use a NSLayoutManager...
		NSAttributedString* marker = [[NSAttributedString alloc] initWithString: @"\u200b"
																	 attributes: @{ NSLinkAttributeName : TSMarker,
																					TSLabelAttributeName : self }];
		
		[mutableText insertAttributedString: marker atIndex: 0];
	}
	
	return [mutableText copy]; // strip mutable
}

- (void) setAttributedText: (NSAttributedString *) attributedText
{
	attributedText = [self ts_configureAttributedText: attributedText];
	
	[super setAttributedText: attributedText];
}

- (void) setLinkAttributes: (NSDictionary*) attributes forState: (UIControlState) state
{
	_linkAttributes[@(state)] = attributes;
}

- (NSDictionary*) linkAttributesForState: (UIControlState) state
{
	return _linkAttributes[@(state)];
}

- (void) touchesBegan: (NSSet *) touches withEvent: (UIEvent *) event
{
    CGPoint p = [touches.anyObject locationInView: self];
	
	[self.links enumerateObjectsUsingBlock: ^(TSLinkInfo* link, BOOL *stop) {
		
		if ( (*stop = CGRectContainsPoint( link.bounds, p ) ) )
		{
			_interactingLink = link;
			[self setAttributedText: self.attributedText];
		}
	}];
}

- (void) touchesCancelled: (NSSet *) touches withEvent: (UIEvent *) event
{
	_interactingLink = nil;
	[self setAttributedText: self.attributedText];
}

- (void) touchesEnded: (NSSet *) touches withEvent: (UIEvent *) event
{
	if ( _interactingLink != nil && [self.delegate respondsToSelector: @selector(label:shouldInteractWithURL:inRange:)] )
	{
		if ( [self.delegate label: self shouldInteractWithURL: _interactingLink.url inRange: _interactingLink.range] )
		{
			[UIApplication.sharedApplication openURL: _interactingLink.url];
		}
	}
	_interactingLink = nil;
	[self setAttributedText: self.attributedText];
}

- (void) touchesMoved: (NSSet *) touches withEvent: (UIEvent *) event
{
	_interactingLink = nil;
	[self setAttributedText: self.attributedText];
}

@end