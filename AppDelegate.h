//
//  AppDelegate.h
//  iPhoneExpat
//
//  Created by Ben Reeves on 22/05/2010.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "ExpatXMLParser.h"

@interface AppDelegate : NSObject <UIApplicationDelegate, ExpatXMLParserDelegate, NSXMLParserDelegate> {
	NSTimeInterval start;
	NSTimeInterval end;
	BOOL timePrinted;
	int opened;
	int closed;
	
	NSTimeInterval firstElementTime;
	NSTimeInterval totalExpat;
	NSTimeInterval totalNSXML;
	NSTimeInterval totalExpatReachFirst;
	NSTimeInterval totalNSXMLReachFirst;
}

@end
