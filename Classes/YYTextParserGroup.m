//
//  YYTextParserGroup.m
//  Pods
//
//  Created by 于学良 on 2017/8/4.
//
//

#import "YYTextParserGroup.h"
#pragma mark - 高亮颜色
#define TextHighlightColor  [UIColor blueColor]
#define TextBackgroundColor [UIColor colorWithWhite:0.000 alpha:0.220]

@implementation YYTextParserGroup

/**
 默认返回一个检测表情、邮箱、电话、网址的ParserGroup

 @param font 目标文本显示字体
 @return YYTextParserGroup对象
 */
+(instancetype)textParsesGroupChatWithFont:(UIFont*)font{
    
    YYTextParserGroup * parserGroup = [YYTextParserGroup new];
    //表情parser
    NSMutableDictionary *mapper = [NSMutableDictionary new];
    
    YYTextEmoticonParser *emoticonParser = [YYTextEmoticonParser new];
    emoticonParser.emoticonMapper = mapper;
    NSDictionary * emojiDic = [parserGroup emojiDictionary];
    NSMutableDictionary *imageDic = [NSMutableDictionary new];
    for (NSString* emojiKey in emojiDic.allKeys) {
        imageDic[emojiKey] = [parserGroup imageWithName:emojiDic[emojiKey]];
    }
    emoticonParser.emoticonMapper = imageDic;
    //链接电话邮箱parser
    YYTextRichParser *richParser = [YYTextRichParser new];
    richParser.detector = [NSDataDetector dataDetectorWithTypes:NSTextCheckingTypeLink|NSTextCheckingTypePhoneNumber error:nil];
    richParser.font = font;
    
    parserGroup.parsers = @[richParser,emoticonParser];
    
    return parserGroup;
}

/**
 遍历 parsers

 @param text 目标文本
 @param selectedRange 需要检查的range范围
 @return 检测结果是否有异常
 */
- (BOOL)parseText:(NSMutableAttributedString *)text selectedRange:(NSRangePointer)selectedRange {
    BOOL changed = NO;
    for (id<YYTextParser>parser in _parsers) {
        if ([parser parseText:text selectedRange:selectedRange]) {
            changed = YES;
        }
    }
    return changed;
}

/**
 从plist获取 表情-图片名 的NSDictionary

 @return 返回 表情：图片名（key-value）的NSDictionary
 */
- (NSDictionary *)emojiDictionary {
    static NSDictionary *emojiDictionary = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSBundle *bundle = [NSBundle mainBundle];
        NSString *plistPath = [bundle pathForResource:@"EMojiImageDictionary" ofType:@"plist"];
        emojiDictionary = [NSDictionary dictionaryWithContentsOfFile:plistPath];
    });
    //    NSLog(@"emojidictionary is:@{%@}",emojiDictionary);
    return emojiDictionary;
}
- (UIImage *)imageWithName:(NSString *)name {
    UIImage *image = [UIImage imageNamed:name];
    return image;
}
@end

@implementation YYTextRichParser

-(BOOL)parseText:(NSMutableAttributedString *)text selectedRange:(NSRangePointer)selectedRange{
    if (!text.string.length)return NO;
    [text yy_removeAttributesInRange:NSMakeRange(0, text.length)];
    text.yy_font = _font;
    if (!_detector) return NO;
    //检测目标文本中符合类型的 文本段（NSTextCheckingResult）
    NSArray *matches = [_detector matchesInString:text.string options:NSMatchingReportProgress range:NSMakeRange(0, text.string.length)];
    if(!matches.count) return NO;
    __weak typeof(self) weakSelf = self;
    for (NSUInteger i = 0, max = matches.count; i < max; i++) {
        __block NSTextCheckingResult *one = matches[i];
        NSRange oneRange = one.range;
        if (oneRange.length == 0) continue;
        
        [text yy_setUnderlineStyle:NSUnderlineStyleSingle range:oneRange];
        [text yy_setTextHighlightRange:oneRange
                                 color:TextHighlightColor
                       backgroundColor:TextBackgroundColor
                             tapAction:^(UIView *containerView, NSAttributedString *text, NSRange range, CGRect rect){
                                 NSLog(@"高亮区点击事件 Match:%@ ",one);
                                 //高亮区点击事件
                                 [weakSelf openUrlWithCheckingResult:one];
                             }];
    }
    return YES;
    
}
//高亮区点击事件 TODO：如需扩展请在这里不全新增类型对应的点击事件 
-(void)openUrlWithCheckingResult:(NSTextCheckingResult *)result{
    NSURL *callUrl = nil;
    switch (result.resultType) {
        case NSTextCheckingTypeLink:{
            callUrl = result.URL;
            
        }break;
        case NSTextCheckingTypePhoneNumber:{
            NSString* text = result.phoneNumber;
            //            text = [text stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"-"]];
            callUrl = [NSURL URLWithString:[NSString stringWithFormat:@"telprompt://%@",text]];
        }break;
        default:
            break;
    }
    if ([[UIApplication sharedApplication] canOpenURL:callUrl]) {
        [[UIApplication sharedApplication] openURL:callUrl];
    }
}
@end

#pragma mark - Emoticon Parser

#define LOCK(...) dispatch_semaphore_wait(_lock, DISPATCH_TIME_FOREVER); \
__VA_ARGS__; \
dispatch_semaphore_signal(_lock);

@implementation YYTextEmoticonParser {
    NSRegularExpression *_regex;
    NSDictionary *_mapper;
    dispatch_semaphore_t _lock;
}

- (instancetype)init {
    self = [super init];
    _lock = dispatch_semaphore_create(1);
    return self;
}

- (NSDictionary *)emoticonMapper {
    LOCK(NSDictionary *mapper = _mapper); return mapper;
}

/**
 通过表情plist文件拼接成一个正则表达式，用来检测目标文本

 @param emoticonMapper 表情-图片名 的NSDictionary
 */
- (void)setEmoticonMapper:(NSDictionary *)emoticonMapper {
    LOCK(
         _mapper = emoticonMapper.copy;
         if (_mapper.count == 0) {
             _regex = nil;
         } else {
             NSMutableString *pattern = @"(".mutableCopy;
             NSArray *allKeys = _mapper.allKeys;
             NSCharacterSet *charset = [NSCharacterSet characterSetWithCharactersInString:@"$^?+*.,#|{}[]()\\"];
             for (NSUInteger i = 0, max = allKeys.count; i < max; i++) {
                 NSMutableString *one = [allKeys[i] mutableCopy];
                 
                 // escape regex characters
                 for (NSUInteger ci = 0, cmax = one.length; ci < cmax; ci++) {
                     unichar c = [one characterAtIndex:ci];
                     if ([charset characterIsMember:c]) {
                         [one insertString:@"\\" atIndex:ci];
                         ci++;
                         cmax++;
                     }
                 }
                 
                 [pattern appendString:one];
                 if (i != max - 1) [pattern appendString:@"|"];
             }
             [pattern appendString:@")"];
             _regex = [[NSRegularExpression alloc] initWithPattern:pattern options:kNilOptions error:nil];
         }
         );
}

// correct the selected range during text replacement
// 重写YYText父类，计算 表情key替换成表情图片后的range；因为表情字符替换成表情图后，range会发生增减，需重新计算
- (NSRange)_replaceTextInRange:(NSRange)range withLength:(NSUInteger)length selectedRange:(NSRange)selectedRange {
    // no change
    if (range.length == length) return selectedRange;
    // right
    if (range.location >= selectedRange.location + selectedRange.length) return selectedRange;
    // left
    if (selectedRange.location >= range.location + range.length) {
        selectedRange.location = selectedRange.location + length - range.length;
        return selectedRange;
    }
    // same
    if (NSEqualRanges(range, selectedRange)) {
        selectedRange.length = length;
        return selectedRange;
    }
    // one edge same
    if ((range.location == selectedRange.location && range.length < selectedRange.length) ||
        (range.location + range.length == selectedRange.location + selectedRange.length && range.length < selectedRange.length)) {
        selectedRange.length = selectedRange.length + length - range.length;
        return selectedRange;
    }
    selectedRange.location = range.location + length;
    selectedRange.length = 0;
    return selectedRange;
}

/**
 检测解析表情符

 @param text 目标富文本
 @param range 需检测目标文本的Range
 @return 是否有异常
 */
- (BOOL)parseText:(NSMutableAttributedString *)text selectedRange:(NSRangePointer)range {
    if (text.length == 0) return NO;
    
    NSDictionary *mapper;
    NSRegularExpression *regex;
    LOCK(mapper = _mapper; regex = _regex;);
    if (mapper.count == 0 || regex == nil) return NO;
    
    NSArray *matches = [regex matchesInString:text.string options:kNilOptions range:NSMakeRange(0, text.length)];
    if (matches.count == 0) return NO;
    
    NSRange selectedRange = range ? *range : NSMakeRange(0, 0);
    NSUInteger cutLength = 0;
    for (NSUInteger i = 0, max = matches.count; i < max; i++) {
        NSTextCheckingResult *one = matches[i];
        NSRange oneRange = one.range;
        if (oneRange.length == 0) continue;
        oneRange.location -= cutLength;
        NSString *subStr = [text.string substringWithRange:oneRange];
        UIImage *emoticon = mapper[subStr];
        if (!emoticon) continue;
        
        CGFloat fontSize = 16; // CoreText default value
        UIFont * textFont = ([text yy_attribute:NSFontAttributeName atIndex:oneRange.location]) ;
        textFont = textFont?textFont:[UIFont systemFontOfSize:fontSize];
        
        UIImageView *imageView = [[UIImageView alloc] initWithImage:emoticon];
        imageView.frame = CGRectMake(0, 0, 23.0, 23.0);
        NSMutableAttributedString *atr = [NSAttributedString yy_attachmentStringWithContent:imageView contentMode:UIViewContentModeCenter attachmentSize:CGSizeMake(28.0, 28.0) alignToFont:textFont alignment:YYTextVerticalAlignmentCenter];
        [atr yy_setTextBackedString:[YYTextBackedString stringWithString:subStr] range:NSMakeRange(0, atr.length)];
        [text replaceCharactersInRange:oneRange withString:atr.string];
        [text yy_removeDiscontinuousAttributesInRange:NSMakeRange(oneRange.location, atr.length)];
        [text addAttributes:atr.yy_attributes range:NSMakeRange(oneRange.location, atr.length)];
        selectedRange = [self _replaceTextInRange:oneRange withLength:atr.length selectedRange:selectedRange];
        cutLength += oneRange.length - 1;
    }
    if (range) *range = selectedRange;
    
    return YES;
}
@end
