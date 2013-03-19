//
//  FA.h
//  СС1
//
//  Created by Pavel Aksenkin on 24.02.13.
//  Copyright (c) 2013 Pavel Aksenkin. All rights reserved.
//

#import "Grammar.h"
#import "Regexp.h"

@interface Arc : NSObject

@property NSString *from;
@property NSString *to;
@property NSString *symbol;

-(Arc*)initWithFrom:(NSString*)from symbol:(NSString*)symbol to:(NSString*)to;

@end

@interface FA : NSObject
{    
    NSMutableArray *_alphabet;
    NSMutableArray *_states;
    NSMutableArray *_initStates;
    NSMutableArray *_finStates;
    NSMutableArray *_transes;
}

-(FA*)initWithLeftLinear:(Grammar*)grammar;
+(FA*)faWithLeftLinear:(Grammar*)grammar;
-(Grammar*)rightLinear;

-(FA*)initWithRegexp:(Regexp*)regexp;
+(FA*)faWithRegexp:(Regexp*)regexp;

-(void)determinate;
-(NSDictionary*)isAllowed:(NSString*)chain;

@end


