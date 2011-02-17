//
//  TNKlipboxDocument.m
//  klipbox
//
//  Created by Travis Nesland on 2/14/11.
//  Copyright 2011. All rights reserved.
//

#import "TNKlipboxDocument.h"

@implementation TNKlipboxDocument

#pragma mark Housekeeping
- (void)dealloc
{
  // remove notifications
  [[NSNotificationCenter defaultCenter] removeObserver:self];
  // release any reserved memory
  // [klipboxes release];klipboxes=nil;
  // super...
  [super dealloc];
}

- (id)init
{
    self = [super init];
    if (self)
    {
      // any global initialization???
    }
    return self;
}

#pragma mark NSDocument Subclassing
- (NSString *)windowNibName
{
  return @"TNKlipboxDocument";
}

- (void)windowControllerDidLoadNib:(NSWindowController *) aController
{
  [super windowControllerDidLoadNib:aController];
  // Add any code here that needs to be executed once the windowController has loaded the document's window.
  domainWindow = [aController window];
  [domainWindow setFrame:[self frame] display:YES];
  [domainWindow setAlphaValue:[self transparency]];
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(recordNewWindowSize:) name:NSWindowDidResizeNotification object:domainWindow];
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(recordNewWindowSize:) name:NSWindowDidMoveNotification object:domainWindow];
}

#pragma mark Document Creation
- (id)initWithType: (NSString *)typeName error: (NSError **)outError
{
  if(self=[super initWithType:typeName error:outError])
  {
    x = 500;
    y = 500;
    w = 650;
    h = 400;
    klipboxes = [[NSMutableArray alloc] initWithCapacity:5];
    [klipboxes addObject:@"one"];
    [klipboxes addObject:@"two"];
  }
  return self;
}

#pragma mark Document Editing
- (void)recordNewWindowSize: (NSNotification *)aNote
{
  DLog(@"Old Dimensions -- x:%f y:%f w:%f h:%f",x,y,w,h);
  NSRect rect = [domainWindow frame];
  x = rect.origin.x;
  y = rect.origin.y;
  w = rect.size.width;
  h = rect.size.height;
  DLog(@"New Dimensions -- x:%f y:%f w:%f h:%f",x,y,w,h);  
}

#pragma mark Document Reading

/**
 Extract data from plist... record error if any
 */
- (id)initWithCoder: (NSCoder *)aCoder
{
  if(self=[super init])
  {
    x = [aCoder decodeFloatForKey:TNKlipboxDocumentOriginXKey];
    y = [aCoder decodeFloatForKey:TNKlipboxDocumentOriginYKey];
    w = [aCoder decodeFloatForKey:TNKlipboxDocumentRectangleWidthKey];
    h = [aCoder decodeFloatForKey:TNKlipboxDocumentRectangleHeightKey];
    klipboxes = [aCoder decodeObjectForKey:TNKlipboxDocumentKlipboxesKey];
    return self;
  }
  // else... could not decode
  ELog(@"Could not decode document");
  return nil;
}

- (BOOL)readFromData: (NSData *)data ofType:(NSString *)typeName error:(NSError **)outError
{
  DLog(@"Type: %@ Data: %@",typeName,data);
  id didRead = nil;
  // create a dictionary out of the file
  if([typeName isEqualToString:TNKlipboxDocumentTypeKey])
  {
    didRead = [NSKeyedUnarchiver unarchiveObjectWithData:data];
  }
  if ( !didRead && outError ) {
    *outError = [NSError errorWithDomain:NSOSStatusErrorDomain code:unimpErr userInfo:NULL];
	}
  DLog(@"My Data: %@",self);
  return YES;
}

#pragma mark Document Writing
- (NSData *)dataOfType: (NSString *)typeName error:(NSError **)outError
{
  DLog(@"Request for data out of type: %@",typeName);
  NSData *retVal;           // our return data
  // attempt to archive our dictionary
  if([typeName isEqualToString:TNKlipboxDocumentTypeKey]) {
    retVal = [NSKeyedArchiver archivedDataWithRootObject:self];
  }
  DLog(@"Data Out: %@",retVal);
  if ( !retVal && outError ) {
    *outError = [NSError errorWithDomain:NSOSStatusErrorDomain code:unimpErr userInfo:NULL];
    return nil;
  }
  return retVal;
}

- (void)encodeWithCoder: (NSCoder *)aCoder
{
  DLog(@"Attempting to encode");
  @try
  {
    [aCoder encodeFloat:x forKey:TNKlipboxDocumentOriginXKey];
    [aCoder encodeFloat:y forKey:TNKlipboxDocumentOriginYKey];
    [aCoder encodeFloat:w forKey:TNKlipboxDocumentRectangleWidthKey];
    [aCoder encodeFloat:h forKey:TNKlipboxDocumentRectangleHeightKey];
    [aCoder encodeObject:klipboxes forKey:TNKlipboxDocumentKlipboxesKey];
  }
  @catch (NSException * e)
  {
    ELog(@"%@",e);
  }
}

#pragma mark Preferences

/** 
 Needs to return are target frame... this may be dynamic in the future
 */
- (NSRect)frame
{
  return NSMakeRect(x,y,w,h);
}

- (float)transparency
{
  return transparency;
}

#pragma mark Key Values
NSString * const TNKlipboxDocumentTypeKey = @"TNKlipboxDocument";
NSString * const TNKlipboxDocumentNameKey = @"TNKlipboxDocumentName";
NSString * const TNKlipboxDocumentOriginXKey = @"TNKlipboxDocumentOriginX";
NSString * const TNKlipboxDocumentOriginYKey = @"TNKlipboxDocumentOriginY";
NSString * const TNKlipboxDocumentRectangleWidthKey = @"TNKlipboxDocumentRectangleWidth";
NSString * const TNKlipboxDocumentRectangleHeightKey = @"TNKlipboxDocumentRectangleHeight";
NSString * const TNKlipboxDocumentKlipboxesKey = @"TNKlipboxDocumentKlipboxes";

#pragma mark Temporary Preference Keys
float const transparency = 0.75;

@end
