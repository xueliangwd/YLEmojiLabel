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

/**
 parsers集合，需要检测的子parser，如表情、邮箱等
 */
@property NSArray * _Nullable parsers;

+(instancetype _Nullable )textParsesGroupChatWithFont:(UIFont*_Nullable)font;
@end

@interface YYTextRichParser  : NSObject<YYTextParser>

/**
 设置需要检测的类型范围，如：NSTextCheckingTypeLink|NSTextCheckingTypePhoneNumber
 */
@property (nullable,nonatomic,strong)NSDataDetector *  detector;

/**
 目标文本字体
 */
@property (nullable, nonatomic, strong) UIFont *font;

@end

@interface YYTextEmoticonParser : NSObject <YYTextParser>

/**
 由表情-图片名（key-value）plist文件生成的NSDictionary，必传值。
 */
@property (nullable, copy) NSDictionary<NSString *, __kindof UIImage *> *emoticonMapper;
@end
