//
//  MvrDraggableView.m
//  Mover3-iPad
//
//  Created by ∞ on 21/04/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "MvrDraggableView.h"

@interface MvrDraggableView () <UIGestureRecognizerDelegate>

- (void) setupGestureRecognizers;

@end



@implementation MvrDraggableView

- (id) initWithFrame:(CGRect) frame;
{
	if ((self = [super initWithFrame:frame]))
		[self setupGestureRecognizers];
	
	return self;
}

- (id) initWithCoder:(NSCoder *)aDecoder;
{
	if ((self = [super initWithCoder:aDecoder]))
		[self setupGestureRecognizers];
	
	return self;
}

- (void) setupGestureRecognizers;
{	
	UIPanGestureRecognizer* pan = [[[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panned:)] autorelease];
	
	UIRotationGestureRecognizer* rotation = [[[UIRotationGestureRecognizer alloc] initWithTarget:self action:@selector(rotated:)] autorelease];
	
	pan.delegate = self;
	rotation.delegate = self;
	
	self.gestureRecognizers = [NSArray arrayWithObjects:pan, rotation, nil];
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer;
{
	return YES;
}

- (void) dealloc;
{
	for (UIGestureRecognizer* g in self.gestureRecognizers) {
		if (g.delegate == self)
			g.delegate = nil;
	}
	
	[super dealloc];
}

@synthesize delegate;

- (void) rotated:(UIRotationGestureRecognizer*) rotation;
{
	L0Log(@"%d", rotation.state);
	
	if (rotation.state == UIGestureRecognizerStateBegan) {
		L0Log(@"Beginning rotation");
		startingTransform = self.transform;		
	} else if (rotation.state == UIGestureRecognizerStateChanged) {
		L0Log(@"Rotated by %f", (double) rotation.rotation);
		self.transform = CGAffineTransformRotate(startingTransform, rotation.rotation);
		[self.delegate draggableViewCenterDidMove:self];
	} else if (rotation.state == UIGestureRecognizerStateEnded) {
		[self.delegate draggableViewCenterDidStopMoving:self velocity:CGPointZero];
	}
}

- (void) touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event;
{
	[self.delegate draggableViewDidBeginTouching:self];
}

- (void) panned:(UIPanGestureRecognizer*) pan;
{
	L0Log(@"%d", pan.state);
	
	if (pan.state == UIGestureRecognizerStateBegan) {
		startingCenter = self.center;
		
		[self.delegate draggableViewCenterDidMove:self];
		
	} else if (pan.state == UIGestureRecognizerStateChanged) {
		
		if (!self.superview)
			return;
		
		CGPoint c = startingCenter,
			t = [pan translationInView:self.superview];
		
		c.x += t.x;
		c.y += t.y;
		
		self.center = c;
		
		[self.delegate draggableViewCenterDidMove:self];

	} else if (pan.state == UIGestureRecognizerStateEnded) {
		
		[self.delegate draggableViewCenterDidStopMoving:self velocity:[pan velocityInView:self.superview]];
		
	}
}

@synthesize draggingDisabledOnScrollViews;

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch;
{
	if (!self.draggingDisabledOnScrollViews)
		return YES;
	
	if ([gestureRecognizer isKindOfClass:[UIPanGestureRecognizer class]]) {
		
		UIView* v = [touch view];
		while (v != self && v != nil) {
			
			if ([v isKindOfClass:[UIScrollView class]] && [(id)v isScrollEnabled])
				return NO;
			
			v = v.superview;
			
		}
		
		return YES;
		
	} else
		return YES;

}

@end
