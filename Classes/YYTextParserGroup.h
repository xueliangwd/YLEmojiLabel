//
//  YYTextParserGroup.h
//  Pods
//  自动检测邮箱电话网址链接，自定义表情文字混排
//  Created by 于学良 on 2017/8/4.
//
//

#import <Foundation/Foundation.h>
#import "YYText.h"
@interface YYTextParserGroup : NSObject<YYTextParser>
@property NSArray * _Nullable parsers;
+(instancetype _Nullable )textParsesGroupChatWithFont:(UIFont*_Nullable)font;
@end

@interface YYTextRichParser  : NSObject<YYTextParser>

@property (nullable,nonatomic,strong)NSDataDetector *  detector;
@property (nullable, nonatomic, strong) UIFont *font;

@end

@interface YYTextEmoticonParser : NSObject <YYTextParser>
@property (nullable, copy) NSDictionary<NSString *, __kindof UIImage *> *emoticonMapper;
@end
