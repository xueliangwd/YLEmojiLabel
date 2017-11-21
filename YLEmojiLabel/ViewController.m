//
//  ViewController.m
//  YLEmojiLabel
//
//  Created by 于学良 on 2017/11/21.
//  Copyright © 2017年 yxlGitHub. All rights reserved.
//

#import "ViewController.h"
#import <YYText/YYLabel.h>
#import "YYTextParserGroup.h"
@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.

   YYLabel * _textView = [YYLabel new];
    _textView.numberOfLines = 0;
    _textView.textAlignment = NSTextAlignmentLeft;
    _textView.preferredMaxLayoutWidth = [UIScreen mainScreen].bounds.size.width-40;
    _textView.font = [UIFont systemFontOfSize:16.0];
    YYTextParserGroup * parserGroup = [YYTextParserGroup textParsesGroupChatWithFont:[UIFont systemFontOfSize:16.0]];
    _textView.textParser = parserGroup;
    [self.view addSubview:_textView];
    _textView.frame = CGRectMake(20, 88, [UIScreen mainScreen].bounds.size.width-40, 500);
    _textView.text = @"/::)/::~/::B/::|/:8-)/::</::$/::X/::Z/::'(/::-|/::@/::P/::D/::O/::(/::+/:--b/::Q/::T/:,@P/:,@-D/::d/:,@o/::g/:|-)/::!/::L/::>/::,@/:,@f/::-S/:?/:,@x/:,@@/::8/:,@!/:!!!/:xx/:bye/:wipe/:dig/:handclap/:&-(/:B-)/:<@/:@>/::-O/:>-|/:P-(/::'|/:X-)/::*/:@x电话：87890099 mobile：15698980090 email：9885035@qq.com Link：www.baidu.com http://www.baidu.com";
    [_textView sizeToFit];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
