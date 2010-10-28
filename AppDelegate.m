//
//  AppDelegate.m
//  iPhoneExpat
//
//  Created by Ben Reeves on 22/05/2010.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "AppDelegate.h"


@implementation AppDelegate

-(void)applicationDidFinishLaunching:(UIApplication *)application {
	
	NSArray * urls = [NSArray arrayWithObjects:@"http://ax.itunes.apple.com/WebObjects/MZStoreServices.woa/ws/RSS/topalbums/sf=143441/limit=300/explicit=true/xml",
					  @"http://ax.itunes.apple.com/WebObjects/MZStoreServices.woa/ws/RSS/topalbums/sf=143441/limit=300/explicit=true/xml",
					  @"http://feeds.feedburner.com/DilbertDailyStrip",
					  @"http://designsponge.blogspot.com/atom.xml",
					  @"http://www.slate.com/rss/",
					  @"http://rssfeeds.usatoday.com/UsatodaycomBooks-TopStories",
					  @"http://googleblog.blogspot.com/atom.xml",
					  @"http://api.flickr.com/services/feeds/groups_pool.gne?id=61057342@N00&lang=en-us&format=rss_200",
					  @"http://phobos.apple.com/WebObjects/MZStore.woa/wpa/MRSS/topsongs/limit=25/rss.xml",
					  @"http://www.readwriteweb.com/rss.xml",
					  @"http://rssfeeds.usatoday.com/UsatodaycomNation-TopStories",
					  @"http://dictionary.reference.com/wordoftheday/wotd.rss",
					  @"http://www.quotationspage.com/data/qotd.rss", 
					  @"http://sports.espn.go.com/espn/rss/news", nil];
	
	for (NSString * urlString in urls) {
		
		timePrinted = NO;
		
		opened = 0;
		closed = 0;
		
		NSLog(@"Begin Parsing Using Expat");
		start = [[NSDate date] timeIntervalSince1970];
		ExpatXMLParser * parser = [[ExpatXMLParser alloc] initWithContentsOfURL:[NSURL URLWithString:urlString]];
		parser.delegate = self;
		//[parser setShouldProcessNamespaces:YES];
		[parser parse];
		[parser release];
		end = [[NSDate date] timeIntervalSince1970];
		totalExpat += end-start;
		totalExpatReachFirst += firstElementTime-start;
		printf("Time Taken to Reach first element %f\n", firstElementTime-start);
		printf("Total time %f\n", end-start);
		
		NSLog(@"opened %d -- closed %d", opened, closed);
		
		urlString = [urlString stringByAppendingFormat:@"?=%d", arc4random()];
		
		NSLog(@"%@", urlString);
		
		timePrinted = NO;
		
		opened = 0;
		closed = 0;
	
		NSLog(@"Begin Parsing Using NSXMLParser");
		start = [[NSDate date] timeIntervalSince1970];
		NSXMLParser * parserns = [[NSXMLParser alloc] initWithContentsOfURL:[NSURL URLWithString:urlString]];
		parserns.delegate = self;
		
		[parserns setShouldProcessNamespaces:YES];
		[parserns parse];
		[parserns release];
		end = [[NSDate date] timeIntervalSince1970];
		totalNSXML += end-start;
		totalNSXMLReachFirst += firstElementTime-start;
		printf("Time Taken to Reach first element %f\n", firstElementTime-start);
		printf("Total time %f\n", end-start);
		
		urlString = [urlString stringByAppendingFormat:@"?=%d", arc4random()];

		NSLog(@"opened %d -- closed %d", opened, closed);
	}

	NSLog(@"time to reach the first element Expat: %f -- NSXMLParser: %f\n", totalExpatReachFirst, totalNSXMLReachFirst);
	NSLog(@"Total time for Expat: %f -- NSXMLParser: %f\n", totalExpat, totalNSXML);
}

- (void)parser:(ExpatXMLParser *)parser foundCharacters:(NSString *)string {
}

- (void)parser:(ExpatXMLParser*)parser parseErrorOccurred:(NSError *)parseError {
	NSLog(@"%@", parseError);
}

- (void)parser:(ExpatXMLParser*)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qualifiedName attributes:(NSDictionary *)attributeDict
{	
	if (timePrinted == NO) {
		firstElementTime = [[NSDate date] timeIntervalSince1970];
		timePrinted = YES;
	}
	
	++opened;
}

- (void)parser:(ExpatXMLParser*)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName
{
	++closed;
}

@end
