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
#import "TNKlipboxBoxInfoPanel.h"
#import "TNKlipboxPasteBoard.h"

@implementation TNKlipboxBox

#define SNAPSHOT CGWindowListCreateImage(NSRectToCGRect([self absFrame]),kCGWindowListOptionOnScreenBelowWindow,[[myDocument domainWindow] windowNumber],kCGWindowImageBoundsIgnoreFraming)
#define BITMAP_FROM_SNAPSHOT [[[NSBitmapImageRep alloc] initWithCGImage:SNAPSHOT] autorelease]
#define DATA_FROM_BITMAP [BITMAP_FROM_SNAPSHOT representationUsingType:NSTIFFFileType properties:nil]

@synthesize boxID;
@synthesize myView;
@synthesize myInfoPanel;
@synthesize myDocument;
@synthesize macroPollingInterval;
@synthesize microPollingInterval;
@synthesize pipeCommand;
@synthesize lastImage;
@synthesize guard;

- (void)dealloc
{
  [boxID release];boxID=nil;
  [myView release];myView=nil;
  [pipeCommand release];pipeCommand=nil;
  // ----------------------------------
  [super dealloc];
}

- (NSRect)absFrame
{
  // TODO: correct implementation
  // ...currently the workaround is to use a fullscreen domain window and
  // pad the top 45 to account for menu bars  
  return NSMakeRect(x,y+44.0,w,h);
}
  
- (void)drawUsingView:(NSView **)newView
{
  if(!newView)
  {
    ELog(@"No view pointer provided");
    return;
  }
  // load nib and claim ownership
  [NSBundle loadNibNamed:@"TNKlipbox" owner:self];
  // [self setMyView:[[TNKlipboxBoxView alloc] initWithFrame:[self frame]]];
  // [myView setOwner:self];
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
    [self setMacroPollingInterval:1000]; // half a second
    [self setMicroPollingInterval:200];  // hundreth of a second
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
  [myView setNeedsDisplay:YES];
}

- (void)updateFrame
{
  NSRect theFrame = [myView frame];
  x = theFrame.origin.x;
  y = theFrame.origin.y;
  w = theFrame.size.width;
  h = theFrame.size.height;
}

#pragma mark Edit Operations
- (IBAction)delete:(id)sender
{
  if([sender isKindOfClass:[TNKlipboxPasteBoard class]]) {
    [myView delete:self];
    return;
  }
  [[myDocument klipboxes] removeObject:self];  // remove ourself from the document
}

- (IBAction)openInfoPanel:(id)sender
{
  // load values for info panel
  [myInfoPanel loadValues];
  // run modal
  DLog(@"Attempting to run modal for panel");
  if(!myInfoPanel) ELog(@"Lost pointer to myInfoPanel");
  [NSApp runModalForWindow:myInfoPanel];
}

#pragma mark Run Operations
- (void)beginRecording
{
  @synchronized(self)
  {
    shouldContinueRecording = YES;
    outsideTimer = [NSTimer scheduledTimerWithTimeInterval:macroPollingInterval/1000 target:self selector:@selector(initiateSnapshot:) userInfo:nil repeats:YES];
    DLog(@"%@ will begin recording",boxID);
  }
}

- (void)initiateSnapshot: (NSTimer *)theTimer
{
  if(shouldContinueRecording)
  {
    if(!guard)
    {
      DLog(@"%@ is trying to take a snapshot",boxID);
      // take snapshot on a new thread
      [self setGuard:YES];
      [NSThread detachNewThreadSelector:@selector(takeSnapshot) toTarget:self withObject:nil];
    }
  }
}

/**
 Returns an autoreleased NSData object representing the screenshot
 */
- (NSData *)screenshotAsData
{
  // screenRect ---> CGImage
  CGImageRef imgRef = CGWindowListCreateImage(NSRectToCGRect([self absFrame]),kCGWindowListOptionOnScreenBelowWindow,[[myDocument domainWindow] windowNumber],kCGWindowImageBoundsIgnoreFraming);
  // CGImage ---> bitmap
  NSBitmapImageRep *bitRep = [[NSBitmapImageRep alloc] initWithCGImage:imgRef];
  // bitmap ---> data
  NSData *imgData = [[NSData alloc] initWithData:[bitRep representationUsingType:NSTIFFFileType properties:nil]];
  // release CGImage and bitmap
  CGImageRelease(imgRef);
  [bitRep release]; bitRep=nil;
  return [imgData autorelease];
}  
  
- (void)stopRecording
{
  @synchronized(self)
  {
    shouldContinueRecording = NO;
    [outsideTimer invalidate];
    DLog(@"%@ will stop recording",boxID);
  }
}

- (void)takeSnapshot
{
  // this message is invoked on background threads...
  // so it needs its own autorelease pool
  NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
  #ifdef DEBUG
  clock_t start, end;
  double elapsed;
  start = clock();
  #endif
  // TODO: add image to our processing queue
  // ...for testing we will write out the image for human inspection
  NSData *newImage = [self screenshotAsData];
  if(![newImage isEqualToData:lastImage])
  {
    DLog(@"Image change has been detected");
    do
    {
      newImage = [self screenshotAsData];
      usleep(5000);
    }
    while(![[self screenshotAsData] isEqualToData:newImage]);
    [self setLastImage:newImage];
    [lastImage writeToFile:[NSString stringWithFormat:@"/Users/tnesland/Desktop/OUT/%@_%d.tiff",boxID,[NSDate date]] atomically:YES];
  }
  DLog(@"%@ did finish taking snapshot at %@ on thread %@",boxID,[NSDate date],[NSThread currentThread]);
  #ifdef DEBUG
  end = clock();
  elapsed = ((double) (end - start)) / CLOCKS_PER_SEC;
  DLog(@"Time: %f",elapsed);
  #endif
  [self setGuard:NO];
  [pool drain];
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





