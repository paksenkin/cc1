//
//  Regexp.m
//  СС1
//
//  Created by Pavel Aksenkin on 26.02.13.
//  Copyright (c) 2013 Pavel Aksenkin. All rights reserved.
//

#import "Regexp.h"

NSString *wrap(NSString *regexp) {
    NSString *result = regexp;
    if (regexp.length > 1) {
        NSCharacterSet *set = [NSCharacterSet characterSetWithCharactersInString:@"])"];
        NSString *lastSymbol = [regexp substringFromIndex:regexp.length-1];
        if ([lastSymbol rangeOfCharacterFromSet:set].location == NSNotFound) {
            result = [NSString stringWithFormat:@"(%@)", regexp];
        }
    }
    return result;
}

@implementation Regexp

@synthesize oper = _oper;

-(NSString *)description
{
    return @"Abstract regexp";
}
-(NSString *)ssercDescription
{
    return [self description];
}

@end

@implementation RegexpBinar

+(RegexpBinar *)concatArray:(NSArray *)opers
{
    RegexpBinar *result = [[RegexpBinar alloc] init];
    result->_oper = RegexpOperConcat;
    result->_operands = [opers mutableCopy];
    return result;
}
+(RegexpBinar *)orArray:(NSArray *)opers
{
    RegexpBinar *result = [[RegexpBinar alloc] init];
    result->_oper = RegexpOperOr;
    result->_operands = [NSMutableArray array];
        // Хочется, чтобы было не a bc = {a, Concat, {b, Concat, c}}, а {Concat, [a, b, c]}
        // Не будем вдаваться в рекурсию, понадеемся, что ее тут нет, по построению так и должно быть
    for (Regexp *r in opers) {
        if (r.oper == result->_oper) {
            for (Regexp *rr in ((RegexpBinar*)r)->_operands) {
                [result->_operands addObject:rr];
            }
        } else {
            [result->_operands addObject:r];
        }
    }
    result->_operands = [opers mutableCopy];
    return result;
}
+(Regexp *)chain:(NSString *)chain
{
    Regexp *result;
    if (chain.length > 1) {
        result = [[RegexpBinar alloc] init];
        result->_oper = RegexpOperConcat;
        ((RegexpBinar*)result)->_operands = [NSMutableArray array];
        for(NSUInteger i=0; i<chain.length; ++i) {
            [((RegexpBinar*)result)->_operands addObject:[RegexpSymbol symbol:[chain substringWithRange:NSMakeRange(i, 1)]]];
        }
    } else {
        result = [RegexpSymbol symbol:chain];
    }
    return result;
}

-(NSString *)description
{
    NSMutableArray *subDescriptions = [NSMutableArray arrayWithCapacity:_operands.count];
    for (NSUInteger i=0; i<_operands.count; ++i) {
        Regexp *r = _operands[i];
        NSString *rdescr = [r description];
        [subDescriptions addObject:rdescr];
    }
    NSString *result = @"";
    if (_oper == RegexpOperOr) {
        NSMutableString *mutable = [NSMutableString stringWithString:@"["];
        BOOL shouldPrecedeByVBar = NO;
        BOOL isFirst = YES;
        for (NSString *descr in subDescriptions) {
            shouldPrecedeByVBar = !isFirst && (shouldPrecedeByVBar || descr.length > 1);
            [mutable appendFormat:@"%@%@", shouldPrecedeByVBar ? @"|" : @"", wrap(descr)];
            shouldPrecedeByVBar = descr.length > 1;
            isFirst = NO;
        }
        [mutable appendString:@"]"];
        result = [NSString stringWithString:mutable];
    } else if (_oper == RegexpOperConcat) {
        result = [subDescriptions componentsJoinedByString:@""];
    }
    return result;
}
-(NSString *)ssercDescription
{
    NSMutableArray *subDescriptions = [NSMutableArray arrayWithCapacity:_operands.count];
    for (Regexp *r in _operands) {
        NSString *rdescr = [r description];
        if (rdescr.length > 1 && _oper == RegexpOperConcat) {
            rdescr = [NSString stringWithFormat:@"(%@)", rdescr];
        }
        [subDescriptions addObject:rdescr];
    }
    NSString *result = @"";
    if (_oper == RegexpOperOr) {
        result = [subDescriptions componentsJoinedByString:@" + "];
    } else if (_oper == RegexpOperConcat) {
        result = [subDescriptions componentsJoinedByString:@""];
    }
    return result;
}

@end

@implementation RegexpSymbol

+(RegexpSymbol*)symbol:(NSString *)symbol
{
    RegexpSymbol *result = [[RegexpSymbol alloc] init];
    result->_oper = RegexpOperSymbol;
    result->_symbol = symbol;
    return result;
}

-(NSString *)description
{
    return _symbol;
}

@end

@implementation RegexpUnar

+(RegexpUnar*)iter:(Regexp*)regexp
{
    RegexpUnar *iter = [[RegexpUnar alloc] init];
    iter->_oper = RegexpOperIter;
    iter->_left = regexp;
    return iter;
}

-(NSString *)description
{
    return [NSString stringWithFormat:@"%@*", wrap([_left description])];
}

@end