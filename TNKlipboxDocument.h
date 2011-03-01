////////////////////////////////////////////////////////////////////////////////
//  klipbox
//  ----------------------------------------------------------------------------
//  Created by Travis Nesland on 2/14/11.
//  Copyright 2011. All rights reserved.
////////////////////////////////////////////////////////////////////////////////

#import <Cocoa/Cocoa.h>
@class TNKlipboxBox;

@interface TNKlipboxDocument : NSDocument
{
  float x;                           // x of origin
  float y;                           // y of origin
  float w;                           // w of rect
  float h;                           // h of rect
  NSMutableArray *klipboxes;         // array of klipboxes in the given document
  NSString *fileURL;                 // URL of file (used to save)
  IBOutlet NSWindow *domainWindow;   // main document window
  NSMutableArray *selectedBoxes;     // stack of selected boxes to allow for multiple selections
  BOOL isRunning;
}
@property (readonly) NSMutableArray *klipboxes;

#pragma mark Accessors
- (NSWindow *)domainWindow;

#pragma mark Document Creation
- (id)initWithType: (NSString *)typeName error: (NSError **)outError;

#pragma mark Document Editing
- (void)makeNewKlipboxWithRect:(NSRect)aRect;
- (void)recordNewWindowSize: (NSNotification *)aNote;
- (void)highlightKlipbox:(TNKlipboxBox *)aBox; // if nil, unhighlight all boxes
- (void)selectNextKlipboxUsingCurrentKlipbox:(TNKlipboxBox *)currentBox;

#pragma mark Document Reading
- (void)decodeWithCoder: (NSCoder *)aCoder;
- (BOOL)readFromData: (NSData*)data ofType:(NSString *)typeName error:(NSError **)outError;
- (void)renderKlipboxes;

#pragma mark Document Writing
- (NSData *)dataOfType: (NSString *)typeName error:(NSError **)outError;
- (void)encodeWithCoder: (NSCoder *)aCoder;

#pragma mark Operations
/**
 Compare the output of each klipbox and group images together given their equality. This will generate a report which contains color-coded listing of each klipbox. Double-clicking a record will pull up the image returned.
 */
- (IBAction)analyze: (id)sender;
/**
 Tell every klipbox in the document to start capturing images.
 */
- (IBAction)start: (id)sender;
/**
 Tell every klipbox in the document to stop capturing images.
 */
- (IBAction)stop: (id)sender;

#pragma mark Preferences
- (NSRect)frame;
- (float)transparency;

#pragma mark Key Values
NSString * const TNKlipboxDocumentTypeKey;
NSString * const TNKlipboxDocumentNameKey;
NSString * const TNKlipboxDocumentOriginXKey;
NSString * const TNKlipboxDocumentOriginYKey;
NSString * const TNKlipboxDocumentRectangleWidthKey;
NSString * const TNKlipboxDocumentRectangleHeightKey;
NSString * const TNKlipboxDocumentKlipboxesKey;

#pragma mark Temporary Preference Keys
float const transparency;
@end



