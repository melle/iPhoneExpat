#import <Foundation/Foundation.h>
#import <zlib.h>
#import "expat.h"

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
	
	CFMutableDictionaryRef dict;
	CFMutableStringRef buffer;
	XML_Parser parser;
	NSURL * url;
	NSError *error;
}

- (id)initWithContentsOfURL:(NSURL *)url;

@property(nonatomic, retain) id<ExpatXMLParserDelegate> delegate;

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
