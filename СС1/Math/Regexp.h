//
//  Regexp.h
//  СС1
//
//  Created by Pavel Aksenkin on 26.02.13.
//  Copyright (c) 2013 Pavel Aksenkin. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSString * wrap (NSString *);

typedef enum RegexpOper {
    RegexpOperSymbol,
    RegexpOperIter,
    RegexpOperConcat,
    RegexpOperOr,
} RegexpOper;

@interface Regexp : NSObject
{
    @protected
    RegexpOper _oper;
}

@property (readonly) RegexpOper  oper;
-(NSString*)ssercDescription;           // Описание для системы уравнений с регулярными коэффициентами

@end



@interface RegexpUnar : Regexp

@property (retain) Regexp * left;

+(RegexpUnar*)iter:(Regexp*)x;

@end

@interface RegexpBinar : Regexp

@property (retain, readonly) NSMutableArray * operands;

+(RegexpBinar*)concatArray:(NSArray*)opers;
+(RegexpBinar*)orArray:(NSArray*)opers;
+(Regexp*)chain:(NSString*)chain;

@end

@interface RegexpSymbol : Regexp

@property (copy) NSString * symbol;

+(RegexpSymbol*)symbol:(NSString*)symbol;

@end
