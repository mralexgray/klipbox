////////////////////////////////////////////////////////////////////////////////
//  klipbox
//  ----------------------------------------------------------------------------
//  Created by Travis Nesland on 2/14/11.
//  Copyright 2011. All rights reserved.
////////////////////////////////////////////////////////////////////////////////
//  TodoList:
//  - decide which expansion options to include in pipe command (out inc,
//    box id, etc.)
//  - add switch between write | pipe | append?
////////////////////////////////////////////////////////////////////////////////

#import "TNKlipboxBox.h"
#import "TNKlipboxDocument.h"
#import "TNKlipboxBoxView.h"

@implementation TNKlipboxBox

@synthesize boxID;
@synthesize myView;
@synthesize myDocument;
@synthesize macroPollingInterval;
@synthesize microPollingInterval;
@synthesize pipeCommand;

- (void)dealloc
{
  [boxID release];boxID=nil;
  [myView release];myView=nil;
  [pipeCommand release];pipeCommand=nil;
  // ----------------------------------
  [super dealloc];
}

- (void)drawUsingView:(NSView **)newView
{
  if(!newView)
  {
    ELog(@"No view pointer provided");
    return;
  }
  [self setMyView:[[TNKlipboxBoxView alloc] initWithFrame:[self frame]]];
  *newView = myView;
  [myView setNeedsDisplay:YES];
}

- (NSRect)frame
{
  return NSMakeRect(x,y,w,h);
}

- (id)initForDocument:(TNKlipboxDocument *)document withRect:(NSRect)rect usingView:(NSView **)view error:(NSError **)outError
{
  if(self=[super init])
  {
    myDocument = document;
    // set new box name / ID
    [self setBoxID:[NSString stringWithFormat:@"New Klipbox %d",[[myDocument klipboxes] count]]];
    [self setFrame:rect];
    // TODO: set default macro and micro polling info
    [self setMacroPollingInterval:500]; // half a second
    [self setMicroPollingInterval:10];  // hundreth of a second
    // TODO: set default pipe command
    [self setPipeCommand:@"> /Users/tnesland/Desktop/ImgOut/%@.jpg"]; // write image out to ~/Desktop/ImgOut/...jpg
    // draw view
    [self drawUsingView:view];
  }
  // else.. there was an error initializing box
  if(!self && outError)
  {
    *outError = [NSError errorWithDomain:NSOSStatusErrorDomain code:unimpErr userInfo:NULL];
  }
  return self;
}

- (void)setFrame:(NSRect)newFrame
{
  x = newFrame.origin.x;
  y = newFrame.origin.y;
  w = newFrame.size.width;
  h = newFrame.size.height;
}

- (void)updateFrame:(NSNotification *)aNote
{
  NSRect theFrame = [myView frame];
  x = theFrame.origin.x;
  y = theFrame.origin.y;
  w = theFrame.size.width;
  h = theFrame.size.height;
}

#pragma mark NSCodingProtocol
- (id)initWithCoder:(NSCoder *)aCoder {
  if(self=[super init])
  {
    [self setBoxID:[aCoder decodeObjectForKey:TNKlipboxBoxIDKey]];
    x = [aCoder decodeFloatForKey:TNKlipboxBoxXKey];
    y = [aCoder decodeFloatForKey:TNKlipboxBoxYKey];
    w = [aCoder decodeFloatForKey:TNKlipboxBoxWidthKey];
    h = [aCoder decodeFloatForKey:TNKlipboxBoxHeightKey];
    macroPollingInterval = [aCoder decodeIntegerForKey:TNKlipboxBoxMacroPollingKey];
    microPollingInterval = [aCoder decodeIntegerForKey:TNKlipboxBoxMicroPollingKey];
    [self setPipeCommand:[aCoder decodeObjectForKey:TNKlipboxBoxPipeCommandKey]];
    
  }
  DLog(@"Decoded Klipbox: %@",boxID);
  return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
  DLog(@"Attempint to endcode klipbox: %@",boxID);
  [aCoder encodeObject:boxID forKey:TNKlipboxBoxIDKey];
  [aCoder encodeFloat:[myView frame].origin.x forKey:TNKlipboxBoxXKey];
  [aCoder encodeFloat:[myView frame].origin.y forKey:TNKlipboxBoxYKey];
  [aCoder encodeFloat:[myView frame].size.width forKey:TNKlipboxBoxWidthKey];
  [aCoder encodeFloat:[myView frame].size.height forKey:TNKlipboxBoxHeightKey];
  [aCoder encodeInteger:macroPollingInterval forKey:TNKlipboxBoxMacroPollingKey];
  [aCoder encodeInteger:microPollingInterval forKey:TNKlipboxBoxMicroPollingKey];
  [aCoder encodeObject:pipeCommand forKey:TNKlipboxBoxPipeCommandKey];
}

NSString * const TNKlipboxBoxIDKey = @"TNKlipboxBoxID";
NSString * const TNKlipboxBoxXKey = @"TNKlipboxBoxX";
NSString * const TNKlipboxBoxYKey = @"TNKlipboxBoxY";
NSString * const TNKlipboxBoxWidthKey = @"TNKlipboxBoxWidth";
NSString * const TNKlipboxBoxHeightKey = @"TNKlipboxBoxHeight";
NSString * const TNKlipboxBoxMacroPollingKey = @"TNKlipboxBoxMacroPolling";
NSString * const TNKlipboxBoxMicroPollingKey = @"TNKlipboxBoxMicroPolling";
NSString * const TNKlipboxBoxPipeCommandKey = @"TNKlipboxBoxPipeCommand";



@end





