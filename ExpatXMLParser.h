#import <Foundation/Foundation.h>
#import <zlib.h>
#import "expat.h"
#import <CFNetwork/CFNetwork.h>

@class ExpatXMLParser;

// Delegate Methods
@protocol ExpatXMLParserDelegate <NSObject>

@optional
- (void)parserDidStartDocument:(ExpatXMLParser*)parser;
- (void)parserDidEndDocument:(ExpatXMLParser*)parser;
- (void)parser:(ExpatXMLParser*)parser didStartMappingPrefix:(NSString *)prefix toURI:(NSString *)namespaceURI;
- (void)parser:(ExpatXMLParser*)parser didEndMappingPrefix:(NSString *)prefix;
- (void)parser:(ExpatXMLParser*)parser foundComment:(NSString *)comment;
- (void)parser:(ExpatXMLParser*)parser foundProcessingInstructionWithTarget:(NSString *)target data:(NSString *)data;
- (void)parser:(ExpatXMLParser*)parser parseErrorOccurred:(NSError *)parseError;
- (BOOL)parser:(ExpatXMLParser*)parser shouldProcessAttributesForElement:(NSString *)elementName;
- (void)parser:(ExpatXMLParser*)parser shouldBeginHTTPRequest:(CFHTTPMessageRef)httpMessage;

@required
- (void)parser:(ExpatXMLParser*)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qualifiedName attributes:(NSDictionary *)attributeDict;
- (void)parser:(ExpatXMLParser*)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName;
- (void)parser:(ExpatXMLParser *)parser foundCharacters:(NSString *)string;

@end

@interface ExpatXMLParser : NSObject
{
	id<ExpatXMLParserDelegate> delegate;
	BOOL shouldProcessNamespaces;
	BOOL shouldReportNamespacePrefixes;
	BOOL shouldResolveExternalEntities;
	BOOL _isDataParse;
	CFMutableDictionaryRef dict;
	CFMutableStringRef buffer;
	XML_Parser parser;
	NSURL * url;
	NSError *error;
	CFStringRef seperator;
	NSData * data;
	NSString * userAgent;
}

- (id)initWithContentsOfURL:(NSURL *)url;
- (id)initWithContentsOfFile:(NSString *)path;
- (id)initWithData:(NSData *)data; // create the parser from data

@property(nonatomic, retain) id<ExpatXMLParserDelegate> delegate;
@property(nonatomic, retain) NSString * userAgent;

- (void)setShouldProcessNamespaces:(BOOL)shouldProcessNamespaces;
- (BOOL)shouldProcessNamespaces;

- (void)setShouldReportNamespacePrefixes:(BOOL)flag;
- (BOOL)shouldReportNamespacePrefixes;

- (void)setShouldResolveExternalEntities:(BOOL)shouldResolveExternalEntities;
- (BOOL)shouldResolveExternalEntities;

- (BOOL)parse;
- (void)abortParsing;
- (NSError *)parserError;

- (int)columnNumber;
- (int)lineNumber;
- (NSString *)publicID;
- (NSString *)systemID;

@end
