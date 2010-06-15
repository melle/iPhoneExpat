// ExpatXMLParser
// Wrapper class to translate from Objective-C messages, to proper expat C function calls.
// In addition to giving Cocoa programmers the ability to easily use the expat parser,
//  this class tries to conform to the NSXMLParser api specification.  This means that
//  expat can be a drop in replacement for the NSXMLParser, and in most cases, programmers
//  will only be required to change one line of code.  ('NSXMLParser' -> 'ExpatXMLParser')
//
// Written by Robbie Hanson
// Inspired by Rafael R. Sevilla's work on Expatobjc

#import "ExpatXMLParser.h"
#import <CFNetwork/CFNetwork.h>
#import <SystemConfiguration/SystemConfiguration.h>

//#define COPY_BUFFER

#ifdef XML_UNICODE 
	#ifdef COPY_BUFFER
	 #define CREATE_CFSTRING(x) CFStringCreateWithCharacters (kCFAllocatorDefault,(UniChar*)x,UniCharStrlen(x));
	#else
	 #define CREATE_CFSTRING(x) CFStringCreateWithCharactersNoCopy (kCFAllocatorDefault,(UniChar*)x, UniCharStrlen(x), kCFAllocatorNull)
	#endif
#else
#define CREATE_CFSTRING(x) CFStringCreateWithCStringNoCopy (kCFAllocatorDefault,(const char*)x,kCFStringEncodingUTF8,kCFAllocatorNull);
#endif

const int buffSize = 1048;

const XML_Char seperator = -1;

@implementation ExpatXMLParser

@synthesize delegate;
@synthesize userAgent;

static inline int UniCharStrlen (const XML_Char * in) {

	int ii = 0;
	while (*in != 0) {
		++in;
		++ii;
	}
	
	return ii;
}

// Called when an element (tag) is started
static void XMLCALL
startElementHandler(void *ud, const XML_Char *name, const XML_Char **atts)
{	
	
	ExpatXMLParser * parserobj = (ExpatXMLParser*)ud;
	CFStringRef elementName;
	CFStringRef uri = nil;
	CFStringRef qualifiedName = nil;
	CFArrayRef temp = nil;
	
	// Extract names
	if(parserobj->shouldProcessNamespaces)
	{				
		CFStringRef _name = CREATE_CFSTRING(name); 
		
		temp = CFStringCreateArrayBySeparatingStrings (kCFAllocatorDefault, _name, parserobj->seperator);
		
		if(CFArrayGetCount(temp) > 1) {
			uri = CFArrayGetValueAtIndex(temp, 0);
			elementName = CFArrayGetValueAtIndex(temp, 1);
		} else {
			elementName = CFArrayGetValueAtIndex(temp, 0);
		}

		if (uri) CFRetain(uri);
		if (elementName) CFRetain(elementName);
		
		// It's possible to have a default namespace, in which case a prefix may not have been declared
		if(CFArrayGetCount(temp) > 2) {
			qualifiedName = CFStringCreateWithFormat (kCFAllocatorDefault, NULL, (CFStringRef)@"%@:%@", CFArrayGetValueAtIndex(temp, 2), elementName);
		} else {
			qualifiedName = elementName;
			CFRetain(qualifiedName);
		}
		
		CFRelease(_name);
		CFRelease(temp);
	}
	else
	{
		elementName = CREATE_CFSTRING(name);
	}

	CFDictionaryRemoveAllValues((CFMutableDictionaryRef)parserobj->dict);
	int i;
	for(i=0; atts[i]; i+=2) 
	{
		CFStringRef key = CREATE_CFSTRING(atts[i]); 
		CFStringRef value = CREATE_CFSTRING(atts[i+1]); 

		CFDictionaryAddValue ((CFMutableDictionaryRef)parserobj->dict,
							  (id)key,
							  (id)value
							  );
		
		CFRelease(key);
		CFRelease(value);
	}
				
	if (parserobj->buffer) {
		[parserobj->delegate parser:parserobj foundCharacters:(NSString*)parserobj->buffer];
		CFRelease(parserobj->buffer);
	}

	parserobj->buffer = nil;
		
	[parserobj->delegate parser:parserobj
				 didStartElement:(NSString*)elementName
					namespaceURI:(NSString*)uri
				   qualifiedName:(NSString*)qualifiedName
					  attributes:(NSDictionary*)parserobj->dict];
	
	
	if (qualifiedName) CFRelease(qualifiedName);
	if (elementName) CFRelease(elementName);
	if (uri) CFRelease(uri);
}

// Called when an element (tag) ends
static void XMLCALL
endElementHandler(void *ud, const XML_Char *name)
{
	ExpatXMLParser * parserobj = (id)ud;
		
	if (parserobj->buffer)
		[parserobj->delegate parser:parserobj foundCharacters:(NSString*)(id)parserobj->buffer];
	
	CFStringRef elementName = CREATE_CFSTRING(name);  

	[parserobj->delegate parser:parserobj
				   didEndElement:(NSString*)elementName
				    namespaceURI:nil
				   qualifiedName:nil];

	CFRelease(elementName);
	
	if (parserobj->buffer) {
		CFRelease(parserobj->buffer);
		parserobj->buffer = nil;
	}
}

// Called when characters are encounted between elements (tags)
static void XMLCALL
characterDataHandler(void *ud, const XML_Char *s, int len)
{
	ExpatXMLParser * parserobj = (id)ud;

	if (s != nil && len > 0) {
		if (parserobj->buffer == nil) {	
			parserobj->buffer = CFStringCreateMutable(kCFAllocatorDefault, 0);
		}
		
	#ifdef XML_UNICODE 
		CFStringAppendCharacters ((CFMutableStringRef)parserobj->buffer, (UniChar*)s, len);
	#else
		CFStringRef string = CFStringCreateWithBytesNoCopy (kCFAllocatorDefault, (UInt8*)s, len, kCFStringEncodingUTF8, false, kCFAllocatorNull);
		CFStringAppend((CFMutableStringRef)parserobj->buffer, string);	
		CFRelease(string);
	#endif
		
	}
}

// Called when comments are encountered
static void XMLCALL
commentHandler(void *ud, const XML_Char *data)
{
	CFStringRef _comment = nil;
	
	if (data) 
		_comment = CREATE_CFSTRING(data);
 	
	ExpatXMLParser * parserobj = (id)ud;
	[parserobj->delegate parser:parserobj foundComment:(id)_comment];
	
	if (_comment) CFRelease(_comment);
}

// Called when a namespace is declared
static void XMLCALL
startNamespaceDeclHandler(void *ud, const XML_Char *prefix, const XML_Char *uri)
{
	CFStringRef _prefix = nil;
	if (prefix) _prefix= CREATE_CFSTRING(prefix);
	
	CFStringRef _uri = nil;
	if (uri) _uri= CREATE_CFSTRING(uri);

	ExpatXMLParser * parserobj = (id)ud;
	[parserobj->delegate parser:parserobj didStartMappingPrefix:(id)_prefix toURI:(id)_uri];
	
	if (_uri) CFRelease(_uri);
	if (_prefix) CFRelease(_prefix);
}

// Called when a namespace declaration ends (falls out of scope)
static void XMLCALL
endNamespaceDeclHandler(void *ud, const XML_Char *prefix)
{
	CFStringRef _prefix = nil;
	if (prefix) _prefix= CREATE_CFSTRING(prefix);

	ExpatXMLParser * parserobj = (id)ud;
	[parserobj->delegate parser:parserobj didEndMappingPrefix:(id)_prefix];
	
	if (_prefix) CFRelease(_prefix);
}

static void XMLCALL
processingInstructionHandler(void *ud, const XML_Char *target, const XML_Char *data)
{
	CFStringRef _target = nil;
	if (target) _target = CREATE_CFSTRING(target);
	
	CFStringRef _data = nil;
	if (data) _data = CREATE_CFSTRING(data);
	
	ExpatXMLParser * parserobj = (id)ud;
	[parserobj->delegate parser:parserobj foundProcessingInstructionWithTarget:(id)_target data:(id)_data];
	
	if (_target) CFRelease(_target);
	if (_data) CFRelease(_data);
}

- (id)initWithData:(NSData *)fdata // create the parser from dat
{
	if (self = [super init]) {
		data = [fdata retain];
		_isDataParse = YES;
	}
	
	return self;
}

- (id)initWithContentsOfFile:(NSString *)path 
{
	if (self = [super init]) {
		url = [[NSURL alloc] initFileURLWithPath:path];
	}
	return self;
}

- (id)initWithContentsOfURL:(NSURL *)furl
{
	if (self = [super init]) {
		url = [furl retain];
		parser = nil;
	}
	return self;
}

-(void)dealloc
{
	
	if (buffer) 
		CFRelease(buffer);
	
	if (parser) {
		XML_ParserFree(parser);
	}
	
	if (dict) CFRelease(dict);
	
	if (seperator) CFRelease(seperator);
	
	[userAgent release];
	[data release];
	[delegate release];
	[url release];
	[error release];
	[super dealloc];
}

- (void)setShouldProcessNamespaces:(BOOL)flag
{
	shouldProcessNamespaces = flag;
}

- (BOOL)shouldProcessNamespaces
{
	return shouldProcessNamespaces;
}

- (void)setShouldReportNamespacePrefixes:(BOOL)flag
{
	shouldReportNamespacePrefixes = flag;
}

- (BOOL)shouldReportNamespacePrefixes
{
	return shouldReportNamespacePrefixes;
}

- (void)setShouldResolveExternalEntities:(BOOL)flag
{
	shouldResolveExternalEntities = flag;
}

- (BOOL)shouldResolveExternalEntities
{
	return shouldResolveExternalEntities;
}

- (void)errorHandler:(int)errorCode
{
	NSLog(@"Caught Error");
	
	if([delegate respondsToSelector:@selector(parser:parseErrorOccurred:)])
	{
		NSString *domain = @"ExpatXMLParserDomain";
		UniChar * errorc = (UniChar*)XML_ErrorString(errorCode);
		CFStringRef errorStr = CREATE_CFSTRING(errorc);
		
		NSDictionary *errorInfo = [NSDictionary dictionaryWithObject:(id)errorStr forKey:NSLocalizedDescriptionKey];
		
		error = [[NSError alloc] initWithDomain:domain code:errorCode userInfo:errorInfo];
		
		if (errorStr) CFRelease(errorStr);
		
		[delegate parser:self parseErrorOccurred:error];
	}
}

-(NSString*)userAgent {
	if (userAgent == nil)
		return @"iphone-expat-xmlparser (benreeves.co.uk)";
	else
		return userAgent;
}

- (BOOL)parse
{	
	
	if (parser) {
		XML_ParserFree(parser);
		parser = nil;
	}
	
	if (dict == nil)
		dict = (CFMutableDictionaryRef)[[NSMutableDictionary alloc] initWithCapacity:20];
	
	if (seperator == nil)
		seperator = CFStringCreateWithCharactersNoCopy (kCFAllocatorDefault,(UniChar*)&seperator,1,kCFAllocatorNull);

	
	// Initialize parser
	if(shouldProcessNamespaces)
	{
		parser = XML_ParserCreateNS(NULL, -1);
		XML_SetReturnNSTriplet(parser,1);
	}
	else
		parser = XML_ParserCreate(NULL);
	
	// Configure parser to pass proper user data
	XML_SetUserData(parser, self);
	
	// Set Standard Handlers
	XML_SetStartElementHandler(parser, startElementHandler);
	XML_SetEndElementHandler(parser, endElementHandler);
	XML_SetCharacterDataHandler(parser, characterDataHandler);
	
	if([delegate respondsToSelector:@selector(parser:foundComment:)])
		XML_SetCommentHandler(parser, commentHandler);
	
	if([delegate respondsToSelector:@selector(parser:foundProcessingInstructionWithTarget:data:)])
		XML_SetProcessingInstructionHandler(parser, processingInstructionHandler);
	
	// Set Namespace Handlers
	if(shouldReportNamespacePrefixes)
	{
		if([delegate respondsToSelector:@selector(parser:didStartMappingPrefix:toURI:)])
			XML_SetStartNamespaceDeclHandler(parser, startNamespaceDeclHandler);
		
		if([delegate respondsToSelector:@selector(parser:didEndMappingPrefix:)])
			XML_SetEndNamespaceDeclHandler(parser, endNamespaceDeclHandler);
	}
		
	// Notify of ending document
	if([delegate respondsToSelector:@selector(parserDidStartDocument:)])
		[delegate parserDidStartDocument:self];
	
	
	BOOL responseProcessed = NO;
	BOOL gzipEncoded = NO;
	BOOL isHTTP = NO;

	CFReadStreamRef inputStream;
	
	if (_isDataParse) { //Read from data
		inputStream =  CFReadStreamCreateWithBytesNoCopy(kCFAllocatorDefault, [data bytes], [data length], kCFAllocatorNull);
	} else if ([url isFileURL]) { //Read from file
		inputStream = CFReadStreamCreateWithFile(kCFAllocatorDefault, (const CFURLRef)url);
	} else { //Presume it's http
		
		isHTTP = YES;
		
		CFHTTPMessageRef myRequest = CFHTTPMessageCreateRequest(kCFAllocatorDefault, (const CFStringRef)@"GET", (const CFURLRef)url, kCFHTTPVersion1_1);
		
		CFHTTPMessageSetHeaderFieldValue(myRequest, (CFStringRef) @"Accept-Encoding", (CFStringRef) @"gzip");	
		CFHTTPMessageSetHeaderFieldValue(myRequest, (CFStringRef) @"User-Agent", (CFStringRef) userAgent);	

		//Setup Cookies
		NSArray *cookies = [[NSHTTPCookieStorage sharedHTTPCookieStorage] cookiesForURL:url];
		NSDictionary *headerFields = [NSHTTPCookie requestHeaderFieldsWithCookies:cookies];
		NSString *cookieHeader = [headerFields objectForKey:@"Cookie"]; // key used in header dictionary
		if (cookieHeader) {
			CFHTTPMessageSetHeaderFieldValue(myRequest, (CFStringRef) @"Cookie", (CFStringRef) cookieHeader);				
		}
		
		inputStream = CFReadStreamCreateForHTTPRequest (kCFAllocatorDefault, myRequest);
		CFReadStreamSetProperty(inputStream, kCFStreamPropertyHTTPShouldAutoredirect, kCFBooleanTrue);	
		CFReadStreamSetProperty(inputStream, kCFStreamPropertyHTTPAttemptPersistentConnection, kCFBooleanTrue);	

		CFMutableDictionaryRef  sslSettings;
		CFDictionaryRef proxySettings;
		
		//Setup the proxy settings
		if((proxySettings = CFNetworkCopySystemProxySettings())) {			
			CFReadStreamSetProperty(inputStream, kCFStreamPropertyHTTPProxy, (proxySettings));
			CFRelease(proxySettings);
		}
		
		//Setup SSL to not validate
		if([[url scheme] isEqualToString:@"https"]) {
			sslSettings = CFDictionaryCreateMutable(kCFAllocatorDefault, 1, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
			CFDictionarySetValue(sslSettings, kCFStreamSSLValidatesCertificateChain, kCFBooleanFalse);
			CFReadStreamSetProperty(inputStream, kCFStreamPropertySSLSettings, sslSettings); //kCFStreamSSLCertificates
			CFRelease(sslSettings);
		}
		
		CFRelease(myRequest);
	}
	
	if (CFReadStreamOpen(inputStream) == NO) {
		CFErrorRef ferror = CFReadStreamCopyError(inputStream);
		if([delegate respondsToSelector:@selector(parser:parseErrorOccurred:)])
			[delegate parser:self parseErrorOccurred:(NSError *)ferror];
		CFRelease(ferror);
	} else {

		int ret;
		unsigned have;
		z_stream strm;
		unsigned char in[buffSize];
		//unsigned char out[buffSize];
		unsigned char * out;

		while (true) {
				//Read in the data from the CFStream
				CFIndex result = CFReadStreamRead (inputStream, (UInt8*)in, buffSize);
				
				if (!responseProcessed) {
					CFHTTPMessageRef msgRespuesta =(CFHTTPMessageRef) CFReadStreamCopyProperty(inputStream, kCFStreamPropertyHTTPResponseHeader);
					if (msgRespuesta) {
						NSString * encodingdd = (NSString*)CFHTTPMessageCopyHeaderFieldValue (msgRespuesta, (CFStringRef) @"Content-Encoding");
						if (encodingdd) {
					
							if ([encodingdd isEqualToString:@"gzip"]) {
								gzipEncoded = YES;
								
								/* allocate inflate state */
								strm.zalloc = Z_NULL;
								strm.zfree = Z_NULL;
								strm.opaque = Z_NULL;
								strm.avail_in = 0;
								strm.next_in = Z_NULL;
								
								ret = inflateInit2(&strm, (15+32));
								if (ret != Z_OK) {
									if(strm.msg && [delegate respondsToSelector:@selector(parserDidEndDocument:)]){
										NSError * ferror = [NSError errorWithDomain:[NSString stringWithUTF8String:strm.msg] code:ret userInfo:nil];
										[delegate parser:self parseErrorOccurred:ferror];
									}
									break;
								} 
								
							} else {
								gzipEncoded = NO;
							}
							responseProcessed = YES;
							CFRelease(encodingdd);
						}
						CFRelease(msgRespuesta);
					}
					
				}
				
				if (result == 0) {
					break;
				} else if (result <= -1) {
					CFErrorRef ferror = CFReadStreamCopyError(inputStream);
					if([delegate respondsToSelector:@selector(parser:parseErrorOccurred:)]) {
						[delegate parser:self parseErrorOccurred:(NSError *)ferror];
					}
					CFRelease(ferror);
					break;				
				} else {
				
					if (gzipEncoded) {
						strm.avail_in = result;
						strm.next_in = in;
					
						do {
							
							out = XML_GetBuffer(parser, buffSize);
							if (out == nil) {
								[self errorHandler:XML_GetErrorCode(parser)];
								break;
							}
							
							strm.avail_out = buffSize;
							strm.next_out = (Bytef*)out;
							
							ret = inflate(&strm, Z_SYNC_FLUSH);
							assert(ret != Z_STREAM_ERROR); 
							switch (ret) {
								case Z_NEED_DICT:
									ret = Z_DATA_ERROR;     
								case Z_DATA_ERROR:
								case Z_MEM_ERROR:							
									if(strm.msg && [delegate respondsToSelector:@selector(parserDidEndDocument:)]){
										NSError * ferror = [NSError errorWithDomain:[NSString stringWithUTF8String:strm.msg] code:ret userInfo:nil];
										[delegate parser:self parseErrorOccurred:ferror];
									}
									break;
								case Z_STREAM_END:
									break;
							}
							
							//Parse what we have so far
							have = buffSize - strm.avail_out;

							if(!XML_ParseBuffer(parser, have, NO)) {
						//	if(!XML_Parse(parser, (const char*)out, have, NO)) {
								[self errorHandler:XML_GetErrorCode(parser)];
								break;
							}
							
						} while (strm.avail_out == 0);
					} else {
						XML_Parse(parser, (const char*)in, result, NO);
					}

				}
			}			

		if (gzipEncoded) {
			inflateEnd(&strm);
		}
		
	}
	
	CFReadStreamClose(inputStream);
	CFRelease(inputStream);
	XML_ParserFree(parser);
	parser = nil;

	// Notify of ending document
	if([delegate respondsToSelector:@selector(parserDidEndDocument:)])
		[delegate parserDidEndDocument:self];
	
	
	return YES;
	
}

- (void)abortParsing
{
	XML_StopParser(parser, XML_FALSE);
}

- (NSError *)parserError
{
	return error;
}

- (int)columnNumber
{
	// NSXMLParser returns column number of the end of the tag
	// Expat returns column number of the beginning of the tag,
	//  so we add the length of the tag
	if(parser == NULL)
		return 0;
	else
		return XML_GetCurrentColumnNumber(parser) + XML_GetCurrentByteCount(parser);
}

- (int)lineNumber
{
	if(parser == NULL)
		return 0;
	else
		return XML_GetCurrentLineNumber(parser);
}

- (NSString *)publicID
{
	return nil;
}

- (NSString *)systemID
{
	return nil;
}

@end
