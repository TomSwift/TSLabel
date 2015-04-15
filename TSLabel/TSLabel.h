//
//  TSLabel.h
//  TestLabel
//
//  Created by Nicholas Hodapp on 4/14/15.
//  Copyright (c) 2015 CoDeveloper LLC. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef void (^LabelLinkTappedBlock)(NSURL* url);

@class TSLabel;

@protocol TSLabelDelegate <NSObject>
@optional

- (BOOL) label: (TSLabel *)label canInteractWithURL: (NSURL *) URL inRange: (NSRange) characterRange;

- (BOOL) label: (TSLabel *)label shouldInteractWithURL: (NSURL *) URL inRange: (NSRange) characterRange;

@end

@interface TSLabel : UILabel

@property (weak, nonatomic) id<TSLabelDelegate> delegate;

- (void) setLinkAttributes: (NSDictionary*) attributes forState: (UIControlState) state;

- (NSDictionary*) linkAttributesForState: (UIControlState) state;

@end
