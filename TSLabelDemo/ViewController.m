//
//  ViewController.m
//  TSLabelDemo
//
//  Created by Nicholas Hodapp on 4/15/15.
//  Copyright (c) 2015 CoDeveloper LLC. All rights reserved.
//

#import "ViewController.h"
#import "TSLabel.h"

@interface ViewController () <TSLabelDelegate>
@end

@implementation ViewController
{
	IBOutlet TSLabel* _label1;
	
	IBOutlet TSLabel* _label2;
}

- (void) viewDidLoad
{
	[super viewDidLoad];
	
	NSMutableAttributedString* at1 = [[NSMutableAttributedString alloc] initWithString: @"Hello, World - Long Text Will Shrink - www.stackoverflow.com"
																			attributes: @{ NSForegroundColorAttributeName : [UIColor redColor]}];
	[at1 addAttribute: NSLinkAttributeName value: [NSURL URLWithString: @"http://www.a.com"] range: NSMakeRange( [at1.string rangeOfString: @"www"].location, 21)];
	
	_label1.delegate = self;
	_label1.attributedText = at1;
	_label1.userInteractionEnabled = YES;
	
	
	NSMutableAttributedString* at2 = [[NSMutableAttributedString alloc] initWithString: @"Tap here or here"];
	[at2 addAttribute: NSLinkAttributeName value: [NSURL URLWithString: @"http://www.b.com"] range: NSMakeRange( 4, 4)];
	[at2 addAttribute: NSLinkAttributeName value: [NSURL URLWithString: @"http://www.c.com"] range: NSMakeRange( 12, 4)];
	
	_label2.delegate = self;
	_label2.attributedText = at2;
}

// TSLabelDelegate methods

- (BOOL) label:(TSLabel *)label canInteractWithURL:(NSURL *)URL inRange:(NSRange)characterRange
{
	return YES;
}

- (BOOL) label:(TSLabel *)label shouldInteractWithURL:(NSURL *)URL inRange:(NSRange)characterRange
{
	NSLog( @"%@", URL );
	return NO;
}

@end
